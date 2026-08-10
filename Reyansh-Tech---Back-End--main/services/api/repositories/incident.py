from __future__ import annotations

import uuid
from typing import Optional

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from auth.dependencies import RequestContext
from models import Incident, IncidentOrganizationAccess


class IncidentRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list(
        self,
        ctx: RequestContext,
        status: Optional[str] = None,
        incident_type: Optional[str] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> tuple[list[Incident], int]:
        query = select(Incident)

        if status:
            query = query.where(Incident.status == status)
        if incident_type:
            query = query.where(Incident.incident_type == incident_type)

        query = self._apply_org_filter(query, ctx)

        count_result = await self.session.execute(select(func.count()).select_from(query.subquery()))
        total = count_result.scalar_one()

        result = await self.session.execute(
            query.offset((page - 1) * page_size).limit(page_size).order_by(Incident.event_time.desc())
        )
        return result.scalars().all(), total

    async def get(self, incident_id: uuid.UUID, ctx: RequestContext) -> Optional[Incident]:
        query = select(Incident).where(Incident.id == incident_id)
        query = self._apply_org_filter(query, ctx)
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def create(self, data: dict) -> Incident:
        incident = Incident(**data)
        self.session.add(incident)
        await self.session.commit()
        await self.session.refresh(incident)
        return incident

    async def update_status(self, incident: Incident, status: str) -> Incident:
        incident.status = status
        await self.session.commit()
        await self.session.refresh(incident)
        return incident

    def _apply_org_filter(self, query, ctx: RequestContext):
        if ctx.org_type == "PLATFORM":
            return query

        # All other org types require an IOA row
        ioa_subquery = (
            select(IncidentOrganizationAccess.incident_id)
            .where(IncidentOrganizationAccess.organization_id == uuid.UUID(ctx.org_id))
            .scalar_subquery()
        )
        return query.where(Incident.id.in_(ioa_subquery))
