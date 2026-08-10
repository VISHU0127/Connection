"""
RBAC access matrix for the vehicle monitoring platform.

Every endpoint declares which Permission it requires; the require_permission
dependency enforces it against the caller's (org_type, role) combination.
"""
from enum import Enum
from functools import wraps
from typing import Callable

from fastapi import Depends, HTTPException

from .dependencies import RequestContext, get_current_user


class Permission(str, Enum):
    # Organizations
    ORG_READ = "ORG_READ"
    ORG_WRITE = "ORG_WRITE"
    ORG_DELETE = "ORG_DELETE"

    # Users
    USER_READ = "USER_READ"
    USER_WRITE = "USER_WRITE"

    # Vehicles
    VEHICLE_READ = "VEHICLE_READ"
    VEHICLE_WRITE = "VEHICLE_WRITE"
    VEHICLE_DELETE = "VEHICLE_DELETE"

    # Devices
    DEVICE_READ = "DEVICE_READ"
    DEVICE_WRITE = "DEVICE_WRITE"
    DEVICE_STATUS_WRITE = "DEVICE_STATUS_WRITE"

    # Trips
    TRIP_READ = "TRIP_READ"

    # Incidents
    INCIDENT_READ = "INCIDENT_READ"
    INCIDENT_STATUS_WRITE = "INCIDENT_STATUS_WRITE"
    INCIDENT_ACCESS_WRITE = "INCIDENT_ACCESS_WRITE"

    # Telemetry
    TELEMETRY_READ = "TELEMETRY_READ"

    # Dispatch
    DISPATCH = "DISPATCH"

    # Internal
    DEVICE_AUTH = "DEVICE_AUTH"

    # Platform admin — EMQX sync and other operator-only actions
    PLATFORM_ADMIN = "PLATFORM_ADMIN"

    # Customer-specific — own profile and own vehicle data
    CUSTOMER_READ = "CUSTOMER_READ"
    CUSTOMER_WRITE = "CUSTOMER_WRITE"


# (org_type, role) → set of permissions
_MATRIX: dict[tuple[str, str], set[Permission]] = {
    # --- PLATFORM ---
    ("PLATFORM", "super_admin"): {
        Permission.ORG_READ, Permission.ORG_WRITE, Permission.ORG_DELETE,
        Permission.USER_READ, Permission.USER_WRITE,
        Permission.VEHICLE_READ, Permission.VEHICLE_WRITE, Permission.VEHICLE_DELETE,
        Permission.DEVICE_READ, Permission.DEVICE_WRITE, Permission.DEVICE_STATUS_WRITE,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ, Permission.INCIDENT_STATUS_WRITE, Permission.INCIDENT_ACCESS_WRITE,
        Permission.TELEMETRY_READ,
        Permission.PLATFORM_ADMIN,
    },
    ("PLATFORM", "support_user"): {
        Permission.ORG_READ,
        Permission.USER_READ,
        Permission.VEHICLE_READ,
        Permission.DEVICE_READ, Permission.DEVICE_STATUS_WRITE,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ,
        Permission.TELEMETRY_READ,
    },
    ("PLATFORM", "data_analyst"): {
        Permission.ORG_READ,
        Permission.USER_READ,
        Permission.VEHICLE_READ,
        Permission.DEVICE_READ,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ,
        Permission.TELEMETRY_READ,
    },
    # --- POLICE ---
    ("POLICE", "org_admin"): {
        Permission.ORG_READ,
        Permission.USER_READ, Permission.USER_WRITE,
        Permission.VEHICLE_READ, Permission.VEHICLE_WRITE, Permission.VEHICLE_DELETE,
        Permission.DEVICE_READ, Permission.DEVICE_WRITE,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ, Permission.INCIDENT_STATUS_WRITE,
        Permission.TELEMETRY_READ,
        Permission.DISPATCH,
    },
    ("POLICE", "operator"): {
        Permission.ORG_READ,
        Permission.USER_READ,
        Permission.VEHICLE_READ, Permission.VEHICLE_WRITE,
        Permission.DEVICE_READ,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ, Permission.INCIDENT_STATUS_WRITE,
        Permission.TELEMETRY_READ,
        Permission.DISPATCH,
    },
    ("POLICE", "dispatcher"): {
        Permission.ORG_READ,
        Permission.VEHICLE_READ,
        Permission.INCIDENT_READ, Permission.INCIDENT_STATUS_WRITE,
        Permission.DISPATCH,
    },
    ("POLICE", "viewer"): {
        Permission.ORG_READ,
        Permission.VEHICLE_READ,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ,
    },
    # --- AMBULANCE ---
    ("AMBULANCE", "org_admin"): {
        Permission.ORG_READ,
        Permission.USER_READ, Permission.USER_WRITE,
        Permission.VEHICLE_READ, Permission.VEHICLE_WRITE, Permission.VEHICLE_DELETE,
        Permission.DEVICE_READ, Permission.DEVICE_WRITE,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ, Permission.INCIDENT_STATUS_WRITE,
        Permission.TELEMETRY_READ,
        Permission.DISPATCH,
    },
    ("AMBULANCE", "operator"): {
        Permission.ORG_READ,
        Permission.USER_READ,
        Permission.VEHICLE_READ, Permission.VEHICLE_WRITE,
        Permission.DEVICE_READ,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ, Permission.INCIDENT_STATUS_WRITE,
        Permission.TELEMETRY_READ,
        Permission.DISPATCH,
    },
    ("AMBULANCE", "dispatcher"): {
        Permission.ORG_READ,
        Permission.VEHICLE_READ,
        Permission.INCIDENT_READ,
        Permission.INCIDENT_STATUS_WRITE,
        Permission.DISPATCH,
    },
    ("AMBULANCE", "viewer"): {
        Permission.ORG_READ,
        Permission.VEHICLE_READ,
        Permission.INCIDENT_READ,
    },
    # --- CUSTOMER (private vehicle owners — self-registered via QR onboarding) ---
    # Each customer gets their own org (org_type=CUSTOMER) with a single owner user.
    # They can only see their own org's data — the default org filter handles this.
    ("CUSTOMER", "owner"): {
        Permission.VEHICLE_READ,
        Permission.TRIP_READ,
        Permission.INCIDENT_READ,
        Permission.TELEMETRY_READ,
        Permission.CUSTOMER_READ,
        Permission.CUSTOMER_WRITE,
    },

    # --- FIRE_DEPARTMENT (future — minimal permissions for now) ---
    ("FIRE_DEPARTMENT", "org_admin"): {
        Permission.ORG_READ,
        Permission.USER_READ, Permission.USER_WRITE,
        Permission.VEHICLE_READ, Permission.VEHICLE_WRITE,
        Permission.INCIDENT_READ, Permission.INCIDENT_STATUS_WRITE,
    },
    ("FIRE_DEPARTMENT", "operator"): {
        Permission.VEHICLE_READ,
        Permission.INCIDENT_READ, Permission.INCIDENT_STATUS_WRITE,
    },
    ("FIRE_DEPARTMENT", "viewer"): {
        Permission.VEHICLE_READ,
        Permission.INCIDENT_READ,
    },
}


def has_permission(org_type: str, role: str, permission: Permission) -> bool:
    key = (org_type, role)
    allowed = _MATRIX.get(key, set())
    return permission in allowed


def get_permissions_for(org_type: str, role: str) -> list[str]:
    """Return sorted list of permission strings for a given org_type + role combination."""
    key = (org_type, role)
    return sorted(p.value for p in _MATRIX.get(key, set()))


def require_permission(permission: Permission) -> Callable:
    """FastAPI dependency factory that enforces RBAC."""

    async def _check(ctx: RequestContext = Depends(get_current_user)) -> RequestContext:
        if not has_permission(ctx.org_type, ctx.role, permission):
            raise HTTPException(
                status_code=403,
                detail={
                    "error": {
                        "code": "FORBIDDEN",
                        "message": "You do not have permission to perform this action.",
                    }
                },
            )
        return ctx

    return _check
