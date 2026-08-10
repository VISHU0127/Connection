# Services Overview

Each folder maps to one EC2 machine. Services within a folder run as separate systemd units on the same machine but share a Python virtualenv.

---

## Machine Layout

```
Machine        Folder              Services (systemd units)
─────────────  ──────────────────  ──────────────────────────────────────────
Machine 1      services/emqx/      EMQX broker
Machine 2      services/api/       FastAPI (REST + WebSocket)
Machine 3      services/pipeline/  vm-ingestion, vm-state-updater, vm-incident-detection
Machine 4      services/data-writers/ vm-telemetry-processor, vm-incident-routing
Machine 5      services/jobs/      vm-jobs (APScheduler)
```

### Infrastructure (managed AWS services — no machine)
- **Kafka** — AWS MSK
- **PostgreSQL** — AWS RDS
- **Redis** — AWS ElastiCache

---

## Data Flow

```
Vehicles (MQTT over TLS)
        │
        ▼
  ┌───────────┐   telemetry.raw    ┌──────────────────────┐
  │  pipeline │ ─────────────────► │    data-writers      │
  │  ingestion│                    │  telemetry-processor │──► Postgres + S3
  └───────────┘                    │  (dedup → normalize  │
                                   │   → batch insert     │──► telemetry.processed
                                   │   → S3 archive)      │
                                   └──────────────────────┘
                                              │
                              telemetry.processed (fan-out)
                              ┌───────────────┴────────────────┐
                              ▼                                 ▼
                   ┌─────────────────────┐         ┌────────────────────┐
                   │ pipeline            │         │ pipeline           │
                   │ state-updater       │         │ incident-detection │
                   └─────────────────────┘         └────────────────────┘
                              │                                 │
                        Redis Pub/Sub                    events.incident
                              │                                 │
                              ▼                                 ▼
                        ┌──────────┐               ┌──────────────────────┐
                        │   api    │◄──────────────│ data-writers         │
                        └──────────┘               │ incident-routing     │
                              ▲                    └──────────────────────┘
                     WebSocket│                            │
                       clients│                     Postgres + Redis
                                                    Pub/Sub notify
                        ┌──────┐
                        │ jobs │ (scheduled maintenance)
                        └──────┘
```

---

## Kafka Topics

| Topic | Producer | Consumer group(s) |
|---|---|---|
| `telemetry.raw` | `ingestion` | `ingestion-processor` (telemetry-processor) |
| `telemetry.processed` | `telemetry-processor` | `state-updater`, `incident-detector` |
| `events.incident` | `incident-detection` | `incident-writer` (incident-routing) |
| `telemetry.dlq` | `ingestion`, `telemetry-processor` | — (manual inspection) |
| `events.incident.dlq` | `incident-detection` | — |

---

## Device Telemetry Payload (spec §1)

Field names are the device firmware contract. Normalization to DB column names happens inside `telemetry-processor`.

| Field | Type | Description |
|---|---|---|
| `device_id` | string | MQTT client ID |
| `timestamp_epoch` | int | Unix seconds (device clock, GPS-corrected) |
| `signal_csq` | int 0–31 | Cellular signal strength |
| `free_ram_kb` | int | Device free RAM |
| `uptime_sec` | int | Device uptime |
| `car_battery_v` | float | 12V vehicle battery |
| `lat` | float | GPS latitude |
| `lon` | float | GPS longitude |
| `gps_speed` | float | GPS-derived speed km/h |
| `hdop` | float | GPS accuracy |
| `rpm` | int | Engine RPM (OBD-II) |
| `obd_speed` | float | OBD-II vehicle speed km/h |
| `coolant_c` | float | Engine coolant temperature °C |
| `cabin_temp` | float | Cabin/ambient temperature °C |
| `engine_temp` | float | Engine bay temperature °C |
| `person_count` | int | Passenger count |
| `event` | string | Hardware IMU event: `ACCIDENT`, `HARSH_BRAKE`, `HARSH_ACCEL`, `PANIC` |

---

## Redis Key Schema

| Key pattern | Type | Written by | Read by |
|---|---|---|---|
| `dedup:{device_id}:{timestamp_epoch}` | String NX | `telemetry-processor` | `telemetry-processor` |
| `device_meta:{device_id}` | String JSON | `api` | `state-updater` |
| `vehicle:state:{device_id}` | Hash TTL=300s | `state-updater` | `api` |
| `vehicle:last_seen:{device_id}` | String TTL=300s | `state-updater` | `api`, `jobs` |
| `org_ids:{org_type}` | Set | `incident-routing` | `incident-routing` |
| `job_lock:{job_name}` | String NX+TTL | `jobs` | `jobs` |
| `s3_retry_queue` | List | `telemetry-processor` | `telemetry-processor` |
| `jwt_denylist:{jti}` | String NX+TTL | `api` | `api` |

---

## Services

### Machine 1 — `emqx/`

MQTT broker. Single entry point for all device connections. Handles authentication via EMQX built-in database (credentials managed by the API on device provision) and per-device topic ACLs.

**Deploy:** `sudo bash machines/emqx/deploy.sh`
Ports: MQTT `:1883`, MQTTS `:8883`, Management API `:18083`

---

### Machine 2 — `api/`

FastAPI process (uvicorn multi-worker). Serves REST API, WebSocket gateway, and admin endpoints. Runs `alembic upgrade head` before starting.

**Device auth:** EMQX native — `POST /devices` calls EMQX Management API to create credential (`username=mac`, `password=sha256(mac:vehicle_id:salt)`). `POST /admin/emqx/sync` reconciles on demand.

**Deploy:** `sudo bash services/api/deploy.sh`
Port: `:8000`

---

### Machine 3 — `pipeline/`

Three systemd units sharing one virtualenv.

**`vm-ingestion`** — Subscribes to EMQX `vehicle/+/+` over MQTT, validates payload against the device protocol schema, produces to `telemetry.raw`. Malformed messages go to `telemetry.dlq`.

**`vm-state-updater`** — Consumes `telemetry.processed`, enriches with vehicle metadata from Redis (`device_meta:{device_id}`), atomically writes vehicle state hash + publishes to `vehicle_state_updates` Pub/Sub via Lua script (EVALSHA). Includes out-of-order timestamp guard.

**`vm-incident-detection`** — Consumes `telemetry.processed`, evaluates each frame against 5 rule categories (hardware events, accident, overspeeding, temperature anomaly, passenger overload), produces to `events.incident`. Per-device rolling state in bounded LRU cache (max 1M entries).

**Deploy:** `sudo bash services/pipeline/deploy.sh`

---

### Machine 4 — `data-writers/`

Two systemd units sharing one virtualenv.

**`vm-telemetry-processor`** — The core pipeline step. Consumes `telemetry.raw`, runs the full 9-step spec pipeline:
1. Deserialize
2. Schema validation
3. Normalize field names (`lon`→`lng`, `gps_speed`→`speed`, etc.)
4. **Dedup** — Redis `SET NX dedup:{device_id}:{timestamp_epoch}` (24h TTL, aligns with DB `UNIQUE (device_id, event_timestamp)`)
5. Batch accumulation (500 records or 1s)
6. Postgres bulk `INSERT … ON CONFLICT DO NOTHING`
7. S3 JSONL.gz archival (best-effort, non-blocking; failures retry via Redis queue)
8. Publish clean frame to `telemetry.processed`
9. Commit Kafka offset

**`vm-incident-routing`** — Consumes `events.incident`, writes to Postgres (`incidents`, `incident_vehicles`, `incident_organization_access`), applies auto-grant logic (POLICE always; AMBULANCE for ACCIDENT/MEDICAL; FIRE_DEPARTMENT for FIRE), publishes to `incident_notifications` Pub/Sub for the WebSocket gateway.

**Deploy:** `sudo bash services/data-writers/deploy.sh`

---

### Machine 5 — `jobs/`

Single APScheduler process. Three scheduled jobs:

| Job | Schedule | What it does |
|---|---|---|
| `trip_computation` | every 30s | Groups GPS frames into trips using Haversine; closes trips after 5min idle |
| `telemetry_pruning` | daily 02:00 UTC | Deletes `telemetry_raw` rows older than 90 days in 10k-row batches |
| `incident_maintenance` | every 5min | Auto-closes OPEN/RESPONDING incidents stale >6h; revokes org access for closed incidents |

Each job acquires a Redis distributed lock before running. Alert webhook fires after 3 consecutive failures.

**Deploy:** `sudo bash services/jobs/deploy.sh`
Health `:8080`, Metrics `:9090`

---

## Ports Reference

| Machine | Service | Health | Metrics |
|---|---|---|---|
| 1 | emqx | — | — |
| 2 | api | `:8000/healthz` | — |
| 3 | vm-ingestion | `:8081/healthz` | `:9100` |
| 3 | vm-incident-detection | `:8082/healthz` | `:9102` |
| 3 | vm-state-updater | `:8083/healthz` | `:9103` |
| 4 | vm-telemetry-processor | `:8084/healthz` | `:9104` |
| 5 | vm-jobs | `:8080/health` | `:9090/metrics` |

## Deployment Order (fresh environment)

```
1. machines/storage/deploy.sh  → copy DB_DSN + REDIS_URL output into machines/app/.env
2. machines/emqx/deploy.sh     → copy EMQX_API_KEY + EMQX_API_SECRET into machines/app/.env
3. machines/app/deploy.sh      → runs DB migrations, starts all 7 application services
```
