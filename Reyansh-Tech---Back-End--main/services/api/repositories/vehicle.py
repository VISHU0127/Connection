from __future__ import annotations

"""
Vehicle repository — enforces org-scoped RBAC filtering.

PLATFORM: sees all vehicles.
POLICE:   all USER_VEHICLEs + own EMERGENCY_VEHICLEs.
AMBULANCE: own EMERGENCY_VEHICLEs + USER_VEHICLEs linked to active incidents.
"""
import uuid
from typing import Optional

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext
from models import Incident, IncidentOrganizationAccess, IncidentVehicle, Vehicle


class VehicleRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list(
        self,
        ctx: RequestContext,
        vehicle_category: Optional[str] = None,
        is_active: Optional[bool] = True,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> tuple[list[Vehicle], int]:
        query = select(Vehicle)

        if is_active is not None:
            query = query.where(Vehicle.is_active == is_active)
        if vehicle_category:
            query = query.where(Vehicle.vehicle_category == vehicle_category)
        if search:
            query = query.where(
                or_(
                    Vehicle.registration_number.ilike(f"%{search}%"),
                    Vehicle.make.ilike(f"%{search}%"),
                    Vehicle.model.ilike(f"%{search}%"),
                    Vehicle.vin.ilike(f"%{search}%"),
                )
            )

        query = self._apply_org_filter(query, ctx)

        # Count
        count_result = await self.session.execute(select(func.count()).select_from(query.subquery()))
        total = count_result.scalar_one()

        # Page
        result = await self.session.execute(
            query.offset((page - 1) * page_size).limit(page_size).order_by(Vehicle.created_at.desc())
        )
        return result.scalars().all(), total

    async def get(self, vehicle_id: uuid.UUID, ctx: RequestContext) -> Optional[Vehicle]:
        query = select(Vehicle).where(Vehicle.id == vehicle_id)
        query = self._apply_org_filter(query, ctx)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def create(self, data: dict) -> Vehicle:
        vehicle = Vehicle(**data)
        self.session.add(vehicle)
        await self.session.commit()
        await self.session.refresh(vehicle)
        return vehicle

    async def update(self, vehicle: Vehicle, data: dict) -> Vehicle:
        for key, value in data.items():
            setattr(vehicle, key, value)
        await self.session.commit()
        await self.session.refresh(vehicle)
        return vehicle

    def _apply_org_filter(self, query, ctx: RequestContext):
        org_type = ctx.org_type

        if org_type == "PLATFORM":
            return query  # no filter

        if org_type == "POLICE":
            return query.where(
                or_(
                    Vehicle.vehicle_category == "USER_VEHICLE",
                    and_(
                        Vehicle.vehicle_category == "EMERGENCY_VEHICLE",
                        Vehicle.organization_id == uuid.UUID(ctx.org_id),
                    ),
                )
            )

        if org_type == "AMBULANCE":
            # Active incident subquery for this ambulance org
            active_incident_vehicle_ids = (
                select(IncidentVehicle.vehicle_id)
                .join(Incident, Incident.id == IncidentVehicle.incident_id)
                .join(
                    IncidentOrganizationAccess,
                    and_(
                        IncidentOrganizationAccess.incident_id == Incident.id,
                        IncidentOrganizationAccess.organization_id == uuid.UUID(ctx.org_id),
                        IncidentOrganizationAccess.revoked_at.is_(None),
                    ),
                )
                .where(Incident.status != "CLOSED")
                .scalar_subquery()
            )
            return query.where(
                or_(
                    and_(
                        Vehicle.vehicle_category == "EMERGENCY_VEHICLE",
                        Vehicle.organization_id == uuid.UUID(ctx.org_id),
                    ),
                    and_(
                        Vehicle.vehicle_category == "USER_VEHICLE",
                        Vehicle.id.in_(active_incident_vehicle_ids),
                    ),
                )
            )

        # Default: own org only (CUSTOMER, FIRE_DEPARTMENT, etc.)
        return query.where(Vehicle.organization_id == uuid.UUID(ctx.org_id))
