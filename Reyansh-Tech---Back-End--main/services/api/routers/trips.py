import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext
from auth.rbac import Permission, require_permission
from database import get_db
from repositories.trip import TripRepository
from schemas.common import ErrorResponse, Page
from schemas.trip import TelemetryPointRead, TripRead

router = APIRouter(prefix="/trips", tags=["trips"])

_COMMON_ERRORS = {
    401: {"model": ErrorResponse, "description": "Missing or invalid JWT"},
    403: {"model": ErrorResponse, "description": "Insufficient permissions"},
}
_NOT_FOUND = {404: {"model": ErrorResponse, "description": "Trip not found"}}


@router.get("", response_model=Page[TripRead], responses={**_COMMON_ERRORS})
async def list_trips(
    vehicle_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    from_dt: Optional[datetime] = None,
    to_dt: Optional[datetime] = None,
    page: int = 1,
    page_size: int = 20,
    ctx: RequestContext = Depends(require_permission(Permission.TRIP_READ)),
    db: AsyncSession = Depends(get_db),
):
    """
    List trips with RBAC filtering applied at the query layer.

    - PLATFORM: all trips.
    - POLICE: trips for USER_VEHICLEs + own EMERGENCY_VEHICLEs.
    - All others: trips for vehicles in their own org.

    Filter by `vehicle_id`, `status` (ACTIVE | COMPLETED | CANCELLED),
    `from_dt` and `to_dt` (ISO 8601 datetimes, matched against trip start_time).

    **FE integration note:**

    `status` values are UPPERCASE enums. Map for display:
    - `ACTIVE`    → "Ongoing"
    - `COMPLETED` → "Completed"
    - `CANCELLED` → "Cancelled"

    `score`, `harshEvents`, and `violations` from the FE mock are not in this response —
    those are computed analytics fields and are not yet implemented in the API.
    """
    page_size = min(max(page_size, 1), 100)
    repo = TripRepository(db)
    trips, total = await repo.list(ctx, vehicle_id, status, from_dt, to_dt, page, page_size)
    return Page.of([TripRead.model_validate(t) for t in trips], total, page, page_size)


@router.get("/{trip_id}", response_model=TripRead, responses={**_COMMON_ERRORS, **_NOT_FOUND})
async def get_trip(
    trip_id: uuid.UUID,
    ctx: RequestContext = Depends(require_permission(Permission.TRIP_READ)),
    db: AsyncSession = Depends(get_db),
):
    """Get a single trip by UUID. Returns 404 if not found or not accessible."""
    repo = TripRepository(db)
    trip = await repo.get(trip_id, ctx)
    if not trip:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "Trip not found."}},
        )
    return TripRead.model_validate(trip)


@router.get("/{trip_id}/telemetry", response_model=Page[TelemetryPointRead], responses={**_COMMON_ERRORS, **_NOT_FOUND})
async def get_trip_telemetry(
    trip_id: uuid.UUID,
    page: int = 1,
    page_size: int = 500,
    ctx: RequestContext = Depends(require_permission(Permission.TELEMETRY_READ)),
    db: AsyncSession = Depends(get_db),
):
    """
    Return the raw telemetry points recorded during a trip, ordered by timestamp ascending.

    Useful for route replay on the map — each point contains GPS coordinates and
    key telemetry fields (speed, RPM, temperature, battery, passenger count).

    `page_size` supports up to 500 to allow loading a full short trip in one call.
    """
    page_size = min(max(page_size, 1), 500)
    repo = TripRepository(db)
    trip = await repo.get(trip_id, ctx)
    if not trip:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "RESOURCE_NOT_FOUND", "message": "Trip not found."}},
        )
    points, total = await repo.get_trip_telemetry(trip, page, page_size)
    return Page.of([TelemetryPointRead.model_validate(p) for p in points], total, page, page_size)
