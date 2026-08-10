import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext, get_current_user
from auth.jwt import hash_password
from auth.rbac import Permission, get_permissions_for, require_permission
from database import get_db
from models import User
from repositories.organization import OrganizationRepository
from repositories.user import UserRepository
from schemas.common import ErrorResponse, Page
from schemas.user_mgmt import UserCreateAdmin, UserReadAdmin, UserUpdateAdmin

router = APIRouter(prefix="/users", tags=["users"])

_COMMON_ERRORS = {
    401: {"model": ErrorResponse, "description": "Missing or invalid JWT"},
    403: {"model": ErrorResponse, "description": "Insufficient permissions"},
}
_NOT_FOUND = {404: {"model": ErrorResponse, "description": "User not found"}}

# Valid roles per org type — enforced on create and role updates
_VALID_ROLES: dict[str, set[str]] = {
    "PLATFORM": {"super_admin", "support_user", "data_analyst"},
    "POLICE": {"org_admin", "operator", "dispatcher", "viewer"},
    "AMBULANCE": {"org_admin", "operator", "dispatcher", "viewer"},
    "FIRE_DEPARTMENT": {"org_admin", "operator", "viewer"},
    "CUSTOMER": {"owner"},
}


def _build_user_read(user: User) -> UserReadAdmin:
    org_type = user.organization.org_type if user.organization else ""
    return UserReadAdmin(
        id=user.id,
        organization_id=user.organization_id,
        org_name=user.organization.name if user.organization else None,
        org_type=org_type,
        username=user.username,
        email=user.email,
        role=user.role,
        first_name=user.first_name,
        last_name=user.last_name,
        phone_number=user.phone_number,
        is_active=user.is_active,
        must_change_password=user.must_change_password,
        last_login_at=user.last_login_at,
        created_at=user.created_at,
        updated_at=user.updated_at,
        permissions=get_permissions_for(org_type, user.role),
    )


@router.get("", response_model=Page[UserReadAdmin], responses={**_COMMON_ERRORS})
async def list_users(
    org_id: Optional[uuid.UUID] = None,
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    search: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
    ctx: RequestContext = Depends(require_permission(Permission.USER_READ)),
    db: AsyncSession = Depends(get_db),
):
    """
    List users.

    - PLATFORM: all users across all orgs. Use `org_id` to filter by organization.
    - All others: users within their own organization only.

    Supports filtering by `role`, `is_active`, and free-text `search`
    (matched against username, email, first_name, last_name).
    """
    page_size = min(max(page_size, 1), 100)
    repo = UserRepository(db)
    users, total = await repo.list_for_admin(ctx, org_id, role, is_active, search, page, page_size)
    return Page.of([_build_user_read(u) for u in users], total, page, page_size)


@router.post("", response_model=UserReadAdmin, status_code=201, responses={
    **_COMMON_ERRORS,
    404: {"model": ErrorResponse, "description": "Organization not found"},
    409: {"model": ErrorResponse, "description": "Email or username already taken"},
    422: {"model": ErrorResponse, "description": "Invalid role for org_type"},
})
async def create_user(
    body: UserCreateAdmin,
    ctx: RequestContext = Depends(require_permission(Permission.USER_WRITE)),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a user account.

    - PLATFORM admins may specify any `organization_id`.
    - org_admin and below may only create users in their own organization.
      If `organization_id` is omitted it defaults to the caller's org.

    The password is hashed server-side. `must_change_password` defaults to true
    so the user is prompted to set their own password on first login.
    """
    user_repo = UserRepository(db)
    org_repo = OrganizationRepository(db)

    # Resolve target org
    if body.organization_id and ctx.org_type != "PLATFORM":
        if str(body.organization_id) != ctx.org_id:
            raise HTTPException(
                status_code=403,
                detail={"error": {"code": "FORBIDDEN", "message": "You can only create users in your own organization."}},
            )
    target_org_id = body.organization_id or uuid.UUID(ctx.org_id)

    # Load org to validate role compatibility
    org = await org_repo.get_by_id(target_org_id)
    if not org:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "Organization not found."}},
        )

    valid_roles = _VALID_ROLES.get(org.org_type, set())
    if body.role not in valid_roles:
        raise HTTPException(
            status_code=422,
            detail={"error": {"code": "VALIDATION_ERROR", "message": f"Role '{body.role}' is not valid for org_type '{org.org_type}'. Valid roles: {', '.join(sorted(valid_roles))}"}},
        )

    if await user_repo.email_exists(body.email):
        raise HTTPException(
            status_code=409,
            detail={"error": {"code": "CONFLICT", "message": "A user with this email already exists."}},
        )
    if await user_repo.username_exists(body.username):
        raise HTTPException(
            status_code=409,
            detail={"error": {"code": "CONFLICT", "message": "A user with this username already exists."}},
        )

    user = await user_repo.create({
        "organization_id": target_org_id,
        "email": body.email,
        "username": body.username,
        "password_hash": hash_password(body.password),
        "first_name": body.first_name,
        "last_name": body.last_name,
        "phone_number": body.phone_number,
        "role": body.role,
        "must_change_password": body.must_change_password,
    })

    # Reload with organization relationship
    user = await user_repo.get_for_admin(user.id, ctx)
    return _build_user_read(user)


@router.get("/{user_id}", response_model=UserReadAdmin, responses={**_COMMON_ERRORS, **_NOT_FOUND})
async def get_user(
    user_id: uuid.UUID,
    ctx: RequestContext = Depends(require_permission(Permission.USER_READ)),
    db: AsyncSession = Depends(get_db),
):
    """Get a single user. Non-platform callers can only fetch users in their own org."""
    repo = UserRepository(db)
    user = await repo.get_for_admin(user_id, ctx)
    if not user:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "User not found."}},
        )
    return _build_user_read(user)


@router.patch("/{user_id}", response_model=UserReadAdmin, responses={**_COMMON_ERRORS, **_NOT_FOUND, 422: {"model": ErrorResponse, "description": "Invalid role for org_type"}})
async def update_user(
    user_id: uuid.UUID,
    body: UserUpdateAdmin,
    ctx: RequestContext = Depends(require_permission(Permission.USER_WRITE)),
    db: AsyncSession = Depends(get_db),
):
    """
    Partial update a user. Fields omitted from the request body are unchanged.

    - `password`: if provided, is hashed and replaces the current password hash.
    - `role`: validated against the user's organization type.
    - `is_active=false`: deactivates the user (soft delete).
    """
    repo = UserRepository(db)
    user = await repo.get_for_admin(user_id, ctx)
    if not user:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "User not found."}},
        )

    updates = body.model_dump(exclude_unset=True)

    if "role" in updates and updates["role"] is not None:
        org_type = user.organization.org_type if user.organization else ""
        valid_roles = _VALID_ROLES.get(org_type, set())
        if updates["role"] not in valid_roles:
            raise HTTPException(
                status_code=422,
                detail={"error": {"code": "VALIDATION_ERROR", "message": f"Role '{updates['role']}' is not valid for org_type '{org_type}'."}},
            )

    if "password" in updates and updates["password"]:
        updates["password_hash"] = hash_password(updates.pop("password"))
    else:
        updates.pop("password", None)

    if not updates:
        return _build_user_read(user)

    user = await repo.update_fields(user, updates)
    user = await repo.get_for_admin(user.id, ctx)
    return _build_user_read(user)


@router.delete("/{user_id}", status_code=204, responses={**_COMMON_ERRORS, **_NOT_FOUND})
async def deactivate_user(
    user_id: uuid.UUID,
    ctx: RequestContext = Depends(require_permission(Permission.USER_WRITE)),
    db: AsyncSession = Depends(get_db),
):
    """
    Deactivate a user (soft delete — sets is_active=false).
    The user record and all associated data are preserved.
    Deactivated users cannot log in.
    """
    repo = UserRepository(db)
    user = await repo.get_for_admin(user_id, ctx)
    if not user:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "User not found."}},
        )
    await repo.update_fields(user, {"is_active": False})
