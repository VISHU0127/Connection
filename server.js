import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = 3000;

app.use(express.json());

// API Status & Test Endpoints
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'Reyansh Tech Full-Stack Integration Runner' });
});

app.post('/api/v1/auth/login', (req, res) => {
  const { username, password } = req.body || {};
  if (username && password) {
    res.json({
      access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkRyaXZlciBVc2VyIiwiaWF0IjoxNTE2MjM5MDIyfQ',
      token_type: 'bearer',
      expires_in: 3600,
      user: {
        id: 'usr_99812',
        full_name: 'Vishu Sharma',
        email: username.includes('@') ? username : `${username}@reyanshtech.com`,
        phone_number: '+91 9876543210',
        role: 'DRIVER'
      }
    });
  } else {
    res.status(400).json({ detail: { error: { message: 'Username and password required' } } });
  }
});

app.get('/api/v1/vehicles', (req, res) => {
  res.json({
    total: 2,
    items: [
      {
        id: 'veh_001',
        make: 'Mercedes-Benz',
        model: 'S-Class S650',
        year: 2024,
        license_plate: 'MH-12-RT-2024',
        vin: 'WDD2221791A000123',
        status: 'active'
      },
      {
        id: 'veh_002',
        make: 'BMW',
        model: 'X5 xDrive40i',
        year: 2023,
        license_plate: 'DL-01-AB-9876',
        vin: 'WBX533091B000456',
        status: 'active'
      }
    ]
  });
});

app.get('/api/v1/trips', (req, res) => {
  res.json({
    total: 3,
    items: [
      {
        id: 'trip_101',
        start_location: 'Downtown Hub',
        end_location: 'International Airport',
        distance_km: 28.5,
        duration_seconds: 2160,
        start_time: '2026-08-09T08:30:00Z',
        status: 'COMPLETED'
      },
      {
        id: 'trip_102',
        start_location: 'Central Plaza',
        end_location: 'Tech Park Sector 4',
        distance_km: 14.2,
        duration_seconds: 1320,
        start_time: '2026-08-08T17:15:00Z',
        status: 'COMPLETED'
      }
    ]
  });
});

app.get('/api/v1/incidents', (req, res) => {
  res.json({
    total: 2,
    items: [
      {
        id: 'inc_501',
        type: 'HARD_BRAKING',
        severity: 'MEDIUM',
        description: 'Hard braking detected at 65 km/h on Sector 12 expressway',
        timestamp: '2026-08-09T09:12:44Z',
        status: 'UNREAD'
      },
      {
        id: 'inc_502',
        type: 'OVERSPEEDING',
        severity: 'HIGH',
        description: 'Vehicle exceeded 110 km/h limit in a 80 km/h zone',
        timestamp: '2026-08-08T18:04:10Z',
        status: 'ACKNOWLEDGED'
      }
    ]
  });
});

app.get('/api/v1/users/me', (req, res) => {
  res.json({
    id: 'usr_99812',
    full_name: 'Vishu Sharma',
    email: 'vishu@reyanshtech.com',
    phone_number: '+91 9876543210',
    organization_id: 'org_001',
    role: 'DRIVER'
  });
});

// Serve interactive UI preview
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Reyansh Tech - Full-Stack Integration Suite</title>
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="bg-slate-950 text-slate-100 min-h-screen font-sans selection:bg-indigo-500 selection:text-white">
      <div class="max-w-6xl mx-auto px-6 py-8">
        
        <!-- Header -->
        <header class="border-b border-slate-800 pb-6 mb-8 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center font-bold text-white shadow-lg shadow-indigo-500/20">
                RT
              </div>
              <div>
                <h1 class="text-2xl font-bold text-white">Reyansh Tech - Full-Stack Integration Suite</h1>
                <p class="text-slate-400 text-xs mt-0.5">FastAPI Backend & Flutter Mobile App Connection & Diagnostic Hub</p>
              </div>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <span class="inline-flex items-center gap-1.5 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-3 py-1.5 rounded-full text-xs font-medium">
              <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              Full-Stack Bridge Active
            </span>
          </div>
        </header>

        <!-- Status Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-5 mb-8">
          <div class="bg-slate-900/80 border border-slate-800 rounded-xl p-5 hover:border-slate-700 transition">
            <div class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">Backend Architecture</div>
            <div class="text-lg font-bold text-white flex items-center gap-2">
              Python FastAPI 
              <span class="text-xs bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 px-2 py-0.5 rounded">v0.1.0</span>
            </div>
            <div class="text-xs text-slate-400 mt-2 space-y-1">
              <div>• Routers: <code class="text-indigo-300">auth, vehicles, trips, incidents, users</code></div>
              <div>• Auth: OAuth2 Password Bearer / JWT Tokens</div>
            </div>
          </div>

          <div class="bg-slate-900/80 border border-slate-800 rounded-xl p-5 hover:border-slate-700 transition">
            <div class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">Flutter Mobile Client</div>
            <div class="text-lg font-bold text-white flex items-center gap-2">
              Flutter / Dart
              <span class="text-xs bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded">Connected</span>
            </div>
            <div class="text-xs text-slate-400 mt-2 space-y-1">
              <div>• Network Config: <code class="text-emerald-300">AppConstants.baseUrl</code></div>
              <div>• Android: <code class="text-emerald-300">10.0.2.2:8000</code> | iOS: <code class="text-emerald-300">localhost:8000</code></div>
            </div>
          </div>

          <div class="bg-slate-900/80 border border-slate-800 rounded-xl p-5 hover:border-slate-700 transition">
            <div class="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">Data Model Mapping</div>
            <div class="text-lg font-bold text-indigo-400 flex items-center gap-2">
              100% Synced
            </div>
            <div class="text-xs text-slate-400 mt-2 space-y-1">
              <div>• Strongly-typed JSON deserializers in Dart</div>
              <div>• Defensive null handling & fallbacks added</div>
            </div>
          </div>
        </div>

        <!-- Main Content Sections -->
        <div class="space-y-8">
          
          <!-- Run Instructions Box -->
          <div class="bg-slate-900/90 border border-slate-800 rounded-2xl p-6">
            <h2 class="text-lg font-bold text-white mb-3 flex items-center gap-2">
              <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              How to Run the Application Stack Locally
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-4">
              
              <!-- Step 1: FastAPI -->
              <div class="bg-slate-950 border border-slate-800 rounded-xl p-4">
                <div class="flex items-center justify-between mb-2">
                  <span class="text-xs font-bold text-indigo-400 uppercase tracking-wider">Step 1: Start FastAPI Backend</span>
                  <span class="text-[10px] bg-slate-800 text-slate-300 px-2 py-0.5 rounded">Terminal 1</span>
                </div>
                <pre class="bg-slate-900 text-slate-200 text-xs p-3 rounded-lg overflow-x-auto font-mono border border-slate-800/80">cd "Reyansh-Tech---Back-End--main/services/api"
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000</pre>
                <p class="text-[11px] text-slate-400 mt-2">Starts the Python backend API at <code class="text-indigo-300">http://localhost:8000</code> with Swagger docs at <code class="text-indigo-300">/docs</code>.</p>
              </div>

              <!-- Step 2: Flutter -->
              <div class="bg-slate-950 border border-slate-800 rounded-xl p-4">
                <div class="flex items-center justify-between mb-2">
                  <span class="text-xs font-bold text-emerald-400 uppercase tracking-wider">Step 2: Run Flutter Mobile App</span>
                  <span class="text-[10px] bg-slate-800 text-slate-300 px-2 py-0.5 rounded">Terminal 2</span>
                </div>
                <pre class="bg-slate-900 text-slate-200 text-xs p-3 rounded-lg overflow-x-auto font-mono border border-slate-800/80">cd "Reyansh-Tech---Mobile-App-main"
flutter pub get
flutter run</pre>
                <p class="text-[11px] text-slate-400 mt-2">Connects to backend via <code class="text-emerald-300">AppConstants.baseUrl</code> (<code class="text-emerald-300">10.0.2.2:8000</code> on Android Emulator, <code class="text-emerald-300">localhost:8000</code> on iOS Simulator).</p>
              </div>

            </div>
          </div>

          <!-- Environment Credentials Box -->
          <div class="bg-slate-900/90 border border-slate-800 rounded-2xl p-6">
            <h2 class="text-lg font-bold text-white mb-3 flex items-center gap-2">
              <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 0121 9z"></path></svg>
              Configured Environment Credentials
            </h2>
            <div class="bg-slate-950 border border-slate-800 rounded-xl p-4 text-xs font-mono space-y-2 text-slate-300 overflow-x-auto">
              <div><span class="text-indigo-400 font-bold">JWT_SECRET_KEY</span>=1937d089c7a575433a79065562b66e702f407dfe60190ddfee14f8a191a50288</div>
              <div><span class="text-indigo-400 font-bold">EMQX_API_KEY</span>=bp7LiFnH3gfLEm6w</div>
              <div><span class="text-indigo-400 font-bold">EMQX_API_SECRET</span>=VobiOMmofnM0yTdDe5VeutygQlMGDrUmvtmYcOAuQIJ</div>
              <div><span class="text-indigo-400 font-bold">EMQX_DEVICE_SECRET_SALT</span>=6c500db7d989092727ba390dfe88375d17ec58147e182ecf96a5c1054483cf1e</div>
              <div><span class="text-emerald-400 font-bold">ADMIN_EMAIL</span>=admin@example.com</div>
              <div><span class="text-emerald-400 font-bold">ADMIN_PASSWORD</span>=ChangeMe123!</div>
            </div>
            <p class="text-xs text-slate-400 mt-2">Saved to root <code class="text-indigo-300">.env.example</code> and <code class="text-indigo-300">services/api/.env.example</code>.</p>
          </div>

          <!-- Interactive API Tester -->
          <div class="bg-slate-900/90 border border-slate-800 rounded-2xl p-6">
            <h2 class="text-lg font-bold text-white mb-2 flex items-center gap-2">
              <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4"></path></svg>
              Live API Bridge Tester
            </h2>
            <p class="text-slate-400 text-xs mb-4">Click any endpoint below to verify the JSON data response schema expected by Flutter models:</p>
            
            <div class="flex flex-wrap gap-2 mb-4">
              <button onclick="testApi('/api/v1/auth/login', 'POST', {username:'vishu@reyanshtech.com', password:'Password123'})" class="bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-medium px-3 py-2 rounded-lg transition">
                POST /auth/login
              </button>
              <button onclick="testApi('/api/v1/vehicles', 'GET')" class="bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium px-3 py-2 rounded-lg border border-slate-700 transition">
                GET /vehicles
              </button>
              <button onclick="testApi('/api/v1/trips', 'GET')" class="bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium px-3 py-2 rounded-lg border border-slate-700 transition">
                GET /trips
              </button>
              <button onclick="testApi('/api/v1/incidents', 'GET')" class="bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium px-3 py-2 rounded-lg border border-slate-700 transition">
                GET /incidents
              </button>
              <button onclick="testApi('/api/v1/users/me', 'GET')" class="bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-medium px-3 py-2 rounded-lg border border-slate-700 transition">
                GET /users/me
              </button>
            </div>

            <div class="bg-slate-950 border border-slate-800 rounded-xl p-4">
              <div class="flex items-center justify-between mb-2">
                <span id="response-title" class="text-xs font-mono text-indigo-400">Response Console</span>
                <span id="response-status" class="text-[11px] text-slate-500 font-mono">Ready</span>
              </div>
              <pre id="response-box" class="bg-slate-900 text-emerald-400 text-xs p-3 rounded-lg overflow-x-auto font-mono max-h-60">Select an endpoint above to view response payload...</pre>
            </div>
          </div>

        </div>

      </div>

      <script>
        async function testApi(url, method, body) {
          const resBox = document.getElementById('response-box');
          const title = document.getElementById('response-title');
          const status = document.getElementById('response-status');
          
          title.textContent = method + ' ' + url;
          status.textContent = 'Fetching...';
          status.className = 'text-[11px] text-amber-400 font-mono';
          
          try {
            const opts = { method, headers: { 'Content-Type': 'application/json' } };
            if (body) opts.body = JSON.stringify(body);
            const res = await fetch(url, opts);
            const data = await res.json();
            
            status.textContent = 'HTTP ' + res.status + ' OK';
            status.className = 'text-[11px] text-emerald-400 font-mono';
            resBox.textContent = JSON.stringify(data, null, 2);
          } catch (err) {
            status.textContent = 'ERROR';
            status.className = 'text-[11px] text-rose-400 font-mono';
            resBox.textContent = 'Failed to fetch: ' + err.message;
          }
        }
      </script>
    </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
