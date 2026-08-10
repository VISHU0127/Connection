import logging
import uuid
from typing import Optional

import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext
from auth.rbac import Permission, require_permission
from config import settings
from database import get_db
from emqx_client import EmqxClient, derive_device_password
from redis_client import get_redis
from repositories.device import DeviceRepository
from schemas.common import ErrorResponse, Page
from schemas.device import DeviceProvision, DeviceProvisionResponse, DeviceRead

router = APIRouter(prefix="/devices", tags=["devices"])

_COMMON_ERRORS = {
    401: {"model": ErrorResponse, "description": "Missing or invalid JWT"},
    403: {"model": ErrorResponse, "description": "Insufficient permissions"},
}


def _get_emqx_client() -> EmqxClient:
    return EmqxClient(settings.emqx_api_url, settings.emqx_api_key, settings.emqx_api_secret)


@router.get("", response_model=Page[DeviceRead], responses={**_COMMON_ERRORS})
async def list_devices(
    vehicle_id: Optional[uuid.UUID] = None,
    is_active: Optional[bool] = None,
    page: int = 1,
    page_size: int = 50,
    ctx: RequestContext = Depends(require_permission(Permission.DEVICE_READ)),
    db: AsyncSession = Depends(get_db),
):
    """
    List devices.

    - PLATFORM: all devices across all orgs.
    - All others: devices belonging to their own organization.

    Filter by `vehicle_id` or `is_active` (true = online/active, false = deactivated).
    """
    page_size = min(max(page_size, 1), 100)
    repo = DeviceRepository(db)
    devices, total = await repo.list(ctx, vehicle_id, is_active, page, page_size)
    return Page.of([DeviceRead.model_validate(d) for d in devices], total, page, page_size)


@router.post("", response_model=DeviceProvisionResponse, status_code=201)
async def provision_device(
    body: DeviceProvision,
    ctx: RequestContext = Depends(require_permission(Permission.DEVICE_WRITE)),
    db: AsyncSession = Depends(get_db),
    redis_client: aioredis.Redis = Depends(get_redis),
):
    """
    Provision a new OBD device.

    Creates the device record in Postgres, registers EMQX credentials, and writes the
    device metadata to the Redis cache used by the state-updater for RBAC enrichment.

    The response includes `emqx_username` (the MAC address) and `emqx_password` — show
    these once and burn them into firmware. The password is derived deterministically from
    `sha256(mac:vehicle_id:salt)` so it can be re-derived via POST /simulator/lookup-vehicle
    if needed.

    If EMQX credential creation fails the Postgres record is rolled back — the response
    will be 502. Retry is safe (idempotent).
    """
    repo = DeviceRepository(db)
    data = body.model_dump()
    data["metadata_"] = data.pop("metadata", {})
    data["organization_id"] = data.get("organization_id") or uuid.UUID(ctx.org_id)

    device = await repo.provision(data)

    vehicle_id = str(device.vehicle_id) if device.vehicle_id else ""
    emqx_password = derive_device_password(device.mac_address, vehicle_id, settings.emqx_device_secret_salt)

    emqx = _get_emqx_client()
    try:
        await emqx.create_credential(device.mac_address, emqx_password)
    except Exception as exc:
        # Roll back DB record and any stale cache if EMQX registration fails
        await db.delete(device)
        await db.commit()
        await repo.invalidate_device_meta_cache(redis_client, device.mac_address)
        raise HTTPException(status_code=502, detail=f"EMQX credential creation failed: {exc}") from exc

    # Write device_meta cache only after EMQX credentials are confirmed
    await repo.write_device_meta_cache(redis_client, device)

    resp = DeviceProvisionResponse.model_validate(device)
    resp = resp.model_copy(update={
        "emqx_username": device.mac_address,
        "emqx_password": emqx_password,
    })
    return resp


@router.get("/{device_id}", response_model=DeviceRead)
async def get_device(
    device_id: str,
    ctx: RequestContext = Depends(require_permission(Permission.DEVICE_READ)),
    db: AsyncSession = Depends(get_db),
):
    repo = DeviceRepository(db)
    device = await repo.get_by_device_id(device_id)
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
    return DeviceRead.model_validate(device)


@router.patch("/{device_id}/status", response_model=DeviceRead)
async def update_device_status(
    device_id: str,
    is_active: bool,
    ctx: RequestContext = Depends(require_permission(Permission.DEVICE_STATUS_WRITE)),
    db: AsyncSession = Depends(get_db),
    redis_client: aioredis.Redis = Depends(get_redis),
):
    """
    Activate or deactivate a device.

    Deactivating (`is_active=false`) removes the EMQX credential so the device can no
    longer publish telemetry. The Redis device-meta cache entry is invalidated in both cases.
    """
    repo = DeviceRepository(db)
    device = await repo.get_by_device_id(device_id)
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    device = await repo.update_status(device, is_active)
    await repo.invalidate_device_meta_cache(redis_client, device.mac_address)

    if not is_active and device.mac_address:
        emqx = _get_emqx_client()
        try:
            await emqx.delete_credential(device.mac_address)
        except Exception as exc:
            logging.getLogger("api.devices").warning(
                "emqx_delete_failed", extra={"device_id": device_id, "error": str(exc)}
            )

    return DeviceRead.model_validate(device)
