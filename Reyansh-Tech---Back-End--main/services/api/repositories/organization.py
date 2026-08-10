from __future__ import annotations

import re
import uuid
from typing import Optional

from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext
from models import Organization


class OrganizationRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list(
        self,
        ctx: RequestContext,
        org_type: Optional[str] = None,
        is_active: Optional[bool] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[Organization], int]:
        query = select(Organization)

        if ctx.org_type != "PLATFORM":
            # Non-platform users can only see their own org
            query = query.where(Organization.id == uuid.UUID(ctx.org_id))
        else:
            if org_type:
                query = query.where(Organization.org_type == org_type)
            if is_active is not None:
                query = query.where(Organization.is_active == is_active)
            if search:
                query = query.where(
                    or_(
                        Organization.name.ilike(f"%{search}%"),
                        Organization.slug.ilike(f"%{search}%"),
                    )
                )

        count_result = await self.session.execute(
            select(func.count()).select_from(query.subquery())
        )
        total = count_result.scalar_one()

        result = await self.session.execute(
            query.order_by(Organization.name.asc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        return result.scalars().all(), total

    async def get(self, org_id: uuid.UUID, ctx: RequestContext) -> Optional[Organization]:
        query = select(Organization).where(Organization.id == org_id)
        if ctx.org_type != "PLATFORM":
            query = query.where(Organization.id == uuid.UUID(ctx.org_id))
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def get_by_id(self, org_id: uuid.UUID) -> Optional[Organization]:
        result = await self.session.execute(
            select(Organization).where(Organization.id == org_id)
        )
        return result.scalar_one_or_none()

    async def create(self, data: dict) -> Organization:
        name = data.get("name", "")
        data["slug"] = await self._unique_slug(name)
        data["metadata_"] = data.pop("metadata", {})
        org = Organization(**data)
        self.session.add(org)
        await self.session.commit()
        await self.session.refresh(org)
        return org

    async def update(self, org: Organization, data: dict) -> Organization:
        if "metadata" in data:
            data["metadata_"] = data.pop("metadata")
        for key, value in data.items():
            setattr(org, key, value)
        await self.session.commit()
        await self.session.refresh(org)
        return org

    async def _unique_slug(self, name: str) -> str:
        base = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-") or "org"
        slug = base
        counter = 2
        while True:
            existing = await self.session.execute(
                select(Organization).where(Organization.slug == slug)
            )
            if not existing.scalar_one_or_none():
                return slug
            slug = f"{base}-{counter}"
            counter += 1
