"""
Public onboarding endpoint — no authentication required.

Flow triggered by QR code scan on a new device:
  1. Customer fills form (personal + vehicle details)
  2. POST /onboard creates: org (CUSTOMER) → user (owner) → vehicle → device → EMQX credentials
  3. Returns JWT + EMQX credentials in a single response

Existing customers adding a second vehicle use POST /onboard/vehicle (requires auth).
"""
import logging
import re
import secrets
import uuid
from datetime import datetime, timedelta, timezone

import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext, get_current_user
from auth.jwt import create_access_token, generate_refresh_token, hash_password, verify_password
from auth.rbac import Permission, require_permission
from config import settings
from database import get_db
from emqx_client import EmqxClient, derive_device_password
from models import Device, Organization, User, Vehicle
from redis_client import get_redis
from repositories.device import DeviceRepository
from repositories.user import UserRepository
from schemas.onboard import AddVehicleRequest, AddVehicleResponse, OnboardRequest, OnboardResponse

logger = logging.getLogger("api.onboard")

router = APIRouter(prefix="/onboard", tags=["onboard"])


def _slug_from_email(email: str) -> str:
    """Derive a unique-enough org slug from email."""
    base = re.sub(r"[^a-z0-9]", "-", email.lower().split("@")[0])
    return f"{base}-{secrets.token_hex(4)}"


def _get_emqx() -> EmqxClient:
    return EmqxClient(settings.emqx_api_url, settings.emqx_api_key, settings.emqx_api_secret)


async def _resume_onboarding(
    db: AsyncSession,
    redis_client: aioredis.Redis,
    user_repo: UserRepository,
    device_repo: DeviceRepository,
    body: OnboardRequest,
    existing_user: User,
    existing_device: Device,
) -> JSONResponse:
    """
    Complete a partial or fully-completed onboarding when the same email + MAC are resubmitted.

    Called when both the user and device already exist in Postgres (same org).
    Re-runs all post-DB steps idempotently:
      - EMQX credential + ACL rules (create_credential handles 409 with PUT internally)
      - Redis device meta cache (plain SET, safe to overwrite)
      - Fresh JWT tokens (old access token may have expired)

    Returns HTTP 200 (not 201) since no new resources are created.
    """
    if not verify_password(body.password, existing_user.password_hash):
        raise HTTPException(
            status_code=401,
            detail={"error": {"code": "UNAUTHORIZED", "message": "Invalid credentials."}},
        )

    result = await db.execute(select(Vehicle).where(Vehicle.id == existing_device.vehicle_id))
    vehicle = result.scalar_one_or_none()
    if not vehicle:
        raise HTTPException(
            status_code=500,
            detail={"error": {"code": "INTERNAL_ERROR", "message": "Onboarding state is inconsistent — vehicle record missing."}},
        )

    emqx_password = derive_device_password(body.mac_address, str(vehicle.id), settings.emqx_device_secret_salt)
    emqx = _get_emqx()
    try:
        await emqx.create_credential(body.mac_address, emqx_password)
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"EMQX registration failed: {exc}") from exc

    await device_repo.write_device_meta_cache(redis_client, existing_device)

    access_token = create_access_token(existing_user)
    refresh_plaintext, refresh_hash = generate_refresh_token()
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.jwt_refresh_token_expire_days)
    await user_repo.update_refresh_token(existing_user.id, refresh_hash, refresh_plaintext[:8], expires_at)

    logger.info("onboarding_resumed", extra={"user_id": str(existing_user.id), "mac": body.mac_address})

    return JSONResponse(
        status_code=200,
        content=OnboardResponse(
            access_token=access_token,
            refresh_token=refresh_plaintext,
            expires_in=settings.jwt_access_token_expire_minutes * 60,
            org_id=existing_user.organization_id,
            user_id=existing_user.id,
            vehicle_id=vehicle.id,
            device_id=existing_device.device_id,
            emqx_username=body.mac_address,
            emqx_password=emqx_password,
        ).model_dump(mode="json"),
    )


@router.post("", response_model=OnboardResponse, status_code=201)
async def onboard(
    body: OnboardRequest,
    db: AsyncSession = Depends(get_db),
    redis_client: aioredis.Redis = Depends(get_redis),
):
    """
    Register a new customer, their vehicle, and their OBD device in one call.
    This is the public QR-code onboarding endpoint — no authentication required.
    Returns a JWT so the customer can immediately use the mobile app.
    """
    user_repo = UserRepository(db)
    device_repo = DeviceRepository(db)

    # Classify the request: new registration, resumable partial, or genuine conflict
    existing_user = await user_repo.get_by_email(body.email)
    existing_device = await device_repo.get_by_mac(body.mac_address)

    if existing_user or existing_device:
        if existing_user and existing_device:
            if existing_device.organization_id != existing_user.organization_id:
                raise HTTPException(
                    status_code=409,
                    detail={"error": {"code": "CONFLICT", "message": "Email and device are registered to different accounts."}},
                )
            # Same org — resume the partial or completed onboarding
            return await _resume_onboarding(db, redis_client, user_repo, device_repo, body, existing_user, existing_device)
        elif existing_user:
            raise HTTPException(
                status_code=409,
                detail={"error": {"code": "CONFLICT", "message": "An account with this email already exists. Use the login endpoint or add a vehicle to your existing account."}},
            )
        else:
            raise HTTPException(
                status_code=409,
                detail={"error": {"code": "CONFLICT", "message": "This device is already registered to a different account."}},
            )

    # 1 — Create CUSTOMER org
    org = Organization(
        name=f"{body.first_name} {body.last_name}",
        slug=_slug_from_email(body.email),
        org_type="CUSTOMER",
        is_active=True,
    )
    db.add(org)
    await db.flush()  # get org.id without committing

    # 2 — Create owner user
    user = User(
        organization_id=org.id,
        email=body.email,
        username=body.email,
        password_hash=hash_password(body.password),
        role="owner",
        first_name=body.first_name,
        last_name=body.last_name,
        is_active=True,
    )
    if body.phone:
        user.phone_number = body.phone
    db.add(user)
    await db.flush()

    # 3 — Create vehicle
    vehicle = Vehicle(
        organization_id=org.id,
        vehicle_category="USER_VEHICLE",
        registration_number=body.registration_number,
        make=body.make,
        model=body.model,
        year=body.year,
        vehicle_type=body.vehicle_type,
        vin=body.vin,
        is_active=True,
    )
    db.add(vehicle)
    await db.flush()

    # 4 — Create device
    device_id = f"dev_{secrets.token_urlsafe(16)}"
    device = Device(
        device_id=device_id,
        mac_address=body.mac_address,
        vehicle_id=vehicle.id,
        organization_id=org.id,
        is_active=True,
    )
    db.add(device)
    await db.flush()

    # 5 — Register EMQX credentials
    vehicle_id_str = str(vehicle.id)
    emqx_password = derive_device_password(body.mac_address, vehicle_id_str, settings.emqx_device_secret_salt)
    emqx = _get_emqx()
    try:
        await emqx.create_credential(body.mac_address, emqx_password)
    except Exception as exc:
        await db.rollback()
        raise HTTPException(status_code=502, detail=f"EMQX registration failed: {exc}") from exc

    # 6 — Commit everything
    await db.commit()
    await db.refresh(user)
    user.organization = org  # attach for JWT creation

    # 7 — Write device_meta cache for state-updater RBAC enrichment
    await device_repo.write_device_meta_cache(redis_client, device)

    # 8 — Issue JWT so customer can use the app immediately
    access_token = create_access_token(user)
    refresh_plaintext, refresh_hash = generate_refresh_token()
    expires_at = datetime.now(timezone.utc) + timedelta(days=settings.jwt_refresh_token_expire_days)
    await user_repo.update_refresh_token(user.id, refresh_hash, refresh_plaintext[:8], expires_at)

    return OnboardResponse(
        access_token=access_token,
        refresh_token=refresh_plaintext,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
        org_id=org.id,
        user_id=user.id,
        vehicle_id=vehicle.id,
        device_id=device_id,
        emqx_username=body.mac_address,
        emqx_password=emqx_password,
    )


@router.post("/vehicle", response_model=AddVehicleResponse, status_code=201)
async def add_vehicle(
    body: AddVehicleRequest,
    ctx: RequestContext = Depends(require_permission(Permission.CUSTOMER_WRITE)),
    db: AsyncSession = Depends(get_db),
    redis_client: aioredis.Redis = Depends(get_redis),
):
    """
    Existing customer adds a second (or subsequent) vehicle by scanning a new device QR code.
    Requires authentication — caller must be org_type=CUSTOMER.
    """
    if ctx.org_type != "CUSTOMER":
        raise HTTPException(status_code=403, detail="Only customer accounts can use this endpoint.")

    device_repo = DeviceRepository(db)
    existing_device = await device_repo.get_by_mac(body.mac_address)
    if existing_device:
        raise HTTPException(
            status_code=409,
            detail={"error": {"code": "CONFLICT", "message": "This device is already registered."}},
        )

    # Create vehicle under caller's org
    vehicle = Vehicle(
        organization_id=uuid.UUID(ctx.org_id),
        vehicle_category="USER_VEHICLE",
        registration_number=body.registration_number,
        make=body.make,
        model=body.model,
        year=body.year,
        vehicle_type=body.vehicle_type,
        vin=body.vin,
        is_active=True,
    )
    db.add(vehicle)
    await db.flush()

    device_id = f"dev_{secrets.token_urlsafe(16)}"
    device = Device(
        device_id=device_id,
        mac_address=body.mac_address,
        vehicle_id=vehicle.id,
        organization_id=uuid.UUID(ctx.org_id),
        is_active=True,
    )
    db.add(device)
    await db.flush()

    vehicle_id_str = str(vehicle.id)
    emqx_password = derive_device_password(body.mac_address, vehicle_id_str, settings.emqx_device_secret_salt)
    emqx = _get_emqx()
    try:
        await emqx.create_credential(body.mac_address, emqx_password)
    except Exception as exc:
        await db.rollback()
        raise HTTPException(status_code=502, detail=f"EMQX registration failed: {exc}") from exc

    await db.commit()
    await device_repo.write_device_meta_cache(redis_client, device)

    return AddVehicleResponse(
        vehicle_id=vehicle.id,
        device_id=device_id,
        emqx_username=body.mac_address,
        emqx_password=emqx_password,
    )
