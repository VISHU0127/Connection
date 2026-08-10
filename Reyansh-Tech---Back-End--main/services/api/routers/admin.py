"""
Admin endpoints — platform-operator only.
Currently: manual EMQX credential sync.
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from auth.rbac import Permission, require_permission
from auth.dependencies import RequestContext
from config import settings
from database import get_db
from emqx_client import EmqxClient
from repositories.device import DeviceRepository

router = APIRouter(prefix="/admin", tags=["admin"])


@router.post("/emqx/sync")
async def sync_emqx_credentials(
    ctx: RequestContext = Depends(require_permission(Permission.PLATFORM_ADMIN)),
    db: AsyncSession = Depends(get_db),
):
    """
    Reconcile EMQX credentials against active devices in Postgres.
    Creates missing credentials, removes credentials for inactive devices.
    Safe to call multiple times — fully idempotent.
    """
    repo = DeviceRepository(db)
    active_devices = await repo.list_active()

    device_dicts = [
        {"mac_address": d.mac_address, "vehicle_id": str(d.vehicle_id) if d.vehicle_id else ""}
        for d in active_devices
        if d.mac_address
    ]

    emqx = EmqxClient(settings.emqx_api_url, settings.emqx_api_key, settings.emqx_api_secret)
    result = await emqx.sync(device_dicts, settings.emqx_device_secret_salt)

    return {
        "status": "ok" if result["errors"] == 0 else "partial",
        **result,
    }
