# Vehicle Monitoring Platform

End-to-end IoT telemetry platform for emergency fleet management in India. Devices publish MQTT telemetry → Kafka pipeline enriches and stores it → FastAPI serves live dashboards for Police, Ambulance, Fire, and Platform admin teams via REST + WebSocket.

---

## Table of contents

- [System architecture](#system-architecture)
- [Repository structure](#repository-structure)
- [Infrastructure](#infrastructure)
- [Services](#services)
- [Data flow](#data-flow)
- [Deployment](#deployment)
- [Frontend integration](#frontend-integration)
- [Documentation](#documentation)

---

## System architecture

```
Vehicles (OBD-II devices, MQTT over TLS)
        │
        ▼
  ┌─────────────┐
  │  EMQX       │  Machine 1 — MQTT broker, device auth, topic ACLs
  │  port 1883  │
  └─────────────┘
        │ MQTT subscribe
        ▼
  ┌─────────────┐   telemetry.raw    ┌──────────────────────┐
  │  ingestion  │ ─────────────────► │  telemetry-processor │──► Postgres (telemetry_raw)
  │  Machine 3  │                    │  Machine 4           │──► S3 archive (JSONL.gz)
  └─────────────┘                    └──────────────────────┘
                                              │ telemetry.processed
                              ┌───────────────┴──────────────────┐
                              ▼                                   ▼
                   ┌─────────────────┐               ┌────────────────────────┐
                   │  state-updater  │               │  incident-detection    │
                   │  Machine 3      │               │  Machine 3             │
                   └─────────────────┘               └────────────────────────┘
                              │                                   │ events.incident
                        Redis pub/sub                             ▼
                    vehicle_state_updates         ┌──────────────────────────┐
                              │                   │  incident-routing        │
                              ▼                   │  Machine 4               │
                   ┌─────────────────┐            └──────────────────────────┘
                   │  FastAPI        │◄────────────────── Redis pub/sub
                   │  Machine 2      │               incident_notifications
                   │  port 8000      │
                   └─────────────────┘
                          ▲  ▲
               WebSocket  │  │  REST
                  clients ─  ─ clients (dashboard)

                   ┌─────────────────┐
                   │  jobs           │  Machine 5 — trip computation, pruning, maintenance
                   └─────────────────┘
```

---

## Repository structure

```
vm/
├── machines/                   # One deploy script per machine
│   ├── app/deploy.sh           # Machine 2 — API + all workers (run this for most updates)
│   ├── emqx/deploy.sh          # Machine 1 — EMQX broker
│   ├── kafka/deploy.sh         # Kafka / MSK setup
│   └── storage/deploy.sh       # Machine — Postgres + Redis provisioning
│
├── services/
│   ├── api/                    # FastAPI service (REST + WebSocket)
│   │   ├── main.py
│   │   ├── routers/            # auth, users, vehicles, devices, trips, incidents, orgs, ws
│   │   ├── schemas/            # Pydantic v2 request/response models
│   │   ├── repositories/       # Async SQLAlchemy query layer
│   │   ├── models/             # ORM models
│   │   ├── auth/               # JWT + RBAC
│   │   ├── alembic/            # DB migrations
│   │   ├── fe_guide.html       # FE integration guide (served at /fe-guide)
│   │   └── README.md           # Full API reference
│   ├── workers/
│   │   ├── mqtt-ingestion/     # MQTT → Kafka
│   │   ├── kafka-state-updater/        # Kafka → Redis vehicle state
│   │   ├── kafka-incident-detection/   # Kafka → incident events
│   │   ├── kafka-telemetry-processor/  # Kafka → Postgres + S3
│   │   ├── kafka-incident-routing/     # Kafka → Postgres incidents + pub/sub
│   │   └── postgres-jobs/      # APScheduler (trips, pruning, maintenance)
│   └── shared/                 # Shared Kafka config, logging, health helpers
│
├── docs/
│   ├── API.md                  # Full API reference (also served at /api-reference)
│   └── erd/                    # ERD, data flow, Kafka topology diagrams
│
├── specs/                      # Module-level specs (00–14)
├── scripts/bootstrap.sh        # Python 3.12 installer used by deploy scripts
├── DEPLOY.md                   # Deployment notes for the current release
└── SPEC.md                     # Master platform specification
```

---

## Infrastructure

| Layer | Technology | Notes |
|---|---|---|
| MQTT broker | EMQX | Machine 1, port 1883/8883. Device credentials managed by the API. |
| Message bus | Kafka (AWS MSK) | 5 topics — see `services/SERVICES.md` for full topic map |
| Database | PostgreSQL (AWS RDS) | Alembic-managed schema — 3 migrations applied |
| Cache / pub-sub | Redis (AWS ElastiCache) | Vehicle state, JWT denylist, WS relay, dedup |
| Object storage | AWS S3 | Telemetry archival in JSONL.gz format |
| API | FastAPI + uvicorn | Machine 2, port 8000 |

---

## Services

Seven systemd units run on the App Machine (Machine 2). All are managed by `machines/app/deploy.sh`.

| Unit | Description |
|---|---|
| `vm-api` | FastAPI gateway — REST API, WebSocket, Swagger/ReDoc, FE guide |
| `vm-ingestion` | MQTT → Kafka ingestion worker |
| `vm-state-updater` | Kafka → Redis vehicle state + pub/sub relay |
| `vm-incident-detection` | Kafka incident detection (5 rule categories) |
| `vm-telemetry-processor` | Kafka → Postgres telemetry writer + S3 archival |
| `vm-incident-routing` | Kafka → Postgres incident writer + pub/sub notify |
| `vm-jobs` | APScheduler — trip computation, telemetry pruning, incident maintenance |

---

## Data flow

1. **Device** publishes a telemetry frame to EMQX via MQTT
2. **`vm-ingestion`** validates and forwards to `telemetry.raw` Kafka topic
3. **`vm-telemetry-processor`** deduplicates, normalises, bulk-inserts to Postgres, archives to S3, publishes clean frame to `telemetry.processed`
4. **`vm-state-updater`** consumes `telemetry.processed`, writes `vehicle:state:{device_id}` Redis hash, publishes to `vehicle_state_updates` pub/sub channel
5. **`vm-incident-detection`** consumes `telemetry.processed`, evaluates rules (hardware events, accidents, overspeeding, temperature, passenger anomaly), produces to `events.incident`
6. **`vm-incident-routing`** consumes `events.incident`, writes to Postgres, grants org access, publishes to `incident_notifications` pub/sub channel
7. **`vm-api`** WebSocket gateway relays both pub/sub channels to connected browser clients with server-side RBAC filtering
8. **`vm-jobs`** runs on schedule: trip computation every 30s, telemetry pruning daily, incident maintenance every 5min

---

## Deployment

### First-time (fresh environment)

Run deploy scripts in order — each outputs credentials needed by the next:

```bash
# 1. Provision Postgres + Redis
sudo bash machines/storage/deploy.sh
# → copy DB_DSN and REDIS_URL into machines/app/.env

# 2. Set up EMQX broker
sudo bash machines/emqx/deploy.sh
# → copy EMQX_API_KEY and EMQX_API_SECRET into machines/app/.env

# 3. Deploy API + all workers (runs migrations, starts all 7 services)
sudo bash machines/app/deploy.sh
```

### Updating the API service

Extract the deployment zip and re-run the app deploy script:

```bash
unzip -o vm-api-deploy.zip -d /path/to/repo
sudo bash machines/app/deploy.sh
```

The script is **idempotent** — it updates dependencies, regenerates `.env` files, runs `alembic upgrade head`, and restarts all services. No manual steps needed.

> **Current release:** No DB migrations required — all changes are in the API layer only.

### Post-deploy verification

```bash
curl http://<server>:8000/healthz    # → {"status":"ok"}
curl http://<server>:8000/readyz     # → {"status":"ready"}
vm-status                            # shows all 7 service statuses
```

### Logs

```bash
journalctl -u vm-api -f
tail -f /var/log/vm/vm-api.log
```

---

## Frontend integration

The React dashboard (`vm-fe/`) targets four roles: **Super Admin** (`/admin`), **Police** (`/police`), **Ambulance** (`/ambulance`), and **Fire** (`/fire`). Routing is determined by `user.org_type` returned in the login response.

After deploying, share these URLs with the FE team:

| URL | Purpose |
|---|---|
| `/fe-guide` | **Start here.** Per-page integration guide — every dashboard page mapped to exact API endpoints with Swagger/ReDoc deep links. |
| `/docs` | Swagger UI — interactive, try endpoints with a real token. |
| `/redoc` | ReDoc — readable schema reference. |
| `/api-reference` | Full API reference as HTML. |

Key notes for the FE team:
- Use `user.org_type` to route to the correct dashboard, not `user.role`
- All enum fields (`status`, `severity`, `incident_type`) are `UPPERCASE` — call `.toLowerCase()` before display
- `telemetry/latest` returns all fields as strings — `parseFloat()` before charting
- WebSocket message types: `vehicle_state` and `incident_notification`

See [`services/api/README.md`](services/api/README.md) for the full API reference.

---

## Documentation

| File | Contents |
|---|---|
| [`SPEC.md`](SPEC.md) | Master platform specification (2389 lines, all 15 modules) |
| [`DEPLOY.md`](DEPLOY.md) | Current release deployment notes and change log |
| [`services/api/README.md`](services/api/README.md) | Full API reference — all endpoints, schemas, RBAC, error format |
| [`services/SERVICES.md`](services/SERVICES.md) | Service descriptions, Kafka topics, Redis key schema, port reference |
| [`docs/API.md`](docs/API.md) | API reference (also served at `/api-reference`) |
| [`docs/erd/`](docs/erd/) | ERD, data flow, and Kafka topology diagrams |
| [`specs/`](specs/) | Module-level specs (00–14) |
