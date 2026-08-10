"""
Platform admin bootstrap — runs at API startup.
Creates the PLATFORM org and default super_admin from .env credentials.
Idempotent: if the user already exists, nothing is changed (password is never overwritten).
"""
import logging

from sqlalchemy import select

from auth.jwt import hash_password
from config import settings
from database import AsyncSessionFactory
from models.organization import Organization
from models.user import User

logger = logging.getLogger("api.seed")


async def seed_platform_admin() -> None:
    """Create PLATFORM org + super_admin from .env if they don't exist."""
    if not settings.admin_email:
        logger.debug("seed_skipped_no_admin_email")
        return

    async with AsyncSessionFactory() as db:
        # Find PLATFORM org by org_type first, then fall back to slug
        result = await db.execute(
            select(Organization).where(
                (Organization.org_type == "PLATFORM") | (Organization.slug == "platform")
            ).limit(1)
        )
        org = result.scalar_one_or_none()

        if not org:
            org = Organization(
                name="Platform",
                slug="platform",
                org_type="PLATFORM",
                is_active=True,
            )
            db.add(org)
            await db.flush()
            logger.info("platform_org_created")
        elif org.org_type != "PLATFORM":
            # Fix the org_type if it was created with wrong type
            org.org_type = "PLATFORM"
            await db.flush()
            logger.info("platform_org_type_corrected")

        # Skip if admin user already exists (never overwrite password)
        result = await db.execute(
            select(User).where(User.email == settings.admin_email.lower()).limit(1)
        )
        if result.scalar_one_or_none():
            logger.info("admin_seed_skipped_already_exists", extra={"email": settings.admin_email})
            return

        if not settings.admin_password:
            logger.warning("admin_seed_skipped_no_password_set")
            return

        db.add(User(
            organization_id=org.id,
            email=settings.admin_email.lower(),
            username=settings.admin_email.lower(),
            password_hash=hash_password(settings.admin_password),
            role="super_admin",
            first_name="Platform",
            last_name="Admin",
            is_active=True,
        ))
        await db.commit()
        logger.info("platform_admin_seeded", extra={"email": settings.admin_email})
