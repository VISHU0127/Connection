from __future__ import annotations

import json
import secrets
import uuid
from typing import Optional

import redis.asyncio as aioredis
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext
from models import Device, Vehicle


class DeviceRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_device_id(self, device_id: str) -> Optional[Device]:
        result = await self.session.execute(
            select(Device).where(Device.device_id == device_id)
        )
        return result.scalar_one_or_none()

    async def get_by_mac(self, mac_address: str) -> Optional[Device]:
        result = await self.session.execute(
            select(Device).where(Device.mac_address == mac_address)
        )
        return result.scalar_one_or_none()

    async def provision(self, data: dict) -> Device:
        """Create a new device record. EMQX credential creation is handled by the router."""
        device = Device(
            device_id=f"dev_{secrets.token_urlsafe(16)}",
            **data,
        )
        self.session.add(device)
        await self.session.commit()
        await self.session.refresh(device)
        return device

    async def update_status(self, device: Device, is_active: bool) -> Device:
        device.is_active = is_active
        await self.session.commit()
        await self.session.refresh(device)
        return device

    async def list(
        self,
        ctx: RequestContext,
        vehicle_id: Optional[uuid.UUID] = None,
        is_active: Optional[bool] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> tuple[list[Device], int]:
        q = select(Device)
        if ctx.org_type != "PLATFORM":
            q = q.where(Device.organization_id == uuid.UUID(ctx.org_id))
        if vehicle_id is not None:
            q = q.where(Device.vehicle_id == vehicle_id)
        if is_active is not None:
            q = q.where(Device.is_active == is_active)
        count_q = select(func.count()).select_from(q.subquery())
        total = (await self.session.execute(count_q)).scalar_one()
        result = await self.session.execute(
            q.order_by(Device.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
        )
        return list(result.scalars().all()), total

    async def list_active(self) -> list[Device]:
        result = await self.session.execute(
            select(Device).where(Device.is_active == True)  # noqa: E712
        )
        return list(result.scalars().all())

    async def write_device_meta_cache(
        self, redis_client: aioredis.Redis, device: Device, ttl: int = 86400
    ) -> None:
        """
        Write device_meta:{device_id} → {vehicle_category, org_id} to Redis.
        Read by state-updater to enrich pub/sub messages for WS RBAC fan-out.
        """
        if not device.vehicle_id:
            return
        result = await self.session.execute(
            select(Vehicle.id, Vehicle.vehicle_category, Vehicle.organization_id)
            .where(Vehicle.id == device.vehicle_id)
        )
        row = result.first()
        if not row:
            return
        meta = {"vehicle_id": str(row[0]), "vehicle_category": row[1], "org_id": str(row[2])}
        await redis_client.set(
            f"device_meta:{device.mac_address}",
            json.dumps(meta),
            ex=ttl,
        )

    async def invalidate_device_meta_cache(
        self, redis_client: aioredis.Redis, mac_address: str
    ) -> None:
        """Invalidate device_meta cache on deactivation so state-updater sees the change."""
        await redis_client.delete(f"device_meta:{mac_address}")
