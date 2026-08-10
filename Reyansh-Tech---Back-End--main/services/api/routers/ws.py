"""
WebSocket Gateway

Clients connect with a valid JWT in query param `token`.
After accepting, they are placed in their org's room and receive:
  - vehicle_state_updates: server-filtered live position pushes per RBAC rules
  - incident_notifications: incident alerts for orgs with explicit access grants

Server-side RBAC filtering rules for vehicle_state_updates:
  PLATFORM           → receives all vehicles
  POLICE             → receives USER_VEHICLEs + own EMERGENCY_VEHICLEs
  AMBULANCE/         → receives only own EMERGENCY_VEHICLEs
  FIRE_DEPARTMENT      (USER_VEHICLEs linked to incidents arrive via incident_notifications)
  CUSTOMER           → receives only own org's vehicles

RBAC filtering rules for incident_notifications:
  PLATFORM           → receives all incidents
  all others         → receives only incidents where the org is in granted_org_ids

Each message published to vehicle_state_updates must include `vehicle_category`
and `owner_org_id` (written by state-updater from device_meta Redis cache).

Connection note: the access token is passed as the `token` query parameter because
browsers cannot set Authorization headers on WebSocket connections. The token is
validated and checked against the Redis denylist on connect. A 20-second keepalive
ping from the client prevents the server's 30-second receive-timeout from closing
idle connections.
"""
import asyncio
import json
import logging
from typing import Optional

import redis.asyncio as aioredis
from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from jose import JWTError

from auth.jwt import decode_access_token
from config import settings
from redis_client import get_pool, make_dedicated_redis

router = APIRouter(prefix="/ws", tags=["websocket"])
logger = logging.getLogger("api.ws")

# Registry: org_id → {websocket: org_type}
_connections: dict[str, dict[WebSocket, str]] = {}


def _should_receive_vehicle_update(
    org_type: str,
    org_id: str,
    vehicle_category: str,
    owner_org_id: str,
) -> bool:
    """Server-side RBAC check — called for each (connection, message) pair."""
    if org_type == "PLATFORM":
        return True
    if org_type == "POLICE":
        return vehicle_category == "USER_VEHICLE" or owner_org_id == org_id
    if org_type in ("AMBULANCE", "FIRE_DEPARTMENT"):
        return owner_org_id == org_id
    # CUSTOMER and any other org type — own vehicles only
    return owner_org_id == org_id


async def _send_safe(ws: WebSocket, message: str) -> bool:
    try:
        await asyncio.wait_for(ws.send_text(message), timeout=2.0)
        return True
    except Exception:
        return False


async def _pubsub_relay() -> None:
    """
    Background task: relays Redis Pub/Sub messages to connected WS clients.
    Uses a dedicated Redis connection (not the shared pool) so the long-lived
    subscription never starves request handlers of connections.
    Includes reconnect loop — a Redis disconnect restarts automatically.
    """
    while True:
        redis_client = make_dedicated_redis()
        try:
            pubsub = redis_client.pubsub()
            await pubsub.subscribe("vehicle_state_updates", "incident_notifications")
            logger.info("ws_pubsub_relay_started")

            async for message in pubsub.listen():
                if message["type"] != "message":
                    continue

                try:
                    channel = message["channel"]
                    data = json.loads(message["data"])
                except (json.JSONDecodeError, KeyError):
                    continue

                if channel == "vehicle_state_updates":
                    vehicle_category: str = data.get("vehicle_category", "USER_VEHICLE")
                    owner_org_id: str = data.get("owner_org_id", "")

                    if not owner_org_id:
                        for ws, org_type in list(_get_all_connections_with_type()):
                            if org_type == "PLATFORM":
                                await _send_safe(ws, json.dumps({"type": "vehicle_state", "data": data}))
                        continue

                    msg_str = json.dumps({"type": "vehicle_state", "data": data})
                    for org_id, ws_map in list(_connections.items()):
                        for ws, org_type in list(ws_map.items()):
                            if _should_receive_vehicle_update(org_type, org_id, vehicle_category, owner_org_id):
                                await _send_safe(ws, msg_str)

                elif channel == "incident_notifications":
                    granted_org_ids: list[str] = data.get("granted_org_ids", [])
                    msg_str = json.dumps({"type": "incident", "data": data})
                    for org_id in granted_org_ids:
                        for ws in list(_connections.get(org_id, {}).keys()):
                            await _send_safe(ws, msg_str)
                    # Platform admins receive all incidents regardless of granted_org_ids
                    for ws, org_type in list(_get_all_connections_with_type()):
                        if org_type == "PLATFORM":
                            await _send_safe(ws, msg_str)

        except Exception as exc:
            logger.error("ws_pubsub_relay_error", extra={"error": str(exc)})
            await asyncio.sleep(2)
        finally:
            await redis_client.aclose()


def _get_all_connections_with_type():
    for ws_map in _connections.values():
        yield from ws_map.items()


@router.websocket("/connect")
async def websocket_endpoint(
    ws: WebSocket,
    token: Optional[str] = Query(default=None),
) -> None:
    if not token:
        await ws.close(code=4001, reason="Missing token")
        return

    try:
        payload = decode_access_token(token)
    except JWTError:
        await ws.close(code=4001, reason="Invalid token")
        return

    # Check JWT denylist — token may have been revoked via logout
    jti = payload.get("jti")
    if jti:
        redis_client = aioredis.Redis(connection_pool=get_pool())
        if await redis_client.exists(f"token_denylist:{jti}"):
            await ws.close(code=4001, reason="Token revoked")
            return

    org_id: str = payload["org_id"]
    org_type: str = payload.get("org_type", "")
    await ws.accept()

    if org_id not in _connections:
        _connections[org_id] = {}
    _connections[org_id][ws] = org_type
    logger.info("ws_client_connected", extra={
        "org_id": org_id,
        "org_type": org_type,
        "user_id": payload["sub"],
    })

    try:
        while True:
            await asyncio.wait_for(ws.receive_text(), timeout=30.0)
    except (WebSocketDisconnect, asyncio.TimeoutError):
        pass
    finally:
        _connections.get(org_id, {}).pop(ws, None)
        if not _connections.get(org_id):
            _connections.pop(org_id, None)
        logger.info("ws_client_disconnected", extra={"org_id": org_id})
