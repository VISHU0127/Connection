import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext, get_current_user
from auth.rbac import Permission, require_permission
from database import get_db
from repositories.organization import OrganizationRepository
from schemas.common import ErrorResponse, Page
from schemas.organization import OrganizationCreate, OrganizationRead, OrganizationUpdate

router = APIRouter(prefix="/organizations", tags=["organizations"])

VALID_ORG_TYPES = {"PLATFORM", "POLICE", "AMBULANCE", "FIRE_DEPARTMENT", "CUSTOMER"}

_COMMON_ERRORS = {
    401: {"model": ErrorResponse, "description": "Missing or invalid JWT"},
    403: {"model": ErrorResponse, "description": "Insufficient permissions"},
}
_NOT_FOUND = {404: {"model": ErrorResponse, "description": "Organization not found"}}


@router.get("", response_model=Page[OrganizationRead], responses={**_COMMON_ERRORS})
async def list_organizations(
    org_type: Optional[str] = None,
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    ctx: RequestContext = Depends(require_permission(Permission.ORG_READ)),
    db: AsyncSession = Depends(get_db),
):
    """
    List organizations.

    - PLATFORM: all organizations (filterable by org_type, is_active, search).
    - All others: returns only their own organization.

    **FE integration note:**

    This endpoint backs the "Emergency Services" management page in the Super Admin
    dashboard (`/admin/services`). Use `org_type` to filter by service category:
    `POLICE`, `AMBULANCE`, `FIRE_DEPARTMENT`, `CUSTOMER`, `PLATFORM`.
    """
    page_size = min(max(page_size, 1), 100)
    repo = OrganizationRepository(db)
    orgs, total = await repo.list(ctx, org_type, is_active, search, page, page_size)
    return Page.of([OrganizationRead.model_validate(o) for o in orgs], total, page, page_size)


@router.post("", response_model=OrganizationRead, status_code=201, responses={**_COMMON_ERRORS, 422: {"model": ErrorResponse, "description": "Invalid org_type"}})
async def create_organization(
    body: OrganizationCreate,
    ctx: RequestContext = Depends(require_permission(Permission.ORG_WRITE)),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a new organization. PLATFORM super_admin only.

    The slug is auto-generated from the name — do not pass it manually.
    Valid org_type values: PLATFORM, POLICE, AMBULANCE, FIRE_DEPARTMENT, CUSTOMER.
    """
    if ctx.org_type != "PLATFORM":
        raise HTTPException(
            status_code=403,
            detail={"error": {"code": "FORBIDDEN", "message": "Only PLATFORM admins can create organizations."}},
        )
    if body.org_type not in VALID_ORG_TYPES:
        raise HTTPException(
            status_code=422,
            detail={"error": {"code": "VALIDATION_ERROR", "message": f"org_type must be one of: {', '.join(sorted(VALID_ORG_TYPES))}"}},
        )
    repo = OrganizationRepository(db)
    org = await repo.create({"name": body.name, "org_type": body.org_type, "metadata": body.metadata})
    return OrganizationRead.model_validate(org)


@router.get("/{org_id}", response_model=OrganizationRead, responses={**_COMMON_ERRORS, **_NOT_FOUND})
async def get_organization(
    org_id: uuid.UUID,
    ctx: RequestContext = Depends(require_permission(Permission.ORG_READ)),
    db: AsyncSession = Depends(get_db),
):
    """Get a single organization. Non-platform users can only fetch their own org."""
    repo = OrganizationRepository(db)
    org = await repo.get(org_id, ctx)
    if not org:
        raise HTTPException(status_code=404, detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "Organization not found."}})
    return OrganizationRead.model_validate(org)


@router.patch("/{org_id}", response_model=OrganizationRead, responses={**_COMMON_ERRORS, **_NOT_FOUND})
async def update_organization(
    org_id: uuid.UUID,
    body: OrganizationUpdate,
    ctx: RequestContext = Depends(require_permission(Permission.ORG_WRITE)),
    db: AsyncSession = Depends(get_db),
):
    """
    Update an organization's name, active status, or metadata.

    - PLATFORM: can update any org.
    - org_admin: can update their own org only.
    """
    repo = OrganizationRepository(db)
    org = await repo.get(org_id, ctx)
    if not org:
        raise HTTPException(status_code=404, detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "Organization not found."}})
    updates = {k: v for k, v in body.model_dump(exclude_unset=True).items() if v is not None}
    if not updates:
        return OrganizationRead.model_validate(org)
    org = await repo.update(org, updates)
    return OrganizationRead.model_validate(org)


@router.delete("/{org_id}", status_code=204, responses={**_COMMON_ERRORS, **_NOT_FOUND})
async def deactivate_organization(
    org_id: uuid.UUID,
    ctx: RequestContext = Depends(require_permission(Permission.ORG_DELETE)),
    db: AsyncSession = Depends(get_db),
):
    """
    Soft-delete an organization by setting is_active=false. PLATFORM super_admin only.
    Does not delete the record — all associated data is preserved.
    """
    if ctx.org_type != "PLATFORM":
        raise HTTPException(
            status_code=403,
            detail={"error": {"code": "FORBIDDEN", "message": "Only PLATFORM admins can deactivate organizations."}},
        )
    repo = OrganizationRepository(db)
    org = await repo.get_by_id(org_id)
    if not org:
        raise HTTPException(status_code=404, detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "Organization not found."}})
    await repo.update(org, {"is_active": False})
