import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext
from auth.rbac import Permission, require_permission
from database import get_db
from repositories.incident import IncidentRepository
from schemas.common import Page
from schemas.incident import IncidentCreate, IncidentRead, IncidentStatusUpdate

router = APIRouter(prefix="/incidents", tags=["incidents"])


@router.get("", response_model=Page[IncidentRead])
async def list_incidents(
    status: Optional[str] = None,
    incident_type: Optional[str] = None,
    page: int = 1,
    page_size: int = 50,
    ctx: RequestContext = Depends(require_permission(Permission.INCIDENT_READ)),
    db: AsyncSession = Depends(get_db),
):
    """
    List incidents with RBAC filtering applied at the query layer.

    Incidents are created automatically by the kafka-incident-detection and
    kafka-incident-routing workers — there is no POST endpoint.

    Filter by `status`: OPEN · ACKNOWLEDGED · RESPONDING · RESOLVED · CLOSED · FALSE_POSITIVE
    Filter by `incident_type`: ACCIDENT · OVERSPEEDING · MEDICAL · FIRE · TEMPERATURE_ANOMALY · PASSENGER_ANOMALY

    **FE integration notes:**

    `severity` is returned UPPERCASE (`CRITICAL`, `HIGH`, `MEDIUM`, `LOW`). Call `.toLowerCase()`
    before rendering badge colours or comparing against display constants.

    `status` values differ from the FE mock. Mapping for display:
    - `OPEN` → "pending"
    - `ACKNOWLEDGED` → "acknowledged"
    - `RESPONDING` → "dispatched" / "on_route" / "on_scene" (no sub-states in API)
    - `RESOLVED` / `CLOSED` → "completed"
    - `CANCELLED` / `FALSE_POSITIVE` → handle as terminal states

    `incident_type` is UPPERCASE enum (e.g. `HARSH_BRAKE`, `GEOFENCE_BREACH`). Map to
    display labels client-side.
    """
    page_size = min(max(page_size, 1), 100)
    repo = IncidentRepository(db)
    incidents, total = await repo.list(ctx, status, incident_type, page, page_size)
    return Page.of([IncidentRead.model_validate(i) for i in incidents], total, page, page_size)


@router.get("/{incident_id}", response_model=IncidentRead)
async def get_incident(
    incident_id: uuid.UUID,
    ctx: RequestContext = Depends(require_permission(Permission.INCIDENT_READ)),
    db: AsyncSession = Depends(get_db),
):
    repo = IncidentRepository(db)
    incident = await repo.get(incident_id, ctx)
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    return IncidentRead.model_validate(incident)


@router.patch("/{incident_id}/status", response_model=IncidentRead)
async def update_incident_status(
    incident_id: uuid.UUID,
    body: IncidentStatusUpdate,
    ctx: RequestContext = Depends(require_permission(Permission.INCIDENT_STATUS_WRITE)),
    db: AsyncSession = Depends(get_db),
):
    """Update the status of an incident. Valid transitions depend on the caller's workflow."""
    repo = IncidentRepository(db)
    incident = await repo.get(incident_id, ctx)
    if not incident:
        raise HTTPException(status_code=404, detail="Incident not found")
    incident = await repo.update_status(incident, body.status)
    return IncidentRead.model_validate(incident)
