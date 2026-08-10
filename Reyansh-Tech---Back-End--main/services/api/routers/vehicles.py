import uuid
from datetime import datetime
from typing import Optional

import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext, get_current_user
from auth.rbac import Permission, require_permission
from database import get_db
from redis_client import get_redis
from repositories.trip import TripRepository
from repositories.vehicle import VehicleRepository
from schemas.common import ErrorResponse, Page
from schemas.trip import TelemetryPointRead, VehicleStateRead
from schemas.vehicle import VehicleCreate, VehicleRead, VehicleUpdate

_VEHICLE_ERRORS = {
    401: {"model": ErrorResponse, "description": "Missing or invalid JWT"},
    403: {"model": ErrorResponse, "description": "Insufficient permissions"},
    404: {"model": ErrorResponse, "description": "Vehicle not found"},
}

router = APIRouter(prefix="/vehicles", tags=["vehicles"])


@router.get("", response_model=Page[VehicleRead])
async def list_vehicles(
    vehicle_category: Optional[str] = None,
    is_active: Optional[bool] = True,
    search: Optional[str] = None,
    page: int = 1,
    page_size: int = 50,
    ctx: RequestContext = Depends(require_permission(Permission.VEHICLE_READ)),
    db: AsyncSession = Depends(get_db),
):
    """
    List vehicles with RBAC filtering applied at the query layer.

    - PLATFORM: all vehicles
    - POLICE: USER_VEHICLEs + own EMERGENCY_VEHICLEs
    - AMBULANCE / FIRE_DEPARTMENT: own EMERGENCY_VEHICLEs only
    - CUSTOMER: own org's USER_VEHICLEs only

    Supports filtering by `vehicle_category`, `is_active`, and free-text `search`
    (matched against registration number, make, and model).
    """
    page_size = min(max(page_size, 1), 100)
    repo = VehicleRepository(db)
    vehicles, total = await repo.list(ctx, vehicle_category, is_active, search, page, page_size)
    return Page.of([VehicleRead.model_validate(v) for v in vehicles], total, page, page_size)


@router.get("/{vehicle_id}", response_model=VehicleRead)
async def get_vehicle(
    vehicle_id: uuid.UUID,
    ctx: RequestContext = Depends(require_permission(Permission.VEHICLE_READ)),
    db: AsyncSession = Depends(get_db),
):
    """Get a single vehicle by UUID. Returns 404 if the vehicle does not exist or is not visible to the caller."""
    repo = VehicleRepository(db)
    vehicle = await repo.get(vehicle_id, ctx)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return VehicleRead.model_validate(vehicle)


@router.post("", response_model=VehicleRead, status_code=201)
async def create_vehicle(
    body: VehicleCreate,
    ctx: RequestContext = Depends(require_permission(Permission.VEHICLE_WRITE)),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a vehicle.

    - PLATFORM admins may create any vehicle category.
    - Emergency orgs (POLICE / AMBULANCE / FIRE_DEPARTMENT) may only create EMERGENCY_VEHICLEs.
    - Private customers must use POST /onboard instead.

    `organization_id` defaults to the caller's own org if omitted.
    """
    # Emergency orgs can only create EMERGENCY_VEHICLEs (their own fleet).
    # Only PLATFORM can create USER_VEHICLEs via this endpoint.
    if ctx.org_type not in ("PLATFORM",) and body.vehicle_category == "USER_VEHICLE":
        raise HTTPException(
            status_code=403,
            detail={"error": {"code": "FORBIDDEN", "message": "Only platform admins can create USER_VEHICLEs. Private customers use POST /onboard."}},
        )

    repo = VehicleRepository(db)
    data = body.model_dump()
    data["metadata_"] = data.pop("metadata", {})
    # Default organization to the caller's org if not explicitly provided
    data["organization_id"] = data.get("organization_id") or uuid.UUID(ctx.org_id)
    vehicle = await repo.create(data)
    return VehicleRead.model_validate(vehicle)


@router.get("/{vehicle_id}/telemetry/latest", response_model=VehicleStateRead, responses={**_VEHICLE_ERRORS})
async def get_vehicle_telemetry_latest(
    vehicle_id: uuid.UUID,
    ctx: RequestContext = Depends(require_permission(Permission.TELEMETRY_READ)),
    db: AsyncSession = Depends(get_db),
    redis_client: aioredis.Redis = Depends(get_redis),
):
    """
    Return the latest known state for a vehicle, read directly from Redis.

    This is a fast (<50ms) snapshot of the vehicle's current telemetry — position,
    speed, RPM, temperatures, battery, passenger count, and last_updated timestamp.
    Use this to seed a vehicle detail panel on page load.

    For continuous live updates, connect to the WebSocket endpoint instead — each
    incoming vehicle_state message is a new data point for rolling live graphs.

    Returns 404 if the vehicle does not exist or is not accessible.
    Returns 200 with null fields if the vehicle exists but has not yet sent telemetry
    (i.e. no Redis state found).

    **FE integration note:**

    All fields in the response are **strings** (raw Redis hash values). Parse to numbers
    before charting or arithmetic:
    - `lat`, `lng` → `parseFloat()`
    - `gps_speed`, `obd_speed`, `rpm`, `coolant_c`, `cabin_temp`, `engine_temp`,
      `car_battery_v`, `signal_csq`, `person_count` → `parseFloat()` / `parseInt()`
    - `last_updated` → `new Date()`

    There is no computed `status` field (active / idle / alert). Derive it from
    `event` (non-null → alert) and `last_updated` age (stale → offline).
    """
    repo = VehicleRepository(db)
    vehicle = await repo.get(vehicle_id, ctx)
    if not vehicle:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "Vehicle not found."}},
        )

    # Find the active device for this vehicle
    from models import Device
    from sqlalchemy import select
    device_result = await db.execute(
        select(Device)
        .where(Device.vehicle_id == vehicle_id, Device.is_active == True)
        .order_by(Device.created_at.desc())
        .limit(1)
    )
    device = device_result.scalar_one_or_none()
    if not device:
        return VehicleStateRead()

    state = await redis_client.hgetall(f"vehicle:state:{device.mac_address}")
    if not state:
        return VehicleStateRead()

    # Normalize lon→lng (pipeline stores lon, schema uses lng)
    if "lon" in state and "lng" not in state:
        state["lng"] = state.pop("lon")
    return VehicleStateRead(**{k: v for k, v in state.items() if k in VehicleStateRead.model_fields})


@router.get("/{vehicle_id}/telemetry/history", response_model=Page[TelemetryPointRead], responses={**_VEHICLE_ERRORS})
async def get_vehicle_telemetry_history(
    vehicle_id: uuid.UUID,
    from_dt: Optional[datetime] = None,
    to_dt: Optional[datetime] = None,
    page: int = 1,
    page_size: int = 100,
    ctx: RequestContext = Depends(require_permission(Permission.TELEMETRY_READ)),
    db: AsyncSession = Depends(get_db),
):
    """
    Return historical telemetry points for a vehicle, ordered by timestamp ascending.

    Query params:
    - `from_dt`: start of time range (ISO 8601, inclusive)
    - `to_dt`: end of time range (ISO 8601, inclusive)
    - `page` / `page_size`: pagination (max page_size=500)

    Source: PostgreSQL telemetry_raw table (partitioned by event_timestamp).
    Each point contains GPS coords plus key telemetry fields.
    """
    page_size = min(max(page_size, 1), 500)
    repo = VehicleRepository(db)
    vehicle = await repo.get(vehicle_id, ctx)
    if not vehicle:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "Vehicle not found."}},
        )
    trip_repo = TripRepository(db)
    points, total = await trip_repo.get_telemetry_by_vehicle(vehicle_id, from_dt, to_dt, page, page_size)
    return Page.of([TelemetryPointRead.model_validate(p) for p in points], total, page, page_size)


@router.patch("/{vehicle_id}", response_model=VehicleRead)
async def update_vehicle(
    vehicle_id: uuid.UUID,
    body: VehicleUpdate,
    ctx: RequestContext = Depends(require_permission(Permission.VEHICLE_WRITE)),
    db: AsyncSession = Depends(get_db),
):
    """Partial update — only fields included in the request body are modified."""
    repo = VehicleRepository(db)
    vehicle = await repo.get(vehicle_id, ctx)
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    updates = {k: v for k, v in body.model_dump(exclude_unset=True).items() if v is not None}
    if "metadata" in updates:
        updates["metadata_"] = updates.pop("metadata")
    vehicle = await repo.update(vehicle, updates)
    return VehicleRead.model_validate(vehicle)
