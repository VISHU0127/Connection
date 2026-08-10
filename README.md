# 🚗 Reyansh Tech - Vehicle Monitoring Platform & Fleet Telemetry

A complete full-stack vehicle tracking, telemetry ingestion, incident detection, and fleet management platform featuring:
- **FastAPI Telemetry & Management Backend** (`Reyansh-Tech---Back-End--main`)
- **Flutter Mobile Application** (`Reyansh-Tech---Mobile-App-main`)
- **Interactive Vehicle Simulator & Web API Bridge** (`server.js` & `simulator.html`)

---

## 📐 Architecture Overview

```
                        ┌─────────────────────────┐
                        │   Flutter Mobile App    │
                        │ (iOS / Android / Web)   │
                        └────────────┬────────────┘
                                     │
                                     ▼
┌─────────────────────────┐   HTTP / REST API   ┌──────────────────────────┐
│  Interactive VM         │ ◄─────────────────► │ FastAPI Backend Service  │
│  Simulator UI           │                     │ (Auth, Vehicles, Trips,  │
│  (Web Portal & SSE)     │ ◄─────────────────► │  Incidents, Telemetry)   │
└─────────────────────────┘                     └────────────┬─────────────┘
                                                             │
                                                             ▼
                                                ┌──────────────────────────┐
                                                │   EMQX / MQTT Broker &   │
                                                │  Kafka Event Processing  │
                                                └──────────────────────────┘
```

---

## 🛠️ Prerequisites & Local System Setup

### Required Tools
- **Node.js**: v18.x or higher
- **Python**: v3.10 or higher
- **Flutter SDK**: v3.19 or higher (compatible with `sdk: '>=3.0.0 <4.0.0'`)
- **Uvicorn / FastAPI**: Python web server

---

## 🚀 1. Running the FastAPI Backend Locally

### Common Issue & Fix: `Error loading ASGI app. Could not import module "main"`
> **Note**: `main.py` is located inside `Reyansh-Tech---Back-End--main/services/api/`. You **must** navigate (`cd`) into that directory before executing `uvicorn main:app`.

### Steps:
```bash
# 1. Navigate to the API service directory
cd Reyansh-Tech---Back-End--main/services/api

# 2. Create and activate a virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 3. Install required Python packages
pip install -r requirements.txt

# 4. Run the FastAPI development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
> The API will now be running at **`http://localhost:8000`** (Swagger docs available at `http://localhost:8000/docs`).

---

## 📱 2. Running the Flutter Mobile App

The Flutter application automatically detects whether it's running on an Android Emulator or iOS Simulator/Web and points to the correct backend host URL:
- **Android Emulator**: `http://10.0.2.2:8000` (maps to local host machine)
- **iOS Simulator / macOS / Web**: `http://localhost:8000`

### Steps:
```bash
# 1. Navigate to the Flutter mobile app directory
cd Reyansh-Tech---Mobile-App-main

# 2. Get Flutter dependencies
flutter pub get

# 3. List available target devices
flutter devices

# 4. Run the app on your preferred simulator/emulator or chrome
flutter run -d chrome     # Run on Web Browser
flutter run -d ios        # Run on iOS Simulator
flutter run -d android    # Run on Android Emulator
```

## 🧪 3. Testing & Verifying Connections

You can verify that all API components are running correctly using `curl` or Postman:

### Check Health Status
```bash
curl http://localhost:8000/healthz
# Expected output: {"status": "ok", ...}

curl http://localhost:8000/readyz
# Expected output: {"status": "ok", "database": "connected", "redis": "connected"}
```

### Test Authentication
```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "driver@example.com", "password": "password123"}'
```

### Test Vehicles & Incidents Endpoints
```bash
curl http://localhost:8000/api/v1/vehicles
curl http://localhost:8000/api/v1/incidents
```

---

## ☁️ 4. Deployment Guide

### A. Deploying to Cloud Run / Docker Container
1. **Dockerfile**: Create a container image for the FastAPI backend:
   ```dockerfile
   FROM python:3.11-slim
   WORKDIR /app
   COPY Reyansh-Tech---Back-End--main/services/api/requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt
   COPY Reyansh-Tech---Back-End--main/services/api/ .
   CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
   ```
2. **Build and Deploy**:
   ```bash
   gcloud run deploy vehicle-api --source . --port 8000 --allow-unauthenticated
   ```

### B. Deploying the Flutter Web Application
```bash
cd Reyansh-Tech---Mobile-App-main
flutter build web --release
# Build output will be located in build/web/
```

---

## ❓ 5. Troubleshooting & FAQ

| Problem | Cause | Solution |
| :--- | :--- | :--- |
| **`Could not import module "main"`** | Running uvicorn from root directory instead of `services/api` | Run `cd Reyansh-Tech---Back-End--main/services/api` before executing `uvicorn main:app --reload` |
| **Mobile App cannot connect to API** | Android emulator trying to use `localhost` instead of `10.0.2.2` | The `AppConstants.baseUrl` automatically uses `10.0.2.2` on Android and `localhost` on iOS/Web |
| **`pubspec.yaml` SDK version conflict** | Local Flutter SDK version mismatch | Updated `environment.sdk` in `pubspec.yaml` to `'>=3.0.0 <4.0.0'` for maximum compatibility |
| **CORS errors in Web browser** | Missing CORS headers on FastAPI | Ensure `CORSMiddleware` in `main.py` allows origins `*` or `http://localhost:3000` |

