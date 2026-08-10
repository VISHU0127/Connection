# VM API Service

FastAPI backend for the Vehicle Monitoring platform. Handles authentication, organisation and user management, vehicle/incident/trip CRUD, WebSocket live updates, device provisioning, and the platform simulator.

**Production base URL:** `https://api.reyanshtechnologies.com`

---

## Table of contents

- [Architecture](#architecture)
- [Environment variables](#environment-variables)
- [Local setup](#local-setup)
- [Deployment](#deployment)
- [Database migrations](#database-migrations)
- [Bootstrap admin user](#bootstrap-admin-user)
- [Authentication](#authentication)
- [RBAC — permissions matrix](#rbac--permissions-matrix)
- [API endpoints](#api-endpoints)
  - [Auth](#auth)
  - [Onboarding](#onboarding)
  - [Organizations](#organizations)
  - [Users](#users)
  - [Vehicles](#vehicles)
  - [Devices](#devices)
  - [Trips](#trips)
  - [Incidents](#incidents)
  - [Admin](#admin)
  - [Simulator](#simulator)
  - [WebSocket](#websocket)
  - [Health & docs](#health--docs)
- [Pagination envelope](#pagination-envelope)
- [Error format](#error-format)
- [FE developer resources](#fe-developer-resources)

---

## Architecture

```
Browser / Mobile App
        │
        ▼
  FastAPI (port 8000)
  ├── PostgreSQL  — persistent data (orgs, users, vehicles, devices, incidents, trips, telemetry)
  ├── Redis       — device state cache · JWT denylist · WS pub/sub · simulator session relay
  └── EMQX API   — device credential management (create / delete / sync)
```

The API does **not** receive MQTT telemetry directly. The `mqtt-ingestion` worker subscribes to EMQX and forwards frames to Kafka; downstream workers enrich and write to Postgres/Redis, then publish to Redis pub/sub channels that the API's WebSocket gateway relays to connected clients.

---

## Environment variables

Copy `.env.example` to `.env` and fill in all values.

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✓ | Async SQLAlchemy URL — `postgresql+asyncpg://user:pass@host/db` |
| `REDIS_URL` | ✓ | Redis connection string — `redis://host:6379/0` |
| `REDIS_PASSWORD` | | Redis AUTH password (omit if none) |
| `JWT_SECRET_KEY` | ✓ | Long random string used to sign JWTs |
| `JWT_ALGORITHM` | | Default: `HS256` |
| `JWT_KID` | | Key ID header on issued JWTs. Default: `v1` |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | | Access token TTL. Default: `15` |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | | Refresh token TTL. Default: `7` |
| `EMQX_API_URL` | ✓ | EMQX management API base URL — `http://host:18083` |
| `EMQX_API_KEY` | ✓ | EMQX API key |
| `EMQX_API_SECRET` | ✓ | EMQX API secret |
| `EMQX_DEVICE_SECRET_SALT` | ✓ | Salt used to derive deterministic device MQTT passwords |
| `MQTT_BROKER` | ✓ | EMQX MQTT broker hostname / IP (used by simulator) |
| `MQTT_PORT` | | MQTT broker port. Default: `1883` |
| `CORS_ORIGINS` | | Comma-separated allowed origins. Default includes `localhost:3000`, `localhost:5173`, `localhost:8080` |
| `LOG_LEVEL` | | Python log level. Default: `INFO` |
| `ADMIN_EMAIL` | | Seed a platform super_admin on startup (idempotent) |
| `ADMIN_PASSWORD` | | Password for the seeded admin (used on first seed only) |

---

## Local setup

```bash
cd services/api
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env          # fill in values
alembic upgrade head          # apply all migrations
uvicorn main:app --reload     # http://localhost:8000
```

Interactive docs: `http://localhost:8000/docs`
FE integration guide: `http://localhost:8000/fe-guide`

---

## Deployment

All services run on the **App Machine** under `systemd` as the `vmservice` user. The deployment script is **idempotent** — safe to re-run on updates.

### Steps

```bash
# 1. Extract the deployment zip into the repo root
unzip -o vm-api-deploy.zip -d /path/to/repo

# 2. Run the deploy script (must be root)
sudo bash machines/app/deploy.sh
```

The script handles all of the following automatically:

| Step | What happens |
|---|---|
| Env validation | Checks all required variables in `machines/app/.env` |
| Python setup | Installs Python 3.12 if missing (`scripts/bootstrap.sh`) |
| Service user | Creates `vmservice` system user if absent |
| Dependencies | Creates / updates virtualenvs and installs `requirements.txt` |
| Config | Writes per-service `.env` files from the central `machines/app/.env` |
| Migrations | Runs `alembic upgrade head` — skips already-applied revisions |
| Systemd | Writes / overwrites unit files, enables and restarts all services |

### Managed services

| Service | Description |
|---|---|
| `nginx` | Reverse proxy — TLS termination on port 443, proxies to vm-api on 127.0.0.1:8000 |
| `vm-api` | FastAPI gateway (port 8000, localhost-only — accessed via nginx) |
| `vm-ingestion` | MQTT → Kafka ingestion worker |
| `vm-state-updater` | Kafka → Redis state updater |
| `vm-incident-detection` | Kafka incident detection worker |
| `vm-telemetry-processor` | Kafka → Postgres telemetry writer |
| `vm-incident-routing` | Kafka → Postgres incident router |
| `vm-jobs` | APScheduler background jobs |

### Post-deploy verification

```bash
curl https://api.reyanshtechnologies.com/healthz    # → {"status": "ok"}
curl https://api.reyanshtechnologies.com/readyz     # → {"status": "ready"}
```

### Logs

```bash
vm-status                            # shows all service statuses at a glance
journalctl -u vm-api -f              # live API logs
tail -f /var/log/vm/vm-api.log       # file-based log
```

### DB migrations

No migrations are required when deploying the current release — all changes are Pydantic schema additions and new query methods on existing tables. `alembic upgrade head` is always safe to run (skips applied revisions).

Current revisions:
- `0001_initial_schema`
- `0002_device_emqx_native_auth`
- `0003_add_customer_org_type`

---

## Database migrations

```bash
# Apply all pending migrations
alembic upgrade head

# Create a new migration after changing a model
alembic revision --autogenerate -m "short description"

# Show current revision
alembic current
```

---

## Bootstrap admin user

Set `ADMIN_EMAIL` and `ADMIN_PASSWORD` in `.env`. On startup the API will:

1. Find or create the PLATFORM organisation (`org_type = PLATFORM`).
2. Create the user with `role = super_admin` — **only if the email does not already exist**.
3. Skip silently on every subsequent restart (idempotent).

The password is never overwritten after the first seed — change it via `PATCH /users/{id}`.

---

## Authentication

The API uses short-lived **JWT access tokens** and long-lived **refresh tokens**.

### Token flow

```
POST /auth/login
  → access_token  (15 min, signed JWT)
  → refresh_token (7 days, opaque, bcrypt-hashed in DB)

Authorization: Bearer <access_token>   ← required on all protected endpoints

POST /auth/refresh
  → new access_token + new refresh_token   ← both tokens rotate on every call

POST /auth/logout
  → access token JTI added to Redis denylist (TTL = remaining token lifetime)
  → refresh token cleared from DB
```

### JWT claims

| Claim | Value |
|---|---|
| `sub` | User UUID |
| `jti` | Unique token ID (used for denylist) |
| `org_id` | Organisation UUID |
| `org_type` | `PLATFORM` · `POLICE` · `AMBULANCE` · `FIRE_DEPARTMENT` · `CUSTOMER` |
| `role` | See RBAC matrix below |
| `iat` / `exp` | Issued / expiry timestamps |

---

## RBAC — permissions matrix

Every endpoint declares a required `Permission`. The `require_permission` dependency checks the caller's `(org_type, role)` pair against the matrix below.

| org_type | role | Permissions |
|---|---|---|
| `PLATFORM` | `super_admin` | All permissions including `PLATFORM_ADMIN` |
| `PLATFORM` | `support_user` | Read all + `DEVICE_STATUS_WRITE` |
| `PLATFORM` | `data_analyst` | Read-only (all resources) |
| `POLICE` | `org_admin` | Full access to own org + vehicles + incidents + `DISPATCH` |
| `POLICE` | `operator` | Vehicle write + incident status + `DISPATCH` |
| `POLICE` | `dispatcher` | Vehicle read + incident status + `DISPATCH` |
| `POLICE` | `viewer` | Read-only |
| `AMBULANCE` | `org_admin` | Full access + `DISPATCH` |
| `AMBULANCE` | `operator` | Vehicle write + incident status + `DISPATCH` |
| `AMBULANCE` | `dispatcher` | Incident status + `DISPATCH` |
| `AMBULANCE` | `viewer` | Read-only |
| `FIRE_DEPARTMENT` | `org_admin` | Org + user + vehicle + incident write |
| `FIRE_DEPARTMENT` | `operator` | Vehicle read + incident status |
| `FIRE_DEPARTMENT` | `viewer` | Read-only |
| `CUSTOMER` | `owner` | Own vehicles + trips + incidents + telemetry |

**RBAC filtering is applied at the query layer** — not just at the permission check. A CUSTOMER owner calling `GET /vehicles` only sees their org's vehicles; a POLICE operator sees USER_VEHICLEs and their own emergency fleet.

---

## API endpoints

### Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/auth/login` | — | Email + password → access + refresh tokens + user info |
| `POST` | `/auth/refresh` | — | Exchange refresh token → new token pair |
| `POST` | `/auth/logout` | Bearer | Revoke access + refresh token |

**`POST /auth/login`** request:
```json
{ "email": "user@example.com", "password": "secret" }
```
Response:
```json
{
  "access_token": "eyJ...",
  "refresh_token": "...",
  "expires_in": 900,
  "user": {
    "user_id": "uuid",
    "email": "user@example.com",
    "name": "First Last",
    "org_id": "uuid",
    "org_type": "PLATFORM",
    "org_name": "VM Operations",
    "role": "super_admin"
  }
}
```

> Use `user.org_type` (not `user.role`) to select the dashboard to route to.  
> `user.org_name` is the organisation's display name — persist the full `user` object for sidebar rendering.

---

### Onboarding

No authentication required. Triggered by QR code scan on a new OBD device.

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/onboard` | — | Register new customer: creates org + user + vehicle + device + EMQX credentials |
| `POST` | `/onboard/vehicle` | Bearer (`CUSTOMER_WRITE`) | Existing customer adds a second vehicle |

`POST /onboard` creates everything in one transaction and returns a JWT:

```json
{
  "email": "owner@example.com",
  "password": "secret",
  "first_name": "Raj",
  "last_name": "Sharma",
  "phone": "+919876543210",
  "registration_number": "MP09AB1234",
  "make": "Maruti",
  "model": "Swift",
  "year": 2022,
  "vehicle_type": "CAR",
  "vin": "optional",
  "mac_address": "AA:BB:CC:DD:EE:FF"
}
```

Resubmitting the same `email` + `mac_address` resumes a partial onboarding idempotently — does not return `409`.  
`emqx_username` and `emqx_password` in the response are derived deterministically and never change — burn them into device firmware once.

---

### Organizations

| Method | Path | Permission | Description |
|---|---|---|---|
| `GET` | `/organizations` | `ORG_READ` | List organisations (PLATFORM: all; others: own org only) |
| `POST` | `/organizations` | `ORG_WRITE` | Create organisation — PLATFORM `super_admin` only |
| `GET` | `/organizations/{id}` | `ORG_READ` | Get single organisation |
| `PATCH` | `/organizations/{id}` | `ORG_WRITE` | Update name, active status, or metadata |
| `DELETE` | `/organizations/{id}` | `ORG_DELETE` | Soft-delete (sets `is_active=false`) — PLATFORM `super_admin` only |

**Query params** for `GET /organizations`:

| Param | Type | Description |
|---|---|---|
| `org_type` | string | Filter: `PLATFORM` · `POLICE` · `AMBULANCE` · `FIRE_DEPARTMENT` · `CUSTOMER` |
| `is_active` | bool | Filter by active status |
| `search` | string | Free-text search on name |
| `page` / `page_size` | int | Pagination (max `page_size=100`) |

Valid `org_type` values: `PLATFORM`, `POLICE`, `AMBULANCE`, `FIRE_DEPARTMENT`, `CUSTOMER`. There is no `HOSPITAL` type.

---

### Users

| Method | Path | Permission | Description |
|---|---|---|---|
| `GET` | `/users` | `USER_READ` | List users (PLATFORM: all; others: own org only) |
| `POST` | `/users` | `USER_WRITE` | Create user |
| `GET` | `/users/{id}` | `USER_READ` | Get single user |
| `PATCH` | `/users/{id}` | `USER_WRITE` | Update user fields (name, role, active status, password) |

**Query params** for `GET /users`:

| Param | Type | Description |
|---|---|---|
| `org_id` | UUID | Filter by organisation |
| `role` | string | Filter by role |
| `is_active` | bool | Filter by active status |
| `search` | string | Free-text search on name / email |
| `page` / `page_size` | int | Pagination (max `page_size=100`) |

User response includes `org_name`, `org_type`, `role`, and a flat `permissions[]` array.

---

### Vehicles

| Method | Path | Permission | Description |
|---|---|---|---|
| `GET` | `/vehicles` | `VEHICLE_READ` | List vehicles (RBAC-filtered, paginated) |
| `GET` | `/vehicles/{id}` | `VEHICLE_READ` | Get single vehicle |
| `POST` | `/vehicles` | `VEHICLE_WRITE` | Create vehicle |
| `PATCH` | `/vehicles/{id}` | `VEHICLE_WRITE` | Update vehicle fields |
| `GET` | `/vehicles/{id}/telemetry/latest` | `TELEMETRY_READ` | Latest state snapshot from Redis |
| `GET` | `/vehicles/{id}/telemetry/history` | `TELEMETRY_READ` | Historical telemetry points from Postgres |

**Query params** for `GET /vehicles`:

| Param | Type | Default | Description |
|---|---|---|---|
| `vehicle_category` | string | — | `USER_VEHICLE` or `EMERGENCY_VEHICLE` |
| `is_active` | bool | `true` | Filter by active status |
| `search` | string | — | Full-text search on registration, make, model |
| `page` / `page_size` | int | `1` / `50` | Pagination (max 100) |

**`GET /vehicles/{id}/telemetry/latest`** reads directly from Redis (< 50 ms).  
All fields are returned as **strings** — parse with `parseFloat()` / `parseInt()` before arithmetic or charting.  
Returns `200` with null fields if the vehicle exists but has not yet sent telemetry.

**`GET /vehicles/{id}/telemetry/history`** query params: `from_dt`, `to_dt` (ISO 8601), `page`, `page_size` (max 500).

---

### Devices

| Method | Path | Permission | Description |
|---|---|---|---|
| `GET` | `/devices` | `DEVICE_READ` | List devices (RBAC-filtered, paginated) |
| `POST` | `/devices` | `DEVICE_WRITE` | Provision a new device — creates EMQX credentials |
| `GET` | `/devices/{id}` | `DEVICE_READ` | Get device by internal `device_id` |
| `PATCH` | `/devices/{id}/status` | `DEVICE_STATUS_WRITE` | Activate / deactivate device |

**Query params** for `GET /devices`:

| Param | Type | Description |
|---|---|---|
| `vehicle_id` | UUID | Filter by linked vehicle |
| `is_active` | bool | Filter by active status |
| `page` / `page_size` | int | Pagination (max 100) |

EMQX credentials (`emqx_username`, `emqx_password`) are returned **once** in the provision response and never stored in plaintext. Re-derive with:

```
sha256(<mac_address>:<vehicle_id>:<EMQX_DEVICE_SECRET_SALT>)
```

Deactivating a device removes its EMQX credential — it stops sending telemetry immediately.

**`mac_address` is a free-text field** — the hardware team does not need to format it as a standard MAC address. Any unique identifier works. Avoid `/`, `#`, `+`, and spaces (reserved MQTT topic characters). The value becomes the EMQX username, the MQTT topic segment, and the Redis state key.

---

### Trips

| Method | Path | Permission | Description |
|---|---|---|---|
| `GET` | `/trips` | `TRIP_READ` | List trips (RBAC-filtered, paginated) |
| `GET` | `/trips/{id}` | `TRIP_READ` | Get single trip |
| `GET` | `/trips/{id}/telemetry` | `TELEMETRY_READ` | GPS + telemetry points recorded during the trip |

Trips are created automatically by the `kafka-telemetry-processor` worker — there is no `POST /trips` endpoint.

**Query params** for `GET /trips`:

| Param | Type | Description |
|---|---|---|
| `vehicle_id` | UUID | Filter by vehicle |
| `status` | string | `ACTIVE` · `COMPLETED` · `CANCELLED` |
| `from_dt` / `to_dt` | datetime | ISO 8601 range matched against `start_time` |
| `page` / `page_size` | int | Pagination (max 100) |

**`GET /trips/{id}/telemetry`** returns ordered GPS points for route replay. `page_size` supports up to 500 to load a short trip in one call.

---

### Incidents

| Method | Path | Permission | Description |
|---|---|---|---|
| `GET` | `/incidents` | `INCIDENT_READ` | List incidents (RBAC-filtered, paginated) |
| `GET` | `/incidents/{id}` | `INCIDENT_READ` | Get single incident |
| `PATCH` | `/incidents/{id}/status` | `INCIDENT_STATUS_WRITE` | Update incident status |

Incidents are created automatically by the `kafka-incident-detection` and `kafka-incident-routing` workers — there is no `POST /incidents` endpoint.

**Query params** for `GET /incidents`:

| Param | Type | Description |
|---|---|---|
| `status` | string | `OPEN` · `ACKNOWLEDGED` · `RESPONDING` · `RESOLVED` · `CLOSED` · `CANCELLED` · `FALSE_POSITIVE` |
| `severity` | string | `LOW` · `MEDIUM` · `HIGH` · `CRITICAL` |
| `incident_type` | string | `ACCIDENT` · `OVERSPEEDING` · `MEDICAL` · `FIRE_DETECTED` · `TEMPERATURE_ANOMALY` · `PASSENGER_ANOMALY` · `HARSH_BRAKE` |
| `page` / `page_size` | int | Pagination |

All enum fields are UPPERCASE. Status lifecycle:

```
OPEN → ACKNOWLEDGED → RESPONDING → RESOLVED / CLOSED
                                 → CANCELLED / FALSE_POSITIVE  (terminal)
```

---

### Admin

Platform `super_admin` only (`PLATFORM_ADMIN` permission).

| Method | Path | Description |
|---|---|---|
| `POST` | `/admin/emqx/sync` | Reconcile EMQX credentials against active devices in Postgres — creates missing, removes stale. Idempotent. |

---

### Simulator

Platform `super_admin` only (`PLATFORM_ADMIN` permission). Browser UI at `GET /simulator`.

| Method | Path | Description |
|---|---|---|
| `GET` | `/simulator` | Simulator HTML UI |
| `POST` | `/simulator/lookup-vehicle` | Look up a vehicle by `device_id` or `registration_number` — re-derives EMQX password |
| `POST` | `/simulator/simulate` | Start a background simulation scenario — returns `session_id` |
| `GET` | `/simulator/stream/{session_id}` | SSE stream of scenario log messages |
| `GET` | `/simulator/services` | Health status of all platform services |
| `GET` | `/simulator/stats` | Live platform stats from Postgres + Redis |

**Scenarios** (`action` in `POST /simulator/simulate`):

| action | Description |
|---|---|
| `normal_drive` | 10-frame normal drive — no incidents |
| `harsh_braking` | Drive with harsh braking event → `HARSH_BRAKE` incident |
| `accident` | Drive with collision event → `CRITICAL` incident |
| `overheat` | Engine temperature spike → `TEMPERATURE_ANOMALY` incident |
| `panic_button` | Panic button press → `HIGH` severity incident |
| `sos` | SOS event → incident |

Simulate request body:
```json
{
  "action": "normal_drive",
  "mac_address": "AA:BB:CC:DD:EE:FF",
  "emqx_password": "derived-password",
  "lat": 22.7196,
  "lon": 75.8577
}
```

The simulator publishes real MQTT frames — the full pipeline (EMQX → ingestion → Kafka → workers → Postgres/Redis → WebSocket) runs end-to-end.

SSE events from `/simulator/stream/{session_id}`:
```json
{ "ts": "14:32:01", "type": "info",    "msg": "Frame 1 of 10 published" }
{ "ts": "14:32:03", "type": "success", "msg": "All 10 frames published" }
{ "ts": "14:32:03", "type": "error",   "msg": "Frame 3 publish failed: ..." }
```

---

### WebSocket

| Path | Auth | Description |
|---|---|---|
| `wss://api.reyanshtechnologies.com/ws/connect?token=<access_token>` | JWT query param | Live vehicle state + incident notifications |

The access token is passed as a query parameter (browsers cannot set `Authorization` headers on WebSocket connections). The token is validated and checked against the Redis denylist on connection.

Message types pushed to the client:

```json
{ "type": "vehicle_state",           "data": { ... } }
{ "type": "incident_notification",   "data": { ... } }
```

**Server-side RBAC filtering** — messages are filtered before delivery:

| org_type | Receives |
|---|---|
| `PLATFORM` | All vehicle updates + all incidents |
| `POLICE` | All `USER_VEHICLE` updates + own `EMERGENCY_VEHICLE` updates + own incidents |
| `AMBULANCE` / `FIRE_DEPARTMENT` | Own `EMERGENCY_VEHICLE` updates + incidents routed to them |
| `CUSTOMER` | Own org's vehicles only + own incidents |

Connect once per session and keep the connection open. The client browser simulator uses a 20-second keepalive ping against the server's 30-second receive-timeout.

---

### Health & docs

| Path | Description |
|---|---|
| `GET /healthz` | Liveness — `{"status": "ok"}` |
| `GET /readyz` | Readiness — checks DB + Redis connectivity |
| `GET /docs` | Swagger UI (interactive) |
| `GET /redoc` | ReDoc (readable reference) |
| `GET /api-reference` | Markdown API reference rendered as HTML |
| `GET /fe-guide` | Per-page FE integration guide — maps every dashboard page to its API endpoints with Swagger/ReDoc deep links |

---

## Pagination envelope

All list endpoints return:

```json
{
  "data": [ ... ],
  "meta": {
    "total":     150,
    "page":        1,
    "page_size":  20,
    "pages":       8
  }
}
```

Read `response.data` for items and `response.meta.total` for counts / KPI cards.

---

## Error format

All error responses use a consistent envelope:

```json
{
  "error": {
    "code":    "UNAUTHORIZED",
    "message": "Invalid credentials."
  }
}
```

Common codes: `UNAUTHORIZED` · `FORBIDDEN` · `RESOURCE_NOT_FOUND` · `CONFLICT` · `INVALID_ACTION` · `VALIDATION_ERROR` · `INTERNAL_ERROR`

---

## FE developer resources

After deployment, share these URLs with the frontend team:

| URL | Description |
|---|---|
| `/fe-guide` | **Start here.** Per-page integration guide — maps every dashboard page to the exact API endpoints each section needs, with direct Swagger and ReDoc deep links. |
| `/docs` | Swagger UI — interactive; try any endpoint with a real token. |
| `/redoc` | ReDoc — cleaner reading experience; best for studying request/response schemas. |
| `/api-reference` | Full markdown API reference rendered as HTML. |

### Key integration notes for FE

- **CORS**: `http://localhost:3000`, `http://localhost:5173`, and `http://localhost:8080` are all allowed — no proxy needed during local development.
- **WebSocket URL**: use `wss://` (not `ws://`) — `wss://api.reyanshtechnologies.com/ws/connect?token=...`
- Use `user.org_type` from login to select the dashboard route — **not** `user.role`.
  - `PLATFORM` → `/admin` · `POLICE` → `/police` · `AMBULANCE` → `/ambulance` · `FIRE_DEPARTMENT` → `/fire`
- `user.role` is the granular permission level (`org_admin`, `operator`, `dispatcher`, `viewer`) — use for feature gating.
- `user.org_name` — persist the full `user` object from login for sidebar display.
- All enum fields (`status`, `severity`, `incident_type`, `org_type`) are `UPPERCASE` — call `.toLowerCase()` before display.
- `VehicleStateRead` (from `telemetry/latest`) returns all fields as **strings** — parse with `parseFloat()` before charting.
- WebSocket message type for incidents is `incident_notification`, not `incident`.
