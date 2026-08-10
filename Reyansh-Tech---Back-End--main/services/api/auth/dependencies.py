"""FastAPI dependencies for auth: JWT validation and RequestContext injection."""
import uuid
from dataclasses import dataclass

import redis.asyncio as aioredis
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError

from redis_client import get_redis

from .jwt import decode_access_token

http_bearer = HTTPBearer(auto_error=True)


@dataclass(frozen=True)
class RequestContext:
    user_id: str
    org_id: str
    org_type: str
    role: str
    jti: str


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(http_bearer),
    redis_client: aioredis.Redis = Depends(get_redis),
) -> RequestContext:
    token = credentials.credentials

    try:
        payload = decode_access_token(token)
    except JWTError as exc:
        reason = "token_expired" if "expired" in str(exc).lower() else "token_malformed"
        raise HTTPException(
            status_code=401,
            detail={"error": {"code": "UNAUTHORIZED", "message": str(exc), "details": {"reason": reason}}},
            headers={"WWW-Authenticate": 'Bearer realm="vm-api"'},
        )

    jti: str = payload["jti"]
    if await redis_client.exists(f"token_denylist:{jti}"):
        raise HTTPException(
            status_code=401,
            detail={"error": {"code": "UNAUTHORIZED", "message": "Token has been revoked.", "details": {"reason": "token_revoked"}}},
            headers={"WWW-Authenticate": 'Bearer realm="vm-api"'},
        )

    return RequestContext(
        user_id=payload["sub"],
        org_id=payload["org_id"],
        org_type=payload["org_type"],
        role=payload["role"],
        jti=jti,
    )
