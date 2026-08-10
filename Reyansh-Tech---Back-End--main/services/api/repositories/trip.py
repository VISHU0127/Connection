from __future__ import annotations

import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext
from models import Device, Trip, TelemetryRaw, Vehicle


class TripRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list(
        self,
        ctx: RequestContext,
        vehicle_id: Optional[uuid.UUID] = None,
        status: Optional[str] = None,
        from_dt: Optional[datetime] = None,
        to_dt: Optional[datetime] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[Trip], int]:
        query = select(Trip).join(Vehicle, Trip.vehicle_id == Vehicle.id)
        query = self._apply_org_filter(query, ctx)

        if vehicle_id:
            query = query.where(Trip.vehicle_id == vehicle_id)
        if status:
            query = query.where(Trip.status == status.upper())
        if from_dt:
            query = query.where(Trip.start_time >= from_dt)
        if to_dt:
            query = query.where(Trip.start_time <= to_dt)

        count_result = await self.session.execute(
            select(func.count()).select_from(query.subquery())
        )
        total = count_result.scalar_one()

        result = await self.session.execute(
            query.order_by(Trip.start_time.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        return result.scalars().all(), total

    async def get(self, trip_id: uuid.UUID, ctx: RequestContext) -> Optional[Trip]:
        query = (
            select(Trip)
            .join(Vehicle, Trip.vehicle_id == Vehicle.id)
            .where(Trip.id == trip_id)
        )
        query = self._apply_org_filter(query, ctx)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_telemetry_by_vehicle(
        self,
        vehicle_id: uuid.UUID,
        from_dt: Optional[datetime] = None,
        to_dt: Optional[datetime] = None,
        page: int = 1,
        page_size: int = 100,
    ) -> tuple[list[TelemetryRaw], int]:
        # Get the active device for this vehicle
        device_result = await self.session.execute(
            select(Device)
            .where(Device.vehicle_id == vehicle_id, Device.is_active == True)
            .order_by(Device.created_at.desc())
            .limit(1)
        )
        device = device_result.scalar_one_or_none()
        if not device:
            return [], 0

        query = select(TelemetryRaw).where(TelemetryRaw.device_id == device.mac_address)
        if from_dt:
            query = query.where(TelemetryRaw.event_timestamp >= from_dt)
        if to_dt:
            query = query.where(TelemetryRaw.event_timestamp <= to_dt)

        count_result = await self.session.execute(
            select(func.count()).select_from(query.subquery())
        )
        total = count_result.scalar_one()

        result = await self.session.execute(
            query.order_by(TelemetryRaw.event_timestamp.asc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        return result.scalars().all(), total

    async def get_trip_telemetry(
        self,
        trip: Trip,
        page: int = 1,
        page_size: int = 500,
    ) -> tuple[list[TelemetryRaw], int]:
        device_result = await self.session.execute(
            select(Device)
            .where(Device.vehicle_id == trip.vehicle_id, Device.is_active == True)
            .order_by(Device.created_at.desc())
            .limit(1)
        )
        device = device_result.scalar_one_or_none()
        if not device:
            return [], 0

        query = select(TelemetryRaw).where(
            TelemetryRaw.device_id == device.mac_address,
            TelemetryRaw.event_timestamp >= trip.start_time,
        )
        if trip.end_time:
            query = query.where(TelemetryRaw.event_timestamp <= trip.end_time)

        count_result = await self.session.execute(
            select(func.count()).select_from(query.subquery())
        )
        total = count_result.scalar_one()

        result = await self.session.execute(
            query.order_by(TelemetryRaw.event_timestamp.asc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        return result.scalars().all(), total

    def _apply_org_filter(self, query, ctx: RequestContext):
        if ctx.org_type == "PLATFORM":
            return query
        if ctx.org_type == "POLICE":
            return query.where(
                or_(
                    Vehicle.vehicle_category == "USER_VEHICLE",
                    and_(
                        Vehicle.vehicle_category == "EMERGENCY_VEHICLE",
                        Vehicle.organization_id == uuid.UUID(ctx.org_id),
                    ),
                )
            )
        return query.where(Vehicle.organization_id == uuid.UUID(ctx.org_id))
