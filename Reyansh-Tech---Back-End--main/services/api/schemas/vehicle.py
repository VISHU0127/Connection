import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class VehicleCreate(BaseModel):
    # Optional — defaults to the caller's org if not provided
    organization_id: Optional[uuid.UUID] = None
    vehicle_category: str  # USER_VEHICLE or EMERGENCY_VEHICLE
    vin: Optional[str] = None
    registration_number: Optional[str] = None
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    vehicle_type: Optional[str] = None
    metadata: dict = {}


class VehicleUpdate(BaseModel):
    registration_number: Optional[str] = None
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    vehicle_type: Optional[str] = None
    is_active: Optional[bool] = None
    metadata: Optional[dict] = None


class VehicleRead(BaseModel):
    id: uuid.UUID
    organization_id: uuid.UUID
    vehicle_category: str
    vin: Optional[str]
    registration_number: Optional[str]
    make: Optional[str]
    model: Optional[str]
    year: Optional[int]
    vehicle_type: Optional[str]
    is_active: bool
    metadata: dict = Field(default={}, validation_alias='metadata_')
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
