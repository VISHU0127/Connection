import uuid
from typing import Optional

from sqlalchemy import func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from auth.dependencies import RequestContext
from models import User


class UserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_email(self, email: str) -> Optional[User]:
        result = await self.session.execute(
            select(User)
            .options(selectinload(User.organization))
            .where(func.lower(User.email) == email.lower())
        )
        return result.scalar_one_or_none()

    async def get_by_id(self, user_id: uuid.UUID) -> Optional[User]:
        result = await self.session.execute(
            select(User)
            .options(selectinload(User.organization))
            .where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_token_prefix(self, prefix: str) -> list[User]:
        result = await self.session.execute(
            select(User)
            .options(selectinload(User.organization))
            .where(User.refresh_token_prefix == prefix)
        )
        return result.scalars().all()

    async def update_refresh_token(
        self,
        user_id: uuid.UUID,
        refresh_token_hash: Optional[str],
        refresh_token_prefix: Optional[str],
        expires_at,
    ) -> None:
        await self.session.execute(
            update(User)
            .where(User.id == user_id)
            .values(
                refresh_token_hash=refresh_token_hash,
                refresh_token_prefix=refresh_token_prefix,
                refresh_token_expires_at=expires_at,
            )
        )
        await self.session.commit()

    async def atomic_clear_refresh_token(self, user_id: uuid.UUID, current_hash: str) -> int:
        result = await self.session.execute(
            update(User)
            .where(User.id == user_id, User.refresh_token_hash == current_hash)
            .values(refresh_token_hash=None, refresh_token_prefix=None, refresh_token_expires_at=None)
        )
        await self.session.commit()
        return result.rowcount

    async def update_last_login(self, user_id: uuid.UUID) -> None:
        from datetime import datetime, timezone
        await self.session.execute(
            update(User).where(User.id == user_id).values(last_login_at=datetime.now(timezone.utc))
        )
        await self.session.commit()

    async def create(self, data: dict) -> User:
        user = User(**data)
        self.session.add(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user

    # --- Admin management methods ---

    async def list_for_admin(
        self,
        ctx: RequestContext,
        org_id: Optional[uuid.UUID] = None,
        role: Optional[str] = None,
        is_active: Optional[bool] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> tuple[list[User], int]:
        query = select(User).options(selectinload(User.organization))

        if ctx.org_type != "PLATFORM":
            query = query.where(User.organization_id == uuid.UUID(ctx.org_id))
        elif org_id:
            query = query.where(User.organization_id == org_id)

        if role:
            query = query.where(User.role == role)
        if is_active is not None:
            query = query.where(User.is_active == is_active)
        if search:
            query = query.where(
                or_(
                    User.username.ilike(f"%{search}%"),
                    User.email.ilike(f"%{search}%"),
                    User.first_name.ilike(f"%{search}%"),
                    User.last_name.ilike(f"%{search}%"),
                )
            )

        count_result = await self.session.execute(
            select(func.count()).select_from(query.subquery())
        )
        total = count_result.scalar_one()

        result = await self.session.execute(
            query.order_by(User.created_at.desc())
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        return result.scalars().all(), total

    async def get_for_admin(self, user_id: uuid.UUID, ctx: RequestContext) -> Optional[User]:
        query = (
            select(User)
            .options(selectinload(User.organization))
            .where(User.id == user_id)
        )
        if ctx.org_type != "PLATFORM":
            query = query.where(User.organization_id == uuid.UUID(ctx.org_id))
        result = await self.session.execute(query)
        return result.scalar_one_or_none()

    async def update_fields(self, user: User, data: dict) -> User:
        for key, value in data.items():
            setattr(user, key, value)
        await self.session.commit()
        await self.session.refresh(user)
        return user

    async def username_exists(self, username: str) -> bool:
        result = await self.session.execute(
            select(User.id).where(func.lower(User.username) == username.lower())
        )
        return result.scalar_one_or_none() is not None

    async def email_exists(self, email: str) -> bool:
        result = await self.session.execute(
            select(User.id).where(func.lower(User.email) == email.lower())
        )
        return result.scalar_one_or_none() is not None
