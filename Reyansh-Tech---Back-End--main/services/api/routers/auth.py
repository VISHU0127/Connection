"""
Authentication endpoints: login, refresh, logout.
"""
from datetime import datetime, timedelta, timezone

import bcrypt
import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from auth.jwt import (
    DUMMY_HASH,
    create_access_token,
    generate_refresh_token,
    verify_password,
)
from config import settings
from database import get_db
from redis_client import get_redis
from repositories.user import UserRepository
from schemas.auth import LoginRequest, LoginResponse, LogoutRequest, RefreshRequest, TokenResponse, UserInfo

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
async def login(
    body: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    redis_client: aioredis.Redis = Depends(get_redis),
) -> LoginResponse:
    """
    Authenticate with email and password. Returns a short-lived access token (15 min)
    and a long-lived refresh token (7 days).

    Both tokens must be stored securely. Invalid credentials always return 401 with a
    constant-time response to prevent user enumeration.

    **FE integration notes:**

    Send `Authorization: Bearer <access_token>` on every subsequent API request.

    Use `user.org_type` (not `user.role`) to determine which dashboard to render:
    - `PLATFORM`        → Super Admin dashboard (`/admin`)
    - `POLICE`          → Police dashboard (`/police`)
    - `AMBULANCE`       → Ambulance dashboard (`/ambulance`)
    - `FIRE_DEPARTMENT` → Fire dashboard (`/fire`)

    `user.role` is the granular permission level within the org (`org_admin`, `operator`,
    `dispatcher`, `viewer`, `super_admin`, etc.) — use it for feature gating, not routing.

    `user.org_name` contains the organization's display name (e.g. "Mumbai Police - Bandra West").
    Persist the full `user` object in session storage for sidebar display.

    There is no `HOSPITAL` org type — hospital pages are not yet backed by this API.
    """
    repo = UserRepository(db)
    user = await repo.get_by_email(body.email)

    if user is None or not user.is_active:
        # Constant-time rejection to prevent user enumeration
        bcrypt.checkpw(b"dummy", DUMMY_HASH.encode())
        raise HTTPException(
            status_code=401,
            detail={"error": {"code": "UNAUTHORIZED", "message": "Invalid credentials.", "details": {"reason": "invalid_credentials"}}},
            headers={"WWW-Authenticate": 'Bearer realm="vm-api"'},
        )

    if not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail={"error": {"code": "UNAUTHORIZED", "message": "Invalid credentials.", "details": {"reason": "invalid_credentials"}}},
            headers={"WWW-Authenticate": 'Bearer realm="vm-api"'},
        )

    access_token = create_access_token(user)
    refresh_plaintext, refresh_hash = generate_refresh_token()
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.jwt_refresh_token_expire_days)

    await repo.update_refresh_token(
        user_id=user.id,
        refresh_token_hash=refresh_hash,
        refresh_token_prefix=refresh_plaintext[:8],
        expires_at=expires_at,
    )
    await repo.update_last_login(user.id)

    org = user.organization
    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_plaintext,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
        user=UserInfo(
            user_id=str(user.id),
            email=user.email,
            name=f"{user.first_name or ''} {user.last_name or ''}".strip() or None,
            org_id=str(user.organization_id),
            org_type=org.org_type if org else "UNKNOWN",
            org_name=org.name if org else None,
            role=user.role,
        ),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    """
    Exchange a valid refresh token for a new access token and refresh token.

    Tokens rotate on every call — the old refresh token is atomically invalidated before
    the new pair is issued. Concurrent refresh requests with the same token will result in
    one succeeding and the other receiving 401.
    """
    repo = UserRepository(db)
    prefix = body.refresh_token[:8]
    candidates = await repo.get_by_token_prefix(prefix)

    matched = None
    for user in candidates:
        try:
            valid = user.refresh_token_hash and bcrypt.checkpw(
                body.refresh_token.encode(), user.refresh_token_hash.encode()
            )
        except ValueError:
            valid = False
        if valid:
            matched = user
            break

    if matched is None:
        raise HTTPException(
            status_code=401,
            detail={"error": {"code": "UNAUTHORIZED", "message": "Invalid grant.", "details": {"reason": "invalid_grant"}}},
        )

    if matched.refresh_token_expires_at and matched.refresh_token_expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=401,
            detail={"error": {"code": "UNAUTHORIZED", "message": "Refresh token expired.", "details": {"reason": "invalid_grant"}}},
        )

    # Atomic rotation — prevents concurrent refresh races
    rows_updated = await repo.atomic_clear_refresh_token(matched.id, matched.refresh_token_hash)
    if rows_updated == 0:
        raise HTTPException(
            status_code=401,
            detail={"error": {"code": "UNAUTHORIZED", "message": "Invalid grant.", "details": {"reason": "invalid_grant"}}},
        )

    new_access = create_access_token(matched)
    new_refresh_plain, new_refresh_hash = generate_refresh_token()
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.jwt_refresh_token_expire_days)

    await repo.update_refresh_token(
        user_id=matched.id,
        refresh_token_hash=new_refresh_hash,
        refresh_token_prefix=new_refresh_plain[:8],
        expires_at=expires_at,
    )

    return TokenResponse(
        access_token=new_access,
        refresh_token=new_refresh_plain,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
    )


@router.post("/logout", status_code=204)
async def logout(
    body: LogoutRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    redis_client: aioredis.Redis = Depends(get_redis),
) -> None:
    """
    Revoke the current session. Always returns 204 — never fails due to token issues.

    - The access token JTI is added to the Redis denylist (TTL = remaining token lifetime).
    - The refresh token is cleared from the database.

    Pass the access token in the `Authorization: Bearer` header and the refresh token in
    the request body.
    """
    from auth.jwt import decode_access_token
    from jose import JWTError

    # Extract Bearer token from Authorization header (allow expired tokens on logout)
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        token = auth_header[7:]
        try:
            from jose import jwt as jose_jwt
            payload = jose_jwt.decode(
                token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm],
                options={"verify_exp": False, "require": ["jti"]},
            )
            jti = payload.get("jti")
            exp = payload.get("exp", 0)
            now = int(datetime.now(timezone.utc).timestamp())
            remaining_ttl = max(1, exp - now) if exp > now else 1
            if jti:
                await redis_client.set(f"token_denylist:{jti}", "1", ex=remaining_ttl)
        except Exception:
            pass  # logout should never fail due to token issues

    # Clear refresh token
    repo = UserRepository(db)
    prefix = body.refresh_token[:8] if body.refresh_token else ""
    if prefix:
        candidates = await repo.get_by_token_prefix(prefix)
        for user in candidates:
            try:
                valid = user.refresh_token_hash and bcrypt.checkpw(
                    body.refresh_token.encode(), user.refresh_token_hash.encode()
                )
            except ValueError:
                valid = False
            if valid:
                await repo.update_refresh_token(user.id, None, None, None)
                break
