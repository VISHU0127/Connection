"""
Simulator router — device simulation UI and MQTT publishing endpoints.

Endpoints:
  GET  /simulator                    — serves simulator.html (no auth)
  POST /simulator/simulate           — starts a background simulation scenario
  GET  /simulator/stream/{session_id} — SSE stream of simulation progress
"""
import asyncio
import json
import logging
import pathlib
import time
import uuid
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse, StreamingResponse
from pydantic import BaseModel
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import RequestContext, get_current_user
from auth.rbac import Permission, require_permission
from config import settings
from database import get_db
from emqx_client import derive_device_password
from models.device import Device
from models.vehicle import Vehicle
import redis.asyncio as aioredis
from redis_client import get_redis, make_dedicated_redis

logger = logging.getLogger("api.simulator")

router = APIRouter(prefix="/simulator", tags=["simulator"])

# ---------------------------------------------------------------------------
# Session store — maps session_id -> asyncio.Queue
# Capped at MAX_SESSIONS to avoid unbounded memory growth.
# ---------------------------------------------------------------------------
MAX_SESSIONS = 100
_sessions: dict[str, asyncio.Queue] = {}

# ---------------------------------------------------------------------------
# Schemas
# ---------------------------------------------------------------------------

class SimulateRequest(BaseModel):
    action: str                  # drive | harsh_brake | accident | overheat | panic | sos
    mac_address: str
    emqx_password: str
    lat: float = 28.6139         # default: New Delhi
    lon: float = 77.2090


class SimulateResponse(BaseModel):
    session_id: str


class VehicleLookupRequest(BaseModel):
    device_id: Optional[str] = None
    registration_number: Optional[str] = None


class VehicleLookupResponse(BaseModel):
    device_id: str
    mac_address: Optional[str]
    vehicle_id: str
    registration_number: Optional[str]
    make: Optional[str]
    model: Optional[str]
    year: Optional[int]
    vehicle_type: Optional[str]
    emqx_username: str
    emqx_password: str


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_frame(
    mac_address: str,
    lat: float,
    lon: float,
    gps_speed: float = 0.0,
    obd_speed: float = 0.0,
    rpm: int = 0,
    coolant_c: float = 90.0,
    engine_temp: float = 85.0,
    car_battery_v: float = 12.4,
    signal_csq: int = 18,
    person_count: int = 1,
    event: Optional[str] = None,
) -> dict:
    payload: dict = {
        "device_id": mac_address,
        "timestamp_epoch": int(time.time()),
        "lat": lat,
        "lon": lon,
        "gps_speed": gps_speed,
        "obd_speed": obd_speed,
        "rpm": rpm,
        "coolant_c": coolant_c,
        "engine_temp": engine_temp,
        "car_battery_v": car_battery_v,
        "signal_csq": signal_csq,
        "person_count": person_count,
    }
    if event is not None:
        payload["event"] = event
    else:
        payload["event"] = None
    return payload


def _publish_sync(
    broker: str,
    port: int,
    username: str,
    password: str,
    topic: str,
    payload: dict,
) -> None:
    """Synchronous MQTT publish — called via run_in_executor to avoid blocking the event loop."""
    import paho.mqtt.client as mqtt  # type: ignore[import]

    client = mqtt.Client(client_id=username, protocol=mqtt.MQTTv311)
    client.username_pw_set(username, password)

    connected = threading_event = None
    import threading
    connected_event = threading.Event()
    connect_rc: list[int] = []

    def on_connect(c, userdata, flags, rc):
        connect_rc.append(rc)
        connected_event.set()

    client.on_connect = on_connect
    client.connect(broker, port, keepalive=10)
    client.loop_start()

    if not connected_event.wait(timeout=8):
        client.loop_stop()
        raise TimeoutError(f"MQTT connect timeout to {broker}:{port}")

    if connect_rc[0] != 0:
        client.loop_stop()
        raise ConnectionError(f"MQTT connect refused, rc={connect_rc[0]}")

    result = client.publish(topic, json.dumps(payload), qos=1, retain=True)
    result.wait_for_publish(timeout=5)

    client.disconnect()
    client.loop_stop()


async def _publish(
    username: str,
    password: str,
    topic: str,
    payload: dict,
) -> None:
    """Async wrapper around _publish_sync using the default executor."""
    if not settings.mqtt_broker:
        return
    # Always stamp timestamp_epoch at publish time so frames built upfront don't
    # share the same epoch and get dropped by the dedup check in telemetry-processor.
    payload = dict(payload)
    payload["timestamp_epoch"] = int(time.time())
    loop = asyncio.get_event_loop()
    await loop.run_in_executor(
        None,
        _publish_sync,
        settings.mqtt_broker,
        settings.mqtt_port,
        username,
        password,
        topic,
        payload,
    )


def _telemetry_topic(mac: str) -> str:
    return f"vehicle/{mac}/telemetry"


def _event_topic(mac: str) -> str:
    return f"vehicle/{mac}/event"


async def _log(q: asyncio.Queue, msg_type: str, msg: str) -> None:
    ts = time.strftime("%H:%M:%S", time.gmtime())
    await q.put({"ts": ts, "type": msg_type, "msg": msg})


# ---------------------------------------------------------------------------
# Scenario implementations
# ---------------------------------------------------------------------------

async def _scenario_drive(
    mac: str,
    password: str,
    lat: float,
    lon: float,
    q: asyncio.Queue,
) -> None:
    frames = [
        # (gps_speed, obd_speed, rpm, lat_offset, lon_offset)
        (0.0,  0.0,  800,  0.0,     0.0),
        (20.0, 20.0, 1500, 0.0001,  0.0001),
        (35.0, 35.0, 2000, 0.0002,  0.0002),
        (50.0, 50.0, 2100, 0.0003,  0.0003),
        (50.0, 50.0, 2100, 0.0008,  0.0008),
        (50.0, 50.0, 2100, 0.0013,  0.0013),
        (50.0, 50.0, 2100, 0.0018,  0.0018),
        (30.0, 30.0, 1600, 0.0021,  0.0021),
        (10.0, 10.0, 1000, 0.0023,  0.0023),
        (0.0,  0.0,    0,  0.0025,  0.0025),
    ]

    for i, (gps_speed, obd_speed, rpm, dlat, dlon) in enumerate(frames, start=1):
        frame_lat = round(lat + dlat, 6)
        frame_lon = round(lon + dlon, 6)

        # Frame 10 has engine off — no event field at all; other frames include event=null
        if i == 10:
            payload = _make_frame(
                mac_address=mac,
                lat=frame_lat,
                lon=frame_lon,
                gps_speed=gps_speed,
                obd_speed=obd_speed,
                rpm=rpm,
            )
            # Remove event key entirely for engine-off frame
            payload.pop("event", None)
        else:
            payload = _make_frame(
                mac_address=mac,
                lat=frame_lat,
                lon=frame_lon,
                gps_speed=gps_speed,
                obd_speed=obd_speed,
                rpm=rpm,
            )

        try:
            await _publish(mac, password, _telemetry_topic(mac), payload)
            await _log(q, "info", f"Frame {i}/10 — lat={frame_lat}, lon={frame_lon}, speed={gps_speed} km/h, rpm={rpm}")
        except Exception as exc:
            await _log(q, "error", f"Frame {i} publish failed: {exc}")
            return

        if i < len(frames):
            await asyncio.sleep(3)

    await _log(q, "success", "Drive complete — check vehicle state and trips in the dashboard")


async def _scenario_harsh_brake(
    mac: str,
    password: str,
    lat: float,
    lon: float,
    q: asyncio.Queue,
) -> None:
    frames = [
        _make_frame(mac, lat, lon, gps_speed=80.0, obd_speed=80.0, rpm=3000),
        _make_frame(mac, lat, lon, gps_speed=18.0, obd_speed=18.0, rpm=1200, event="HARSH_BRAKE"),
    ]
    for i, payload in enumerate(frames, start=1):
        try:
            await _publish(mac, password, _telemetry_topic(mac), payload)
        except Exception as exc:
            await _log(q, "error", f"Frame {i} publish failed: {exc}")
            return
        if i < len(frames):
            await asyncio.sleep(1)

    await _log(q, "success", "Harsh braking event published — expect HARSH_BRAKE incident within ~2s")


async def _scenario_accident(
    mac: str,
    password: str,
    lat: float,
    lon: float,
    q: asyncio.Queue,
) -> None:
    frames = [
        _make_frame(mac, lat, lon, gps_speed=65.0, obd_speed=65.0, rpm=2500),
        _make_frame(mac, lat, lon, gps_speed=0.0,  obd_speed=0.0,  rpm=0, event="ACCIDENT"),
    ]
    for i, payload in enumerate(frames, start=1):
        topic = _event_topic(mac) if payload.get("event") else _telemetry_topic(mac)
        try:
            await _publish(mac, password, topic, payload)
        except Exception as exc:
            await _log(q, "error", f"Frame {i} publish failed: {exc}")
            return
        if i < len(frames):
            await asyncio.sleep(1)

    await _log(q, "success", "Accident event published — expect CRITICAL incident within ~2s")


async def _scenario_overheat(
    mac: str,
    password: str,
    lat: float,
    lon: float,
    q: asyncio.Queue,
) -> None:
    payload = _make_frame(
        mac,
        lat,
        lon,
        gps_speed=30.0,
        obd_speed=30.0,
        rpm=1800,
        coolant_c=115.0,
        engine_temp=108.0,
    )
    try:
        await _publish(mac, password, _telemetry_topic(mac), payload)
    except Exception as exc:
        await _log(q, "error", f"Overheat frame publish failed: {exc}")
        return

    await _log(q, "success", "Overheat event published — expect TEMPERATURE_ANOMALY incident within ~2s")


async def _scenario_panic(
    mac: str,
    password: str,
    lat: float,
    lon: float,
    q: asyncio.Queue,
) -> None:
    payload = _make_frame(mac, lat, lon, gps_speed=0.0, rpm=0, event="PANIC")
    try:
        await _publish(mac, password, _event_topic(mac), payload)
    except Exception as exc:
        await _log(q, "error", f"Panic frame publish failed: {exc}")
        return

    await _log(q, "success", "Panic button event published — expect HIGH incident within ~2s")


async def _scenario_sos(
    mac: str,
    password: str,
    lat: float,
    lon: float,
    q: asyncio.Queue,
) -> None:
    payload = _make_frame(mac, lat, lon, gps_speed=0.0, rpm=0, event="SOS")
    try:
        await _publish(mac, password, _event_topic(mac), payload)
    except Exception as exc:
        await _log(q, "error", f"SOS frame publish failed: {exc}")
        return

    await _log(q, "success", "SOS event published — expect incident within ~2s")


_SCENARIOS = {
    "drive":       _scenario_drive,
    "harsh_brake": _scenario_harsh_brake,
    "accident":    _scenario_accident,
    "overheat":    _scenario_overheat,
    "panic":       _scenario_panic,
    "sos":         _scenario_sos,
}


async def _redis_relay(session_id: str, q: asyncio.Queue) -> None:
    """Copies queue items to Redis pub/sub so SSE streams work across multiple workers."""
    redis_client = make_dedicated_redis()
    try:
        while True:
            item = await q.get()
            await redis_client.publish(f"sim:{session_id}", json.dumps(item))
            if item is None:  # sentinel
                break
    except Exception:
        logger.exception("redis_relay_error for session %s", session_id)
    finally:
        await redis_client.delete(f"sim_meta:{session_id}")  # prevent EventSource reconnects from reattaching
        await redis_client.aclose()
        _sessions.pop(session_id, None)


async def _run_scenario(
    session_id: str,
    action: str,
    mac: str,
    password: str,
    lat: float,
    lon: float,
) -> None:
    q = _sessions.get(session_id)
    if q is None:
        return

    fn = _SCENARIOS.get(action)
    if fn is None:
        await _log(q, "error", f"Unknown action: {action}")
    else:
        try:
            await fn(mac, password, lat, lon, q)
        except Exception as exc:
            logger.exception("Unhandled error in scenario %s", action)
            await _log(q, "error", f"Scenario error: {exc}")

    # Sentinel — signals the SSE stream to close
    await q.put(None)


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.get("", response_class=HTMLResponse, include_in_schema=False)
async def simulator_ui() -> HTMLResponse:
    """Serve the simulator HTML page."""
    html_path = pathlib.Path(__file__).parent.parent / "simulator.html"
    if not html_path.exists():
        raise HTTPException(status_code=404, detail="simulator.html not found")
    return HTMLResponse(content=html_path.read_text(encoding="utf-8"))


@router.post("/simulate", response_model=SimulateResponse, status_code=202)
async def simulate(
    body: SimulateRequest,
    _: RequestContext = Depends(require_permission(Permission.PLATFORM_ADMIN)),
) -> SimulateResponse:
    """
    Start a background simulation scenario. Returns a `session_id` to stream progress via
    `GET /simulator/stream/{session_id}`.

    Valid `action` values:
    - `normal_drive` — 10-frame normal drive, no incidents expected
    - `harsh_braking` — drive with harsh braking event → HARSH_BRAKE incident
    - `accident` — drive with collision event → CRITICAL incident
    - `overheat` — engine temperature spike → TEMPERATURE_ANOMALY incident
    - `panic_button` — panic button press → HIGH severity incident
    - `sos` — SOS event → incident

    The simulator publishes real MQTT frames server-side — the full pipeline runs end-to-end.
    Requires PLATFORM_ADMIN permission.
    """
    if body.action not in _SCENARIOS:
        raise HTTPException(
            status_code=422,
            detail={
                "error": {
                    "code": "INVALID_ACTION",
                    "message": f"Unknown action '{body.action}'. Valid actions: {', '.join(_SCENARIOS)}.",
                }
            },
        )

    # Evict oldest session if at capacity
    if len(_sessions) >= MAX_SESSIONS:
        oldest_key = next(iter(_sessions))
        del _sessions[oldest_key]

    session_id = uuid.uuid4().hex
    q: asyncio.Queue = asyncio.Queue()
    _sessions[session_id] = q

    # Register session in Redis so any worker can serve the SSE stream
    from redis_client import get_pool
    _pool_redis = aioredis.Redis(connection_pool=get_pool())
    await _pool_redis.set(f"sim_meta:{session_id}", "1", ex=120)

    asyncio.create_task(
        _run_scenario(
            session_id=session_id,
            action=body.action,
            mac=body.mac_address,
            password=body.emqx_password,
            lat=body.lat,
            lon=body.lon,
        )
    )
    asyncio.create_task(_redis_relay(session_id, q))

    return SimulateResponse(session_id=session_id)


@router.get("/stream/{session_id}", include_in_schema=False)
async def stream_session(session_id: str) -> StreamingResponse:
    """
    SSE stream for a running simulation session.
    Streams JSON-encoded event objects until the scenario finishes or 60s elapses.
    Each SSE event: data: {"ts": "HH:MM:SS", "type": "info|success|error", "msg": "..."}
    Uses Redis pub/sub so the stream works even when served by a different uvicorn worker
    than the one that started the simulation.
    """
    from redis_client import get_pool
    _pool_redis = aioredis.Redis(connection_pool=get_pool())
    # Accept the session if it is in this worker's local map OR registered in Redis
    if session_id not in _sessions and not await _pool_redis.exists(f"sim_meta:{session_id}"):
        raise HTTPException(status_code=404, detail="Session not found or already expired.")

    async def _event_generator():
        redis_client = make_dedicated_redis()
        pubsub = redis_client.pubsub()
        await pubsub.subscribe(f"sim:{session_id}")

        deadline = time.monotonic() + 60  # 60-second hard timeout

        try:
            while True:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    yield "data: " + json.dumps({"ts": time.strftime("%H:%M:%S", time.gmtime()), "type": "error", "msg": "Stream timeout (60s)"}) + "\n\n"
                    yield "event: done\ndata: {}\n\n"
                    await asyncio.sleep(0.1)
                    break

                try:
                    message = await asyncio.wait_for(
                        pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0),
                        timeout=2.0,
                    )
                except asyncio.TimeoutError:
                    yield ": keepalive\n\n"
                    continue

                if message is None:
                    yield ": keepalive\n\n"
                    continue

                item = json.loads(message["data"])

                if item is None:  # sentinel — scenario finished
                    yield "event: done\ndata: {}\n\n"
                    await asyncio.sleep(0.1)  # ensure chunk is flushed before connection tears down
                    break

                yield "data: " + json.dumps(item) + "\n\n"
        finally:
            await pubsub.unsubscribe(f"sim:{session_id}")
            await redis_client.aclose()

    return StreamingResponse(
        _event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
        },
    )


# ---------------------------------------------------------------------------
# Service health status
# ---------------------------------------------------------------------------

def _strip_credentials(url: str) -> str:
    """Remove username:password from a URL for safe display."""
    try:
        from urllib.parse import urlparse, urlunparse
        p = urlparse(url)
        safe = p._replace(netloc=p.hostname + (f":{p.port}" if p.port else ""))
        return urlunparse(safe)
    except Exception:
        return url


def _db_display() -> str:
    url = getattr(settings, "database_url", "")
    return _strip_credentials(url).replace("postgresql+asyncpg://", "postgresql://")


def _redis_display() -> str:
    url = getattr(settings, "redis_url", "")
    return _strip_credentials(url)


async def _check_http(url: str, timeout: float = 2.0) -> str:
    try:
        async with httpx.AsyncClient() as c:
            r = await c.get(url, timeout=timeout)
            return "ok" if r.status_code < 400 else "error"
    except Exception:
        return "error"


# Static metadata for each service: label, machine, systemd unit, connection info
_SERVICE_META = {
    "api": {
        "label": "API Gateway",
        "machine": "Machine 2 — App",
        "systemd": "vm-api",
        "endpoint": "http://localhost:8000",
        "note": "REST + WebSocket. Health: /healthz",
    },
    "database": {
        "label": "PostgreSQL",
        "machine": "Machine 1 — Storage",
        "systemd": "postgresql",
        "note": "Check pg_hba.conf allows app machine IP. Port 5432.",
    },
    "redis": {
        "label": "Redis",
        "machine": "Machine 1 — Storage",
        "systemd": "redis-server",
        "note": "Used for vehicle state, dedup keys, JWT denylist. Port 6379.",
    },
    "emqx": {
        "label": "EMQX Broker",
        "machine": "Machine 3 — EMQX",
        "systemd": "emqx",
        "note": "MQTT :1883  ·  Management API :18083",
    },
    "kafka": {
        "label": "Kafka",
        "machine": "Machine 3 — Kafka",
        "systemd": "kafka",
        "note": "KRaft single-broker. Port 9092. Inferred from telemetry-processor health.",
    },
    "mqtt-ingestion": {
        "label": "MQTT Ingestion",
        "machine": "Machine 2 — App",
        "systemd": "vm-ingestion",
        "endpoint": "http://localhost:8081/healthz",
        "note": "Subscribes to EMQX vehicle/+/+  →  Kafka telemetry.raw",
    },
    "kafka-state-updater": {
        "label": "State Updater",
        "machine": "Machine 2 — App",
        "systemd": "vm-state-updater",
        "endpoint": "http://localhost:8083/healthz",
        "note": "Kafka telemetry.processed  →  Redis vehicle:state:{id}  →  WS Pub/Sub",
    },
    "kafka-incident-detection": {
        "label": "Incident Detection",
        "machine": "Machine 2 — App",
        "systemd": "vm-incident-detection",
        "endpoint": "http://localhost:8082/healthz",
        "note": "Kafka telemetry.processed  →  rule engine  →  Kafka events.incident",
    },
    "kafka-telemetry-processor": {
        "label": "Telemetry Processor",
        "machine": "Machine 2 — App",
        "systemd": "vm-telemetry-processor",
        "endpoint": "http://localhost:8084/healthz",
        "note": "Kafka telemetry.raw  →  dedup  →  Postgres + S3  →  telemetry.processed",
    },
    "postgres-jobs": {
        "label": "Scheduler",
        "machine": "Machine 2 — App",
        "systemd": "vm-jobs",
        "endpoint": "http://localhost:8080/health",
        "note": "APScheduler: trip computation, telemetry pruning, incident maintenance",
    },
}


@router.get("/services", include_in_schema=False)
async def service_status(
    db: AsyncSession = Depends(get_db),
    redis_client: aioredis.Redis = Depends(get_redis),
    _: RequestContext = Depends(require_permission(Permission.PLATFORM_ADMIN)),
):
    """
    Returns health status + connection/troubleshoot info for every platform service.
    Called by the simulator UI every 10s.
    """
    statuses: dict[str, str] = {}

    # API — always ok if we're responding
    statuses["api"] = "ok"

    # DB
    try:
        await db.execute(text("SELECT 1"))
        statuses["database"] = "ok"
    except Exception:
        statuses["database"] = "error"

    # Redis
    try:
        await redis_client.ping()
        statuses["redis"] = "ok"
    except Exception:
        statuses["redis"] = "error"

    # EMQX
    if settings.emqx_api_url:
        statuses["emqx"] = await _check_http(f"{settings.emqx_api_url}/api/v5/status")
    else:
        statuses["emqx"] = "unconfigured"

    # Workers
    worker_checks = {
        "mqtt-ingestion":             "http://localhost:8081/healthz",
        "kafka-state-updater":        "http://localhost:8083/healthz",
        "kafka-incident-detection":   "http://localhost:8082/healthz",
        "kafka-telemetry-processor":  "http://localhost:8084/healthz",
        "postgres-jobs":              "http://localhost:8080/health",
    }
    checks = await asyncio.gather(
        *[_check_http(url) for url in worker_checks.values()],
        return_exceptions=True,
    )
    for name, result in zip(worker_checks.keys(), checks):
        statuses[name] = result if isinstance(result, str) else "error"

    # Kafka inferred from telemetry-processor
    statuses["kafka"] = statuses.get("kafka-telemetry-processor", "error")

    # Build enriched response
    response = {}
    for key, status in statuses.items():
        meta = _SERVICE_META.get(key, {})
        entry: dict = {"status": status, **meta}

        # Add live connection info when healthy
        if status == "ok":
            if key == "database":
                entry["endpoint"] = _db_display()
            elif key == "redis":
                entry["endpoint"] = _redis_display()
            elif key == "emqx":
                entry["endpoint"] = settings.emqx_api_url

        response[key] = entry

    return response


# ---------------------------------------------------------------------------
# DB counters
# ---------------------------------------------------------------------------

@router.get("/stats", include_in_schema=False)
async def platform_stats(
    db: AsyncSession = Depends(get_db),
    _: RequestContext = Depends(require_permission(Permission.PLATFORM_ADMIN)),
):
    """
    Returns live counts of key entities from the database.
    Polled every 5s by the simulator UI to show that data is flowing.
    """
    queries = {
        "organizations": "SELECT COUNT(*) FROM organizations WHERE org_type != 'PLATFORM'",
        "customers":     "SELECT COUNT(*) FROM organizations WHERE org_type = 'CUSTOMER'",
        "users":         "SELECT COUNT(*) FROM users",
        "vehicles":      "SELECT COUNT(*) FROM vehicles",
        "devices":       "SELECT COUNT(*) FROM devices",
        "incidents":     "SELECT COUNT(*) FROM incidents",
        "trips":         "SELECT COUNT(*) FROM trips",
    }
    stats = {}
    for key, sql in queries.items():
        try:
            result = await db.execute(text(sql))
            stats[key] = result.scalar() or 0
        except Exception:
            stats[key] = -1
    return stats


# ---------------------------------------------------------------------------
# Vehicle lookup (for simulating existing vehicles)
# ---------------------------------------------------------------------------

@router.post("/lookup-vehicle", response_model=VehicleLookupResponse)
async def lookup_vehicle(
    body: VehicleLookupRequest,
    db: AsyncSession = Depends(get_db),
    _: RequestContext = Depends(require_permission(Permission.PLATFORM_ADMIN)),
) -> VehicleLookupResponse:
    """
    Look up an existing vehicle by device_id or registration_number.
    Re-derives the EMQX password deterministically so admin can simulate it without
    knowing the customer's credentials.
    Requires PLATFORM_ADMIN permission.
    """
    if not body.device_id and not body.registration_number:
        raise HTTPException(
            status_code=422,
            detail={"error": {"code": "VALIDATION_ERROR", "message": "Provide device_id or registration_number."}},
        )

    device: Optional[Device] = None

    if body.device_id:
        result = await db.execute(
            select(Device).where(Device.device_id == body.device_id).limit(1)
        )
        device = result.scalar_one_or_none()

    if device is None and body.registration_number:
        result = await db.execute(
            select(Device)
            .join(Vehicle, Vehicle.id == Device.vehicle_id)
            .where(Vehicle.registration_number == body.registration_number)
            .limit(1)
        )
        device = result.scalar_one_or_none()

    if device is None:
        raise HTTPException(
            status_code=404,
            detail={"error": {"code": "NOT_FOUND", "message": "No device found matching the given identifier."}},
        )

    if not device.vehicle_id:
        raise HTTPException(
            status_code=409,
            detail={"error": {"code": "CONFLICT", "message": "Device exists but is not linked to a vehicle."}},
        )

    result = await db.execute(select(Vehicle).where(Vehicle.id == device.vehicle_id).limit(1))
    vehicle = result.scalar_one_or_none()
    if not vehicle:
        raise HTTPException(
            status_code=500,
            detail={"error": {"code": "INTERNAL_ERROR", "message": "Device points to a missing vehicle record."}},
        )

    emqx_username = device.mac_address or device.device_id
    emqx_password = derive_device_password(emqx_username, str(vehicle.id), settings.emqx_device_secret_salt)

    return VehicleLookupResponse(
        device_id=device.device_id,
        mac_address=device.mac_address,
        vehicle_id=str(vehicle.id),
        registration_number=vehicle.registration_number,
        make=vehicle.make,
        model=vehicle.model,
        year=vehicle.year,
        vehicle_type=vehicle.vehicle_type,
        emqx_username=emqx_username,
        emqx_password=emqx_password,
    )


# ---------------------------------------------------------------------------
# Unknown hardware events (events with no active detection rule)
# ---------------------------------------------------------------------------

@router.get("/unknown-events", include_in_schema=False)
async def unknown_events(
    _: RequestContext = Depends(require_permission(Permission.PLATFORM_ADMIN)),
):
    """
    Returns hardware event strings seen in telemetry that have no active
    detection rule.  Stored in Redis — never persisted to Postgres.
    """
    r = await get_redis()
    counts: dict = await r.hgetall("unknown_hw_events:counts")
    if not counts:
        return {"unknown_events": []}

    results = []
    for event_type, count_str in counts.items():
        meta: dict = await r.hgetall(f"unknown_hw_events:meta:{event_type}")
        last_seen_epoch = meta.get("last_seen_epoch")
        results.append({
            "event_type": event_type,
            "count": int(count_str),
            "last_seen_epoch": int(last_seen_epoch) if last_seen_epoch else None,
            "last_device_id": meta.get("last_device_id"),
            "example_payload": json.loads(meta.get("example_payload", "{}")),
        })

    results.sort(key=lambda x: x["count"], reverse=True)
    return {"unknown_events": results}


# ---------------------------------------------------------------------------
# Vehicle history (trips + incidents for a given vehicle)
# ---------------------------------------------------------------------------

@router.get("/vehicle-history/{vehicle_id}", include_in_schema=False)
async def vehicle_history(
    vehicle_id: str,
    db: AsyncSession = Depends(get_db),
    _: RequestContext = Depends(require_permission(Permission.PLATFORM_ADMIN)),
):
    """
    Returns the last 20 trips and last 20 incidents for a vehicle.
    Used by the simulator admin panel for customer support lookups.
    """
    from models.trip import Trip
    from models.incident import Incident, IncidentVehicle
    from models.telemetry import TelemetryRaw

    vid = uuid.UUID(vehicle_id)

    # Resolve the device MAC so we can query telemetry_raw (keyed by MAC, not vehicle id)
    device_result = await db.execute(
        select(Device.mac_address, Device.device_id)
        .where(Device.vehicle_id == vid, Device.is_active.is_(True))
        .limit(1)
    )
    device_row = device_result.first()
    telemetry_device_id = (device_row.mac_address or device_row.device_id) if device_row else None

    trips_result = await db.execute(
        select(Trip)
        .where(Trip.vehicle_id == vid)
        .order_by(Trip.start_time.desc())
        .limit(20)
    )
    trips = trips_result.scalars().all()

    incidents_result = await db.execute(
        select(Incident)
        .join(IncidentVehicle, IncidentVehicle.incident_id == Incident.id)
        .where(IncidentVehicle.vehicle_id == vid)
        .order_by(Incident.event_time.desc())
        .limit(20)
    )
    incidents = incidents_result.scalars().all()

    telemetry_rows = []
    if telemetry_device_id:
        tel_result = await db.execute(
            select(TelemetryRaw)
            .where(TelemetryRaw.device_id == telemetry_device_id)
            .order_by(TelemetryRaw.event_timestamp.desc())
            .limit(100)
        )
        telemetry_rows = tel_result.scalars().all()

    return {
        "device_id": telemetry_device_id,
        "trips": [
            {
                "id": str(t.id),
                "status": t.status,
                "start_time": t.start_time.isoformat() if t.start_time else None,
                "end_time": t.end_time.isoformat() if t.end_time else None,
                "distance_meters": t.distance_meters,
                "duration_seconds": t.duration_seconds,
                "start_location": t.start_location,
                "end_location": t.end_location,
            }
            for t in trips
        ],
        "incidents": [
            {
                "id": str(i.id),
                "incident_type": i.incident_type,
                "severity": i.severity,
                "status": i.status,
                "event_time": i.event_time.isoformat() if i.event_time else None,
                "location": i.location,
                "metadata": i.metadata_,
            }
            for i in incidents
        ],
        "telemetry": [
            {
                "event_timestamp": r.event_timestamp.isoformat() if r.event_timestamp else None,
                "lat": r.lat,
                "lng": r.lng,
                "speed": r.speed,
                "rpm": r.rpm,
                "temperature": r.temperature,
                "battery": r.battery,
                "passenger_count": r.passenger_count,
                "event": r.raw_payload.get("event") if isinstance(r.raw_payload, dict) else None,
            }
            for r in telemetry_rows
        ],
    }
