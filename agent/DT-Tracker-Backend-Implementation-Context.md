# DT Tracker Backend Implementation Context

> Internal engineering / Confluence-style documentation for DT Tracker backend.
>
> This document explains the current backend implementation, infrastructure, environment setup, Firebase integration, security model, endpoint patterns, and step-by-step instructions to maintain or extend the backend.

---

## 1. Project Overview

DT Tracker is an IoT GPS tracking platform.

The current system receives GPS telemetry from an ESP32-S3 + SIM7670 device and stores that data in Firebase.

### High-level architecture

```text
ESP32-S3 + SIM7670
        |
        | HTTPS POST /api/v1/ingest
        v
Nginx on AWS EC2
        |
        | reverse proxy by hostname
        v
Node.js / Express Backend
        |
        | Firebase Admin SDK
        v
Firebase
   ├── Realtime Database
   └── Firestore
```

The ESP32 does **not** write directly to Firebase. All device writes go through the backend.

---

## 2. Current Environments

| Environment | Public URL | PM2 Process | Internal Port | Env File |
|---|---|---|---|---|
| Development | `https://dev.dt-tracker.com` | `dt-tracker-dev` | `3001` | `.env.dev` |
| Staging | `https://staging.dt-tracker.com` | `dt-tracker-staging` | `3002` | `.env.staging` |
| Production | `https://api.dt-tracker.com` | `dt-tracker-prod` | `3000` | `.env.prod` |

---

## 3. AWS / EC2 Setup

### Main backend folder

```bash
/home/ubuntu/DT-Tracker-Backend
```

### Secrets folder

```bash
/home/ubuntu/secrets
```

### Firebase service account

```bash
/home/ubuntu/secrets/serviceAccountKey.json
```

### Nginx configuration

```bash
/etc/nginx/sites-enabled/dt-tracker
```

### PM2 process list

```text
dt-tracker-dev
dt-tracker-staging
dt-tracker-prod
```

---

## 4. DNS

The following DNS records point to the same EC2 public IP:

```text
api.dt-tracker.com      -> EC2 public IP
dev.dt-tracker.com      -> EC2 public IP
staging.dt-tracker.com  -> EC2 public IP
```

Nginx decides which backend process receives the request based on the domain.

---

## 5. Nginx Routing

```nginx
server {
    server_name api.dt-tracker.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    server_name dev.dt-tracker.com;

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}

server {
    server_name staging.dt-tracker.com;

    location / {
        proxy_pass http://127.0.0.1:3002;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

After editing Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 6. HTTPS / Certbot

Certificates are managed with Certbot.

```bash
sudo certbot --nginx \
  -d api.dt-tracker.com \
  -d dev.dt-tracker.com \
  -d staging.dt-tracker.com
```

Verify HTTPS:

```bash
curl https://api.dt-tracker.com/health
curl https://dev.dt-tracker.com/health
curl https://staging.dt-tracker.com/health
```

---

## 7. PM2 Configuration

### File

```bash
ecosystem.config.js
```

### Content

```js
module.exports = {
  apps: [
    {
      name: "dt-tracker-prod",
      script: "server.js",
      cwd: "/home/ubuntu/DT-Tracker-Backend",
      env: {
        NODE_ENV: "prod"
      }
    },
    {
      name: "dt-tracker-dev",
      script: "server.js",
      cwd: "/home/ubuntu/DT-Tracker-Backend",
      env: {
        NODE_ENV: "dev"
      }
    },
    {
      name: "dt-tracker-staging",
      script: "server.js",
      cwd: "/home/ubuntu/DT-Tracker-Backend",
      env: {
        NODE_ENV: "staging"
      }
    }
  ]
};
```

### Useful commands

```bash
pm2 list
pm2 logs dt-tracker-dev --lines 50
pm2 logs dt-tracker-staging --lines 50
pm2 logs dt-tracker-prod --lines 50

pm2 restart dt-tracker-dev --update-env
pm2 restart dt-tracker-staging --update-env
pm2 restart dt-tracker-prod --update-env

pm2 save
pm2 startup
```

---

## 8. Environment Files

Environment files are not committed to Git.

### `.env.dev`

```env
PORT=3001
FIREBASE_DB_URL=https://dttracker-dev-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-dev
```

### `.env.staging`

```env
PORT=3002
FIREBASE_DB_URL=https://dttracker-staging-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-staging
```

### `.env.prod`

```env
PORT=3000
FIREBASE_DB_URL=https://dttracker-prod-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-prod
```

---

## 9. Firebase Architecture

The project currently uses **one Firebase project** with multiple environment-specific databases.

### Realtime Database

```text
dttracker-dev-01
dttracker-staging-01
dttracker-prod-01
```

Selected by:

```env
FIREBASE_DB_URL=
```

### Firestore

```text
dttracker-dev
dttracker-staging
dttracker-prod
```

Selected by:

```env
FIRESTORE_DATABASE_ID=
```

---

## 10. Firebase Admin SDK Setup

### File

```bash
firebase.js
```

### Content

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

### Verify Firestore access

```bash
NODE_ENV=dev node -e "require('dotenv').config({path:'.env.dev'}); const {firestore}=require('./firebase'); firestore.collection('users').limit(1).get().then(s=>{console.log('Firestore OK docs:',s.size); process.exit(0)}).catch(e=>{console.error('Firestore ERROR:',e.message); process.exit(1)})"
```

Expected:

```text
Firestore OK docs: 0
```

or:

```text
Firestore OK docs: 1
```


---

## 11. Libraries

Current runtime and major dependencies:

- Node.js
- Express
- Firebase Admin SDK
- dotenv
- Joi
- PM2
- Nginx
- Certbot

### `package.json`

```json
{
  "name": "dt-tracker-backend",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "dotenv": "^17.4.2",
    "express": "^5.2.1",
    "firebase-admin": "^13.9.0",
    "joi": "^18.0.2"
  }
}
```

---

## 12. Project Structure

```text
DT-Tracker-Backend/
├── ecosystem.config.js
├── firebase.js
├── package.json
├── package-lock.json
├── server.js
├── src/
│   ├── middleware/
│   │   ├── authMiddleware.js
│   │   └── vehicleOwnership.js
│   ├── routes/
│   │   ├── ingest.js
│   │   ├── trackers.js
│   │   └── vehicles.js
│   └── validators/
│       ├── ingestValidator.js
│       ├── trackerValidator.js
│       └── vehicleValidator.js
```

---

## 13. Express Server

### File

```bash
server.js
```

### Content

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

    console.log(
      JSON.stringify({
        timestamp: new Date().toISOString(),
        env,
        method: req.method,
        path: req.originalUrl,
        status: res.statusCode,
        durationMs: duration,
        imei: req.body?.imei || null,
        ip: req.headers["x-forwarded-for"] || req.socket.remoteAddress,
        userAgent: req.headers["user-agent"] || null,
      })
    );
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

// Legacy route for existing firmware
app.use("/ingest", ingestRoute);

// Versioned routes
app.use("/api/v1/ingest", ingestRoute);
app.use("/api/v1/trackers", trackersRoute);
app.use("/api/v1/vehicles", vehiclesRoute);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

---

## 14. Middleware

### 14.1 Firebase Auth Middleware

#### File

```bash
src/middleware/authMiddleware.js
```

#### Content

```js
const { admin } = require("../../firebase");

async function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization || "";

  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice(7)
    : null;

  if (!token) {
    return res.status(401).json({
      error: "unauthorized",
      message: "Missing Firebase ID token",
    });
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);

    req.user = {
      uid: decoded.uid,
      email: decoded.email || null,
    };

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

### 14.2 Vehicle Ownership Middleware

#### File

```bash
src/middleware/vehicleOwnership.js
```

#### Content

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

---

## 15. Validators

### 15.1 Ingest Validator

#### File

```bash
src/validators/ingestValidator.js
```

#### Content

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

### 15.2 Tracker Validator

#### File

```bash
src/validators/trackerValidator.js
```

#### Content

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

module.exports = {
  validateImeiPayload,
};
```

### 15.3 Vehicle Validator

#### File

```bash
src/validators/vehicleValidator.js
```

#### Content

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

module.exports = {
  validateVehicleParams,
};
```


---

## 16. Routes

### 16.1 Ingest Route

#### Endpoint

```http
POST /api/v1/ingest
```

Legacy:

```http
POST /ingest
```

#### File

```bash
src/routes/ingest.js
```

#### Content

```js
const express = require("express");
const router = express.Router();

const { db } = require("../../firebase");
const validateIngestPayload = require("../validators/ingestValidator");

router.post("/", validateIngestPayload, async (req, res) => {
  try {
    const {
      imei,
      lat,
      lng,
      speed,
      battery,
      datetime,
      ts,
    } = req.body;

    const date = datetime.substring(0, 10);

    await db.ref(`trackers_live/${imei}`).set({
      imei,
      lat,
      lng,
      speed,
      battery,
      datetime,
      ts,
      online: true,
    });

    await db.ref(`trackers_status/${imei}`).set({
      battery,
      speed,
      lastUpdate: datetime,
      online: true,
    });

    await db.ref(`trackers_info/${imei}`).update({
      imei,
      model: "SIM7670",
      provider: "Telcel",
    });

    await db.ref(`trackers_history/${imei}/${date}`).push({
      lat,
      lng,
      speed,
      battery,
      datetime,
      ts,
    });

    return res.json({
      ok: true,
    });
  } catch (err) {
    console.error(err);

    return res.status(500).json({
      error: err.message,
    });
  }
});

module.exports = router;
```

### 16.2 Trackers Route

#### Endpoint

```http
POST /api/v1/trackers/validate
```

#### File

```bash
src/routes/trackers.js
```

#### Content

```js
const express = require("express");
const router = express.Router();

const { db } = require("../../firebase");
const authMiddleware = require("../middleware/authMiddleware");
const { validateImeiPayload } = require("../validators/trackerValidator");

router.post("/validate", authMiddleware, validateImeiPayload, async (req, res) => {
  try {
    const { imei } = req.body;

    const snapshot = await db.ref(`trackers_info/${imei}`).get();

    if (!snapshot.exists()) {
      return res.status(404).json({
        error: "tracker_not_found",
        message: "Tracker was not found",
      });
    }

    const tracker = snapshot.val();
    const ownerId = tracker.ownerId || null;

    const isAvailable = !ownerId || ownerId === req.user.uid;

    return res.json({
      tracker: {
        imei,
        model: tracker.model || null,
        provider: tracker.provider || null,
        ownerId,
        linkedAt: tracker.linkedAt || null,
      },
      isAvailable,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      error: "internal_error",
      message: error.message,
    });
  }
});

module.exports = router;
```

### 16.3 Vehicles Route

#### Endpoints

```http
POST /api/v1/vehicles/:vehicleId/link
POST /api/v1/vehicles/:vehicleId/unlink
```

#### File

```bash
src/routes/vehicles.js
```

#### Content

```js
const express = require("express");
const router = express.Router();

const { admin, db } = require("../../firebase");

const authMiddleware = require("../middleware/authMiddleware");
const vehicleOwnership = require("../middleware/vehicleOwnership");
const { validateImeiPayload } = require("../validators/trackerValidator");
const { validateVehicleParams } = require("../validators/vehicleValidator");

router.post(
  "/:vehicleId/link",
  authMiddleware,
  validateVehicleParams,
  vehicleOwnership,
  validateImeiPayload,
  async (req, res) => {
    try {
      const uid = req.user.uid;
      const { vehicleId } = req.params;
      const { imei } = req.body;

      const trackerInfoRef = db.ref(`trackers_info/${imei}`);
      const trackerSnapshot = await trackerInfoRef.get();

      if (!trackerSnapshot.exists()) {
        return res.status(404).json({
          error: "tracker_not_found",
          message: "Tracker was not found",
        });
      }

      const ownerRef = db.ref(`trackers_info/${imei}/ownerId`);

      const transactionResult = await ownerRef.transaction((currentOwner) => {
        if (
          currentOwner === null ||
          currentOwner === undefined ||
          currentOwner === uid
        ) {
          return uid;
        }

        return currentOwner;
      });

      const owner = transactionResult.snapshot.val();

      if (owner !== uid) {
        return res.status(409).json({
          error: "tracker_in_use",
          message: "Tracker already belongs to another user",
        });
      }

      const nowIso = new Date().toISOString();
      const nowFirestore = admin.firestore.Timestamp.now();

      const updates = {};
      updates[`users/${uid}/devices/${imei}`] = true;
      updates[`trackers_info/${imei}/linkedAt`] = nowIso;

      await db.ref().update(updates);

      await req.vehicleRef.update({
        trackerId: imei,
        trackerLinkedAt: nowFirestore,
        updatedAt: nowFirestore,
      });

      return res.json({
        ok: true,
        vehicleId,
        imei,
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        error: "internal_error",
        message: error.message,
      });
    }
  }
);

router.post(
  "/:vehicleId/unlink",
  authMiddleware,
  validateVehicleParams,
  vehicleOwnership,
  async (req, res) => {
    try {
      const uid = req.user.uid;
      const { vehicleId } = req.params;

      const vehicle = req.vehicle;
      const trackerId = vehicle.trackerId;

      if (!trackerId) {
        return res.json({
          ok: true,
          vehicleId,
          message: "Vehicle has no linked tracker.",
        });
      }

      const ownerRef = db.ref(`trackers_info/${trackerId}/ownerId`);

      const transactionResult = await ownerRef.transaction((currentOwner) => {
        if (currentOwner === uid) {
          return null;
        }

        return currentOwner;
      });

      const owner = transactionResult.snapshot.val();

      if (owner !== null && owner !== undefined) {
        return res.status(409).json({
          error: "tracker_owner_mismatch",
          message: "Tracker belongs to another user",
        });
      }

      const updates = {};
      updates[`users/${uid}/devices/${trackerId}`] = null;
      updates[`trackers_info/${trackerId}/linkedAt`] = null;

      await db.ref().update(updates);

      await req.vehicleRef.update({
        trackerId: admin.firestore.FieldValue.delete(),
        trackerLinkedAt: admin.firestore.FieldValue.delete(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      return res.json({
        ok: true,
        vehicleId,
        trackerId,
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        error: "internal_error",
        message: error.message,
      });
    }
  }
);

module.exports = router;
```

---

## 17. Current Endpoints

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

### Authenticated app endpoints

```http
POST /api/v1/trackers/validate
POST /api/v1/vehicles/:vehicleId/link
POST /api/v1/vehicles/:vehicleId/unlink
```

---

## 18. API Authentication Model

Flutter sends:

```http
Authorization: Bearer <Firebase ID Token>
```

The backend validates the ID token using Firebase Admin SDK.

### Get token from Flutter

```dart
final token = await FirebaseAuth.instance.currentUser!.getIdToken();
print(token);
```

### Test variables

```bash
TOKEN="PASTE_REAL_TOKEN_HERE"
IMEI="864643060618008"
VEHICLE_ID="df25934b-c7fd-4581-8640-c2384e3e7d5d"
```

### Validate tracker

```bash
curl -X POST "https://dev.dt-tracker.com/api/v1/trackers/validate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"imei\":\"$IMEI\"}"
```

### Link tracker

```bash
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

## 19. Firebase Data Model

### Realtime Database

```text
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

### Tracker ownership

```text
trackers_info/{imei}/ownerId = uid
trackers_info/{imei}/linkedAt = ISO timestamp
users/{uid}/devices/{imei} = true
```

---

## 20. Recommended RTDB Rules

These rules allow only authenticated users to read trackers assigned to them.

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

## 21. Deployment Flow

### Development

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

### Production

```bash
pm2 restart dt-tracker-prod --update-env
pm2 save
```

### Verify after deployment

```bash
curl https://dev.dt-tracker.com/health
curl https://staging.dt-tracker.com/health
curl https://api.dt-tracker.com/health
```

---

## 22. How to Add a New Environment

### Step 1: Create RTDB instance

Firebase Console:

```text
Realtime Database -> Create database
```

Example:

```text
dttracker-qa-01
```

### Step 2: Create Firestore database

Firebase Console:

```text
Firestore -> Databases -> Create database
```

Example:

```text
dttracker-qa
```

### Step 3: Create `.env.qa`

```bash
nano .env.qa
```

```env
PORT=3003
FIREBASE_DB_URL=https://dttracker-qa-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-qa
```

### Step 4: Add PM2 process

```bash
nano ecosystem.config.js
```

Add:

```js
{
  name: "dt-tracker-qa",
  script: "server.js",
  cwd: "/home/ubuntu/DT-Tracker-Backend",
  env: {
    NODE_ENV: "qa"
  }
}
```

### Step 5: Add Nginx server block

```bash
sudo nano /etc/nginx/sites-enabled/dt-tracker
```

Add:

```nginx
server {
    server_name qa.dt-tracker.com;

    location / {
        proxy_pass http://127.0.0.1:3003;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

### Step 6: Add DNS record

```text
qa.dt-tracker.com -> EC2 public IP
```

### Step 7: Add HTTPS cert

```bash
sudo certbot --nginx -d qa.dt-tracker.com
```

### Step 8: Start process

```bash
pm2 start ecosystem.config.js --only dt-tracker-qa
pm2 save
```

### Step 9: Test

```bash
curl https://qa.dt-tracker.com/health
curl https://qa.dt-tracker.com/version
```

---

## 23. How to Create a New Endpoint

### Step 1: Decide endpoint

Example:

```http
GET /api/v1/vehicles/:vehicleId/status
```

### Step 2: Add validator if needed

```bash
nano src/validators/statusValidator.js
```

Example:

```js
const Joi = require("joi");

const statusParamsSchema = Joi.object({
  vehicleId: Joi.string().guid({ version: ["uuidv4"] }).required(),
});

function validateStatusParams(req, res, next) {
  const { error, value } = statusParamsSchema.validate(req.params, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).json({
      error: "invalid_params",
      details: error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      })),
    });
  }

  req.params = value;
  next();
}

module.exports = {
  validateStatusParams,
};
```

### Step 3: Add route

```bash
nano src/routes/vehicleStatus.js
```

Example:

```js
const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const vehicleOwnership = require("../middleware/vehicleOwnership");
const { validateStatusParams } = require("../validators/statusValidator");

router.get(
  "/:vehicleId/status",
  authMiddleware,
  validateStatusParams,
  vehicleOwnership,
  async (req, res) => {
    try {
      return res.json({
        ok: true,
        vehicle: req.vehicle,
      });
    } catch (error) {
      console.error(error);

      return res.status(500).json({
        error: "internal_error",
        message: error.message,
      });
    }
  }
);

module.exports = router;
```

### Step 4: Register route in `server.js`

```js
const vehicleStatusRoute = require("./src/routes/vehicleStatus");

app.use("/api/v1/vehicles", vehicleStatusRoute);
```

### Step 5: Restart dev

```bash
pm2 restart dt-tracker-dev --update-env
```

### Step 6: Test

```bash
curl -X GET "https://dev.dt-tracker.com/api/v1/vehicles/$VEHICLE_ID/status" \
  -H "Authorization: Bearer $TOKEN"
```

### Step 7: Promote after validation

```bash
pm2 restart dt-tracker-staging --update-env
pm2 restart dt-tracker-prod --update-env
pm2 save
```

---

## 24. How to Add a New Validator

### Step 1: Create file

```bash
nano src/validators/exampleValidator.js
```

### Step 2: Add Joi schema

```js
const Joi = require("joi");

const exampleSchema = Joi.object({
  name: Joi.string().min(2).max(100).required(),
});

function validateExamplePayload(req, res, next) {
  const { error, value } = exampleSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).json({
      error: "invalid_payload",
      details: error.details.map((detail) => ({
        field: detail.path.join("."),
        message: detail.message,
      })),
    });
  }

  req.body = value;
  next();
}

module.exports = {
  validateExamplePayload,
};
```

### Step 3: Use in route

```js
const { validateExamplePayload } = require("../validators/exampleValidator");

router.post(
  "/example",
  authMiddleware,
  validateExamplePayload,
  async (req, res) => {
    return res.json({ ok: true });
  }
);
```

---

## 25. Troubleshooting

### 25.1 401 Unauthorized

Cause:

- Missing token
- Expired token
- Invalid token
- Extra spaces after `Bearer`

Correct:

```bash
-H "Authorization: Bearer $TOKEN"
```

Incorrect:

```bash
-H "Authorization: Bearer  $TOKEN"
```

### 25.2 Firestore `5 NOT_FOUND`

Cause:

- Firestore database does not exist
- Wrong `FIRESTORE_DATABASE_ID`
- Backend using default Firestore database unintentionally

Verify:

```bash
NODE_ENV=dev node -e "require('dotenv').config({path:'.env.dev'}); const {firestore}=require('./firebase'); firestore.collection('users').limit(1).get().then(s=>{console.log('Firestore OK docs:',s.size); process.exit(0)}).catch(e=>{console.error('Firestore ERROR:',e.message); process.exit(1)})"
```

### 25.3 404 `vehicle_not_found`

Cause:

Backend expects:

```text
users/{uid}/vehicles/{vehicleId}
```

Verify Firestore path and document ID.

### 25.4 409 `tracker_in_use`

Cause:

```text
trackers_info/{imei}/ownerId
```

already belongs to another user.

### 25.5 ESP32 receives 301

Cause:

Device is using HTTP but Nginx redirects to HTTPS.

Solution:

Use SIM7670 native HTTPS AT commands.

---

## 26. Security Roadmap

### Completed

- HTTPS
- Firebase Admin SDK
- Secrets outside repository
- RTDB strict rules
- Firebase Auth middleware
- Vehicle ownership middleware
- Transactional tracker ownership

### Next recommended phases

#### Phase 8: Service layer

Move business logic from routes to services.

```text
src/services/trackerService.js
src/services/vehicleService.js
```

#### Phase 9: Repository layer

Move Firebase operations into repositories.

```text
src/repositories/trackerRepository.js
src/repositories/vehicleRepository.js
```

#### Phase 10: Centralized error handling

Create consistent API errors.

#### Phase 11: Device authentication

Add API keys or signed tokens for ESP32 devices.

#### Phase 12: Rate limiting

Protect endpoints from abuse.

#### Phase 13: Swagger / OpenAPI docs

Generate interactive API documentation.

#### Phase 14: Tests

Use Jest for unit and integration tests.

#### Phase 15: CI/CD

Use GitHub Actions for automatic deployment.

---

## 27. Important Notes

- Never commit `.env.*`.
- Never commit service account files.
- Always deploy to dev first.
- Use staging before production.
- Always test `/health` after deployment.
- Always use real Firebase ID tokens for protected endpoints.
- Tokens expire; refresh from Flutter if needed.
- Admin SDK bypasses RTDB rules.
- RTDB rules protect Flutter direct reads.
- Device writes must go through the backend.
- Firestore database ID must match the environment.
