import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class IncidentCreate(BaseModel):
    incident_type: str
    severity: str
    event_time: datetime
    location: dict
    metadata: dict = {}


class IncidentStatusUpdate(BaseModel):
    status: str  # OPEN, ACKNOWLEDGED, RESPONDING, RESOLVED, CLOSED, FALSE_POSITIVE


class IncidentRead(BaseModel):
    id: uuid.UUID
    incident_type: str
    severity: str
    status: str
    event_time: datetime
    location: dict
    created_by_org_id: uuid.UUID
    created_by_user_id: Optional[uuid.UUID]
    trip_id: Optional[uuid.UUID]
    metadata: dict = Field(default={}, validation_alias='metadata_')
    resolved_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
