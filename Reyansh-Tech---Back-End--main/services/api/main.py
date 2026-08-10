import asyncio
import json
import logging
import pathlib

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse

from config import settings
from routers import admin, auth, devices, incidents, onboard, organizations, simulator, trips, users, vehicles, ws
from seed import seed_platform_admin

logger = logging.getLogger("api")

app = FastAPI(
    title="Vehicle Monitoring API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# --- CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
    expose_headers=["X-Request-ID"],
    max_age=600,
)


# --- Security headers ---
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Cache-Control"] = "no-store"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response


# --- Global exception handler (consistent error shape) ---
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error("unhandled_exception", exc_info=exc)
    return JSONResponse(
        status_code=500,
        content={"error": {"code": "INTERNAL_ERROR", "message": f"{type(exc).__name__}: {exc}"}},
    )


# --- Routers ---
app.include_router(auth.router)
app.include_router(onboard.router)
app.include_router(simulator.router)
app.include_router(admin.router)
app.include_router(organizations.router)
app.include_router(users.router)
app.include_router(vehicles.router)
app.include_router(trips.router)
app.include_router(incidents.router)
app.include_router(devices.router)
app.include_router(ws.router)


@app.get("/", tags=["ops"])
async def root_redirect():
    return RedirectResponse(url="/docs", status_code=307)


# --- WebSocket Pub/Sub relay (background task) ---
# Task is stored at module scope to prevent garbage collection (Python 3.12+)
_background_tasks: set = set()

@app.on_event("startup")
async def on_startup():
    await seed_platform_admin()
    task = asyncio.create_task(ws._pubsub_relay())
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)


@app.get("/healthz", tags=["ops"])
async def health_check():
    return {"status": "ok", "service": settings.service_name}


@app.get("/readyz", tags=["ops"])
async def readiness_check():
    """Check DB and Redis connectivity."""
    from database import engine
    from redis_client import get_pool
    import redis.asyncio as aioredis

    try:
        async with engine.connect() as conn:
            await conn.execute(__import__("sqlalchemy").text("SELECT 1"))
    except Exception as exc:
        return JSONResponse(status_code=503, content={"status": "db_unavailable", "detail": str(exc)})

    try:
        r = aioredis.Redis(connection_pool=get_pool())
        await r.ping()
    except Exception as exc:
        return JSONResponse(status_code=503, content={"status": "redis_unavailable", "detail": str(exc)})

    return {"status": "ready"}


@app.get("/fe-guide", include_in_schema=False)
async def fe_integration_guide():
    """Per-page API integration guide for the frontend team."""
    html = (pathlib.Path(__file__).parent / "fe_guide.html").read_text()
    return HTMLResponse(content=html)


@app.get("/api-reference", include_in_schema=False)
async def api_reference():
    """Human-readable API reference for frontend developers."""
    docs_path = pathlib.Path(__file__).parent.parent.parent / "docs" / "API.md"
    content = docs_path.read_text() if docs_path.exists() else "# API documentation not found."
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>VM Platform — API Reference</title>
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            max-width: 920px; margin: 48px auto; padding: 0 24px;
            line-height: 1.65; color: #1f2328; }}
    pre  {{ background: #f6f8fa; padding: 16px; border-radius: 6px;
            overflow-x: auto; font-size: 13px; }}
    code {{ background: #f6f8fa; padding: 2px 6px; border-radius: 4px;
            font-size: 88%; }}
    pre code {{ background: none; padding: 0; }}
    table {{ border-collapse: collapse; width: 100%; margin: 16px 0; }}
    th, td {{ border: 1px solid #d0d7de; padding: 8px 14px; text-align: left; }}
    th {{ background: #f6f8fa; font-weight: 600; }}
    h1 {{ font-size: 2em; border-bottom: 1px solid #d0d7de; padding-bottom: .4em; }}
    h2 {{ font-size: 1.4em; border-bottom: 1px solid #d0d7de; padding-bottom: .3em;
          margin-top: 2em; }}
    h3 {{ font-size: 1.1em; margin-top: 1.6em; }}
    a  {{ color: #0969da; text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
    blockquote {{ border-left: 4px solid #d0d7de; margin: 0; padding: 0 16px;
                  color: #57606a; }}
    hr {{ border: none; border-top: 1px solid #d0d7de; margin: 24px 0; }}
    .nav {{ position: sticky; top: 0; background: white; border-bottom: 1px solid #d0d7de;
            padding: 10px 0; margin-bottom: 32px; font-size: 13px; }}
    .nav a {{ margin-right: 16px; color: #0969da; }}
  </style>
</head>
<body>
  <div class="nav">
    <strong>VM Platform</strong> &nbsp;|&nbsp;
    <a href="/api-reference">API Reference</a>
    <a href="/docs">Swagger UI</a>
    <a href="/redoc">ReDoc</a>
  </div>
  <div id="content"></div>
  <script>
    const md = {json.dumps(content)};
    document.getElementById('content').innerHTML = marked.parse(md);
  </script>
</body>
</html>"""
    return HTMLResponse(content=html)
