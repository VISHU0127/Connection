import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class OrganizationCreate(BaseModel):
    name: str
    org_type: str  # PLATFORM, POLICE, AMBULANCE, FIRE_DEPARTMENT, CUSTOMER
    metadata: dict = {}


class OrganizationUpdate(BaseModel):
    name: Optional[str] = None
    is_active: Optional[bool] = None
    metadata: Optional[dict] = None


class OrganizationRead(BaseModel):
    id: uuid.UUID
    name: str
    slug: str
    org_type: str
    is_active: bool
    metadata: dict = Field(default={}, validation_alias='metadata_')
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
