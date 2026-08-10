import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class TripRead(BaseModel):
    id: uuid.UUID
    vehicle_id: uuid.UUID
    driver_id: Optional[uuid.UUID]
    start_time: datetime
    end_time: Optional[datetime]
    start_location: Optional[dict]
    end_location: Optional[dict]
    distance_meters: Optional[int]
    duration_seconds: Optional[int]
    status: str
    summary: dict
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TelemetryPointRead(BaseModel):
    device_id: str
    event_timestamp: datetime
    lat: Optional[float]
    lng: Optional[float]
    speed: Optional[float]
    rpm: Optional[int]
    temperature: Optional[float]
    battery: Optional[float]
    passenger_count: Optional[int]

    class Config:
        from_attributes = True


class VehicleStateRead(BaseModel):
    device_id: Optional[str] = None
    vehicle_id: Optional[str] = None
    lat: Optional[str] = None
    lng: Optional[str] = None
    gps_speed: Optional[str] = None
    obd_speed: Optional[str] = None
    hdop: Optional[str] = None
    rpm: Optional[str] = None
    coolant_c: Optional[str] = None
    cabin_temp: Optional[str] = None
    engine_temp: Optional[str] = None
    car_battery_v: Optional[str] = None
    signal_csq: Optional[str] = None
    person_count: Optional[str] = None
    event: Optional[str] = None
    last_updated: Optional[str] = None
    vehicle_category: Optional[str] = None
