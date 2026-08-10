import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class DeviceProvision(BaseModel):
    mac_address: str                        # burned into firmware; becomes EMQX username
    organization_id: uuid.UUID
    vehicle_id: Optional[uuid.UUID] = None
    firmware_version: Optional[str] = None
    metadata: dict = {}


class DeviceRead(BaseModel):
    id: uuid.UUID
    device_id: str
    mac_address: Optional[str]
    vehicle_id: Optional[uuid.UUID]
    organization_id: uuid.UUID
    is_active: bool
    firmware_version: Optional[str]
    last_seen_at: Optional[datetime]
    metadata: dict = Field(default={}, validation_alias='metadata_')
    created_at: datetime

    class Config:
        from_attributes = True


class DeviceProvisionResponse(DeviceRead):
    # EMQX credentials shown once at provisioning time.
    # Hardware team burns these into firmware; re-derivable from mac + vehicle_id + salt.
    emqx_username: str   # = mac_address
    emqx_password: str   # = sha256(mac:vehicle_id:salt)
