"""JWT creation and validation for the API service."""
import secrets
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

import bcrypt
from jose import JWTError, jwt

from config import settings


def create_access_token(user) -> str:
    now = datetime.now(timezone.utc)
    exp = now + timedelta(minutes=settings.jwt_access_token_expire_minutes)
    payload = {
        "sub": str(user.id),
        "jti": str(uuid.uuid4()),
        "org_id": str(user.organization_id),
        "org_type": user.organization.org_type if user.organization else None,
        "role": user.role,
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
    }
    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
        headers={"kid": settings.jwt_kid},
    )


def decode_access_token(token: str) -> dict:
    """Decode and verify a JWT. Raises JWTError on failure."""
    return jwt.decode(
        token,
        settings.jwt_secret_key,
        algorithms=[settings.jwt_algorithm],
        options={"require": ["sub", "jti", "org_id", "org_type", "role", "exp"]},
    )


def generate_refresh_token() -> tuple[str, str]:
    """Returns (plaintext_token, bcrypt_hash)."""
    plaintext = secrets.token_urlsafe(48)  # ~64 chars — 384 bits entropy, safely under bcrypt's 72-byte limit
    hashed = bcrypt.hashpw(plaintext.encode(), bcrypt.gensalt(rounds=settings.bcrypt_rounds)).decode()
    return plaintext, hashed


def hash_password(password: str) -> str:
    encoded = password.encode()
    if len(encoded) > 72:
        raise ValueError("Password must not exceed 72 bytes (bcrypt limit)")
    return bcrypt.hashpw(encoded, bcrypt.gensalt(rounds=settings.bcrypt_rounds)).decode()


def verify_password(plaintext: str, hashed: str) -> bool:
    encoded = plaintext.encode()
    if len(encoded) > 72:
        return False
    return bcrypt.checkpw(encoded, hashed.encode())


# Constant-time dummy hash to prevent timing attacks on login
DUMMY_HASH = bcrypt.hashpw(b"dummy", bcrypt.gensalt(rounds=settings.bcrypt_rounds)).decode()
