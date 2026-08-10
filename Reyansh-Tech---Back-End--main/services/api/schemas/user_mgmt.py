import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr


class UserCreateAdmin(BaseModel):
    organization_id: Optional[uuid.UUID] = None  # defaults to caller's org if omitted
    email: EmailStr
    username: str
    password: str
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone_number: Optional[str] = None
    role: str
    must_change_password: bool = True


class UserUpdateAdmin(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone_number: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    must_change_password: Optional[bool] = None
    password: Optional[str] = None  # admin password reset


class UserReadAdmin(BaseModel):
    id: uuid.UUID
    organization_id: uuid.UUID
    org_name: Optional[str] = None
    org_type: Optional[str] = None
    username: str
    email: str
    role: str
    first_name: Optional[str]
    last_name: Optional[str]
    phone_number: Optional[str]
    is_active: bool
    must_change_password: bool
    last_login_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    permissions: list[str] = []

    class Config:
        from_attributes = True
