import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, field_validator


class OnboardRequest(BaseModel):
    # Customer personal details
    first_name: str
    last_name: str
    email: EmailStr
    password: str
    phone: Optional[str] = None

    # Vehicle details
    registration_number: str
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    vehicle_type: Optional[str] = None
    vin: Optional[str] = None

    # Device MAC address — encoded in the QR code on the hardware device
    mac_address: str

    @field_validator("password")
    @classmethod
    def _password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v

class OnboardResponse(BaseModel):
    # JWT for the newly created customer — use immediately in mobile app
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

    # Created entity IDs
    org_id: uuid.UUID
    user_id: uuid.UUID
    vehicle_id: uuid.UUID
    device_id: str

    # EMQX device credentials — shown ONCE, never retrievable again
    # Hardware team burns these into firmware (or app stores them securely)
    emqx_username: str
    emqx_password: str


class AddVehicleRequest(BaseModel):
    """For existing customers adding a second vehicle via QR scan."""
    registration_number: str
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    vehicle_type: Optional[str] = None
    vin: Optional[str] = None
    mac_address: str


class AddVehicleResponse(BaseModel):
    vehicle_id: uuid.UUID
    device_id: str
    emqx_username: str
    emqx_password: str
