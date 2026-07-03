# DT Tracker Backend — Full Implementation Context

## Overview

DT Tracker is an IoT GPS tracking platform. The ESP32-S3 + SIM7670 tracker sends GPS telemetry to a Node.js backend hosted on AWS EC2. The backend writes data to Firebase using the Admin SDK.

```text
ESP32-S3 + SIM7670
  -> HTTPS POST /api/v1/ingest
  -> Nginx on EC2
  -> Node.js / Express / PM2
  -> Firebase Admin SDK
  -> Realtime Database + Firestore
```

The ESP32 does not write directly to Firebase.

---

## Environments

| Environment | URL | PM2 Process | Port | Env File |
|---|---|---|---|---|
| Dev | https://dev.dt-tracker.com | dt-tracker-dev | 3001 | .env.dev |
| Staging | https://staging.dt-tracker.com | dt-tracker-staging | 3002 | .env.staging |
| Prod | https://api.dt-tracker.com | dt-tracker-prod | 3000 | .env.prod |

Base API URLs for Flutter:

```text
dev      https://dev.dt-tracker.com/api/v1
staging  https://staging.dt-tracker.com/api/v1
prod     https://api.dt-tracker.com/api/v1
```

---

## EC2 Paths

```bash
/home/ubuntu/DT-Tracker-Backend
/home/ubuntu/secrets/serviceAccountKey.json
/etc/nginx/sites-enabled/dt-tracker
```

---

## DNS

```text
api.dt-tracker.com      -> EC2 public IP
dev.dt-tracker.com      -> EC2 public IP
staging.dt-tracker.com  -> EC2 public IP
```

Nginx maps:

```text
api.dt-tracker.com      -> 127.0.0.1:3000
dev.dt-tracker.com      -> 127.0.0.1:3001
staging.dt-tracker.com  -> 127.0.0.1:3002
```

---

## Nginx Commands

```bash
sudo nano /etc/nginx/sites-enabled/dt-tracker
sudo nginx -t
sudo systemctl reload nginx
```

HTTPS:

```bash
sudo certbot --nginx \
  -d api.dt-tracker.com \
  -d dev.dt-tracker.com \
  -d staging.dt-tracker.com
```

---

## PM2

`ecosystem.config.js`

```js
module.exports = {
  apps: [
    {
      name: "dt-tracker-prod",
      script: "server.js",
      cwd: "/home/ubuntu/DT-Tracker-Backend",
      env: { NODE_ENV: "prod" }
    },
    {
      name: "dt-tracker-dev",
      script: "server.js",
      cwd: "/home/ubuntu/DT-Tracker-Backend",
      env: { NODE_ENV: "dev" }
    },
    {
      name: "dt-tracker-staging",
      script: "server.js",
      cwd: "/home/ubuntu/DT-Tracker-Backend",
      env: { NODE_ENV: "staging" }
    }
  ]
};
```

Commands:

```bash
pm2 list
pm2 logs dt-tracker-dev --lines 50
pm2 restart dt-tracker-dev --update-env
pm2 restart dt-tracker-staging --update-env
pm2 restart dt-tracker-prod --update-env
pm2 save
pm2 startup
```

---

## Environment Files

`.env.dev`

```env
PORT=3001
FIREBASE_DB_URL=https://dttracker-dev-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-dev
ADMIN_API_KEY=<secret-dev-key>
```

`.env.staging`

```env
PORT=3002
FIREBASE_DB_URL=https://dttracker-staging-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-staging
ADMIN_API_KEY=<secret-staging-key>
```

`.env.prod`

```env
PORT=3000
FIREBASE_DB_URL=https://dttracker-prod-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-prod
ADMIN_API_KEY=<secret-prod-key>
```

Do not commit `.env.*`.

---

## Firebase Architecture

One Firebase project with multiple Realtime Databases and multiple Firestore databases.

Realtime Database instances:

```text
dttracker-dev-01
dttracker-staging-01
dttracker-prod-01
```

Firestore databases:

```text
dttracker-dev
dttracker-staging
dttracker-prod
```

`FIREBASE_DB_URL` selects Realtime Database.  
`FIRESTORE_DATABASE_ID` selects Firestore database.

---

## Libraries

```json
{
  "dependencies": {
    "dotenv": "^17.4.2",
    "express": "^5.2.1",
    "firebase-admin": "^13.9.0",
    "joi": "^18.0.2"
  }
}
```

---

## Project Structure

```text
DT-Tracker-Backend/
├── ecosystem.config.js
├── firebase.js
├── package.json
├── package-lock.json
├── server.js
├── src/
│   ├── middleware/
│   │   ├── adminApiKey.js
│   │   ├── authMiddleware.js
│   │   └── vehicleOwnership.js
│   ├── routes/
│   │   ├── ingest.js
│   │   ├── trackers.js
│   │   └── vehicles.js
│   └── validators/
│       ├── ingestValidator.js
│       ├── registryValidator.js
│       ├── trackerValidator.js
│       └── vehicleValidator.js
```

---

## `firebase.js`

```js
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");

const serviceAccount = require("/home/ubuntu/secrets/serviceAccountKey.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DB_URL,
  });
}

const app = admin.app();

const db = admin.database();
const firestore = getFirestore(app, process.env.FIRESTORE_DATABASE_ID);

module.exports = {
  admin,
  db,
  firestore,
};
```

Test Firestore:

```bash
NODE_ENV=dev node -e "require('dotenv').config({path:'.env.dev'}); const {firestore}=require('./firebase'); firestore.collection('users').limit(1).get().then(s=>{console.log('Firestore OK docs:',s.size); process.exit(0)}).catch(e=>{console.error('Firestore ERROR:',e.message); process.exit(1)})"
```

---

## `server.js`

```js
const env = process.env.NODE_ENV || "prod";
require("dotenv").config({ path: `.env.${env}` });

console.log(`Running environment: ${env}`);

const express = require("express");

const ingestRoute = require("./src/routes/ingest");
const trackersRoute = require("./src/routes/trackers");
const vehiclesRoute = require("./src/routes/vehicles");

const app = express();

app.use(express.json());

app.use((req, res, next) => {
  const start = Date.now();

  res.on("finish", () => {
    const duration = Date.now() - start;
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      env,
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      durationMs: duration,
      imei: req.body?.imei || null,
      ip: req.headers["x-forwarded-for"] || req.socket.remoteAddress,
      userAgent: req.headers["user-agent"] || null,
    }));
  });

  next();
});

app.get("/", (req, res) => {
  res.json({
    name: "DT Tracker Backend",
    description: "GPS Tracking Backend API",
    environment: env,
    version: require("./package.json").version,
    status: "UP",
  });
});

app.get("/health", (req, res) => {
  res.json({
    status: "UP",
    environment: env,
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

app.get("/version", (req, res) => {
  res.json({
    version: require("./package.json").version,
    node: process.version,
    environment: env,
  });
});

app.use("/ingest", ingestRoute);
app.use("/api/v1/ingest", ingestRoute);
app.use("/api/v1/trackers", trackersRoute);
app.use("/api/v1/vehicles", vehiclesRoute);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## Middleware

### `src/middleware/authMiddleware.js`

Validates Firebase ID tokens sent from Flutter.

```js
const { admin } = require("../../firebase");

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;

  if (!token) {
    return res.status(401).json({
      error: "unauthorized",
      message: "Missing Firebase ID token",
    });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    req.user = { uid: decoded.uid, email: decoded.email || null };
    next();
  } catch (error) {
    console.error("Firebase Auth Error:");
    console.error(error);
    return res.status(401).json({
      error: "unauthorized",
      message: error.message,
    });
  }
}

module.exports = authMiddleware;
```

### `src/middleware/vehicleOwnership.js`

Verifies authenticated user owns the requested vehicle.

```js
const { firestore } = require("../../firebase");

async function vehicleOwnership(req, res, next) {
  try {
    const uid = req.user.uid;
    const { vehicleId } = req.params;

    const vehicleRef = firestore
      .collection("users")
      .doc(uid)
      .collection("vehicles")
      .doc(vehicleId);

    const vehicleSnapshot = await vehicleRef.get();

    if (!vehicleSnapshot.exists) {
      return res.status(404).json({
        error: "vehicle_not_found",
        message: "Vehicle was not found",
      });
    }

    req.vehicleRef = vehicleRef;
    req.vehicle = vehicleSnapshot.data();

    next();
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      error: "internal_error",
      message: error.message,
    });
  }
}

module.exports = vehicleOwnership;
```

### `src/middleware/adminApiKey.js`

Protects admin/manufacturing endpoints.

```js
function adminApiKey(req, res, next) {
  const apiKey = req.headers["x-admin-api-key"];

  if (!process.env.ADMIN_API_KEY) {
    return res.status(500).json({
      error: "admin_api_key_not_configured",
      message: "ADMIN_API_KEY is not configured",
    });
  }

  if (!apiKey || apiKey !== process.env.ADMIN_API_KEY) {
    return res.status(401).json({
      error: "unauthorized",
      message: "Invalid admin API key",
    });
  }

  next();
}

module.exports = adminApiKey;
```

---

## Validators

### `src/validators/ingestValidator.js`

```js
const Joi = require("joi");

const ingestSchema = Joi.object({
  imei: Joi.string().pattern(/^\d{14,17}$/).required(),
  lat: Joi.number().min(-90).max(90).required(),
  lng: Joi.number().min(-180).max(180).required(),
  speed: Joi.number().min(0).required(),
  battery: Joi.number().integer().min(0).max(100).required(),
  datetime: Joi.string().isoDate().required(),
  ts: Joi.number().integer().min(0).required(),
});

function validateIngestPayload(req, res, next) {
  const { error, value } = ingestSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).json({
      error: "Invalid payload",
      details: error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      })),
    });
  }

  req.body = value;
  next();
}

module.exports = validateIngestPayload;
```

### `src/validators/trackerValidator.js`

```js
const Joi = require("joi");

const imeiSchema = Joi.object({
  imei: Joi.string()
    .pattern(/^\d{15}$/)
    .required()
    .messages({
      "string.pattern.base": "IMEI must be exactly 15 digits",
      "any.required": "IMEI is required",
    }),
});

function validateImeiPayload(req, res, next) {
  const { error, value } = imeiSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).json({
      error: "invalid_imei",
      details: error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      })),
    });
  }

  req.body = value;
  next();
}

module.exports = { validateImeiPayload };
```

### `src/validators/vehicleValidator.js`

```js
const Joi = require("joi");

const vehicleParamsSchema = Joi.object({
  vehicleId: Joi.string()
    .guid({ version: ["uuidv4"] })
    .required()
    .messages({
      "string.guid": "vehicleId must be a valid UUID",
      "any.required": "vehicleId is required",
    }),
});

function validateVehicleParams(req, res, next) {
  const { error, value } = vehicleParamsSchema.validate(req.params, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).json({
      error: "invalid_vehicle_id",
      details: error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      })),
    });
  }

  req.params = value;
  next();
}

module.exports = { validateVehicleParams };
```

### `src/validators/registryValidator.js`

```js
const Joi = require("joi");

const trackerRegisterSchema = Joi.object({
  imei: Joi.string().pattern(/^\d{15}$/).required(),
  model: Joi.string().min(2).max(50).required(),
  provider: Joi.string().min(2).max(50).required(),
  firmware: Joi.string().min(1).max(30).default("unknown"),
  manufacturedAt: Joi.string().isoDate().optional(),
});

function validateTrackerRegisterPayload(req, res, next) {
  const { error, value } = trackerRegisterSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).json({
      error: "invalid_tracker_registration",
      details: error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      })),
    });
  }

  req.body = value;
  next();
}

module.exports = { validateTrackerRegisterPayload };
```

---

## Routes

### `src/routes/ingest.js`

Responsibilities:

- Accept ESP32 telemetry.
- Update runtime telemetry only.
- Does not update inventory/ownership.

Updates:

```text
trackers_live/{imei}
trackers_status/{imei}
trackers_info/{imei}
trackers_history/{imei}/{date}
```

### `src/routes/trackers.js`

Responsibilities:

- Register tracker in inventory using admin API key.
- Validate tracker against `trackers_registry`.
- Return availability to Flutter.

Endpoints:

```http
POST /api/v1/trackers/register
POST /api/v1/trackers/validate
```

### `src/routes/vehicles.js`

Responsibilities:

- Link registered tracker to a vehicle.
- Unlink tracker from a vehicle.
- Update both RTDB and Firestore.

Endpoints:

```http
POST /api/v1/vehicles/:vehicleId/link
POST /api/v1/vehicles/:vehicleId/unlink
```

---

## Current Endpoints

### Public / operational

```http
GET /
GET /health
GET /version
```

### Device ingest

```http
POST /api/v1/ingest
POST /ingest
```

### Flutter authenticated endpoints

```http
POST /api/v1/trackers/validate
POST /api/v1/vehicles/:vehicleId/link
POST /api/v1/vehicles/:vehicleId/unlink
```

### Admin endpoint

```http
POST /api/v1/trackers/register
```

---

## Firebase Data Model

### Realtime Database

```text
trackers_registry/{imei}
trackers_live/{imei}
trackers_status/{imei}
trackers_info/{imei}
trackers_history/{imei}/{date}
users/{uid}/devices/{imei}
```

### Firestore

```text
users/{uid}/vehicles/{vehicleId}
```

### Registry example

```json
{
  "imei": "864643060618008",
  "model": "SIM7670",
  "provider": "Telcel",
  "firmware": "1.0.0",
  "manufacturedAt": "2026-07-03T00:00:00Z",
  "registeredAt": "2026-07-03T00:00:00Z",
  "status": "available",
  "ownerId": null,
  "linkedAt": null
}
```

On link:

```json
{
  "status": "linked",
  "ownerId": "<uid>",
  "linkedAt": "<ISO timestamp>"
}
```

On unlink:

```json
{
  "status": "available",
  "ownerId": null,
  "linkedAt": null
}
```

---

## RTDB Security Rules

Recommended rules:

```json
{
  "rules": {
    "trackers_live": {
      "$imei": {
        ".read": "auth != null && root.child('users').child(auth.uid).child('devices').child($imei).val() === true",
        ".write": false
      }
    },
    "trackers_status": {
      "$imei": {
        ".read": "auth != null && root.child('users').child(auth.uid).child('devices').child($imei).val() === true",
        ".write": false
      }
    },
    "trackers_info": {
      "$imei": {
        ".read": "auth != null && root.child('users').child(auth.uid).child('devices').child($imei).val() === true",
        ".write": false
      }
    },
    "trackers_history": {
      "$imei": {
        ".read": "auth != null && root.child('users').child(auth.uid).child('devices').child($imei).val() === true",
        ".write": false
      }
    },
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": false
      }
    },
    ".read": false,
    ".write": false
  }
}
```

Backend Admin SDK bypasses these rules.

---

## Test Commands

### Health

```bash
curl https://dev.dt-tracker.com/health
```

### Register tracker

```bash
ADMIN_API_KEY="YOUR_DEV_ADMIN_KEY"

curl -X POST "https://dev.dt-tracker.com/api/v1/trackers/register" \
  -H "x-admin-api-key: $ADMIN_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "imei": "864643060618008",
    "model": "SIM7670",
    "provider": "Telcel",
    "firmware": "1.0.0",
    "manufacturedAt": "2026-07-03T00:00:00Z"
  }'
```

### Validate tracker

```bash
TOKEN="FIREBASE_ID_TOKEN"
IMEI="864643060618008"

curl -X POST "https://dev.dt-tracker.com/api/v1/trackers/validate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"imei\":\"$IMEI\"}"
```

### Link tracker

```bash
VEHICLE_ID="df25934b-c7fd-4581-8640-c2384e3e7d5d"

curl -X POST "https://dev.dt-tracker.com/api/v1/vehicles/$VEHICLE_ID/link" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"imei\":\"$IMEI\"}"
```

### Unlink tracker

```bash
curl -X POST "https://dev.dt-tracker.com/api/v1/vehicles/$VEHICLE_ID/unlink" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Deployment

### Dev

```bash
cd /home/ubuntu/DT-Tracker-Backend
git pull
npm install
pm2 restart dt-tracker-dev --update-env
```

### Staging

```bash
pm2 restart dt-tracker-staging --update-env
```

### Prod

```bash
pm2 restart dt-tracker-prod --update-env
pm2 save
```

---

## Add a New Endpoint

1. Create validator if needed:

```bash
nano src/validators/exampleValidator.js
```

2. Create route:

```bash
nano src/routes/example.js
```

3. Use middleware pipeline:

```js
router.post(
  "/example",
  authMiddleware,
  validateExamplePayload,
  async (req, res) => {
    return res.json({ ok: true });
  }
);
```

4. Register in `server.js`:

```js
const exampleRoute = require("./src/routes/example");
app.use("/api/v1/example", exampleRoute);
```

5. Restart dev:

```bash
pm2 restart dt-tracker-dev --update-env
```

6. Test, then promote staging/prod.

---

## Add a New Environment

1. Create RTDB instance.
2. Create Firestore database.
3. Create `.env.<env>`.
4. Add PM2 app in `ecosystem.config.js`.
5. Add Nginx server block.
6. Add DNS record.
7. Run Certbot.
8. Start PM2 process.
9. Test `/health` and `/version`.

Example `.env.qa`:

```env
PORT=3003
FIREBASE_DB_URL=https://dttracker-qa-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-qa
ADMIN_API_KEY=<secret-qa-key>
```

---

## Troubleshooting

### 401 Unauthorized

Use exactly one space:

```bash
-H "Authorization: Bearer $TOKEN"
```

Not:

```bash
-H "Authorization: Bearer  $TOKEN"
```

### Firestore `5 NOT_FOUND`

Verify `FIRESTORE_DATABASE_ID` and database existence.

```bash
NODE_ENV=dev node -e "require('dotenv').config({path:'.env.dev'}); const {firestore}=require('./firebase'); firestore.collection('users').limit(1).get().then(s=>{console.log('Firestore OK docs:',s.size); process.exit(0)}).catch(e=>{console.error('Firestore ERROR:',e.message); process.exit(1)})"
```

### `vehicle_not_found`

Expected Firestore path:

```text
users/{uid}/vehicles/{vehicleId}
```

### `tracker_not_found`

Tracker is missing from:

```text
trackers_registry/{imei}
```

### `tracker_not_available`

Tracker exists but is not available.

---

## Pending Backend Phases

Remember these for later:

1. Request IDs and correlation logs.
2. Centralized error handling.
3. Rate limiting.
4. OpenAPI / Swagger integration.
5. CI/CD with GitHub Actions.
6. Monitoring and metrics.
7. Per-device authentication for ESP32 ingest.
8. Service layer.
9. Repository layer.
10. Tests with Jest.
11. Swagger UI or generated API docs.

---

## Flutter Integration Next

Flutter should migrate link/unlink/validate to backend:

```text
POST /trackers/validate
POST /vehicles/:vehicleId/link
POST /vehicles/:vehicleId/unlink
```

Each request must include:

```http
Authorization: Bearer <Firebase ID Token>
```

Flutter can continue reading RTDB live/status/history directly, but strict rules require:

```text
users/{uid}/devices/{imei} = true
```

which is created by the backend link endpoint.
