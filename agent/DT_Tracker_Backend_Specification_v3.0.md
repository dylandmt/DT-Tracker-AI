# DT Tracker Backend Specification v3.0 — Backend + Flutter Integration Contract

> **Status:** Current merged implementation context
> **Primary audience:** Backend and Flutter developers / AI coding agents
> **API family:** `v1` (`/api/v1`)
> **Last updated:** August 2, 2026
> **Merged from:** Flutter integration specification + backend production-hardening v2.1

---

# 1. Purpose

This document is the implementation contract between the DT Tracker backend and the Flutter application.

It explains:

- The deployed backend architecture.
- Development, staging, and production environments.
- Firebase Authentication requirements.
- Every current endpoint used by Flutter.
- Request and response formats.
- Error handling.
- Realtime Database paths.
- Firestore collections.
- Firebase Storage paths.
- Security rules.
- Tracker registration and ownership.
- Vehicle link and unlink behavior.
- Geofence processing.
- Backend-generated events.
- Recommended Flutter Clean Architecture and BLoC mapping.
- Testing and rollout expectations.
- Current limitations and pending backend work.

This document should be used as the primary context when implementing or refactoring the Flutter application.

---

# 2. System Overview

DT Tracker is an IoT GPS tracking platform.

The system consists of:

- ESP32-S3 tracker hardware.
- SIM7670 cellular and GNSS modem.
- Node.js and Express backend.
- AWS EC2 infrastructure.
- Nginx reverse proxy.
- PM2 process manager.
- Firebase Authentication.
- Firebase Realtime Database.
- Firestore.
- Firebase Storage.
- Flutter mobile application.

## 2.1 High-level architecture

```text
ESP32-S3 + SIM7670
        |
        | HTTPS telemetry
        v
Nginx on AWS EC2
        |
        | Reverse proxy
        v
Node.js / Express backend
        |
        | Firebase Admin SDK
        +------------------------------+
        |                              |
        v                              v
Firebase Realtime Database         Firestore
        |                              |
        +---------------+--------------+
                        |
                        v
                  Flutter application
```

## 2.2 Main responsibility boundaries

### ESP32

The device:

- Obtains GNSS coordinates.
- Obtains speed.
- Reads battery level.
- Obtains device IMEI.
- Generates a device timestamp.
- Sends telemetry to `/api/v1/ingest`.
- Buffers telemetry when offline.
- Retries failed telemetry uploads.

The device does not:

- Write directly to Firebase.
- Link itself to users.
- Link itself to vehicles.
- Create geofence events.
- Manage user permissions.

### Backend

The backend:

- Validates telemetry.
- Writes live and historical tracker data.
- Verifies Firebase ID tokens.
- Registers tracker inventory.
- Validates tracker availability.
- Links and unlinks trackers.
- Enforces vehicle ownership.
- Evaluates geofences.
- Maintains geofence state.
- Generates immutable events.
- Uses Firebase Admin SDK for privileged writes.

### Flutter

The Flutter app:

- Authenticates users with Firebase Authentication.
- Obtains Firebase ID tokens.
- Calls backend endpoints for tracker validation and linking.
- Reads authorized tracker telemetry from RTDB.
- Reads and manages Firestore user data.
- Creates and edits geofence definitions.
- Reads backend-generated events.
- Marks events as read or archived.
- Uploads profile and vehicle images to Firebase Storage.

---

# 3. Environments

The platform has three isolated runtime environments.

| Environment | Backend URL | API Base URL | PM2 Process | Port |
|---|---|---|---|---:|
| Development | `https://dev.dt-tracker.com` | `https://dev.dt-tracker.com/api/v1` | `dt-tracker-dev` | 3001 |
| Staging | `https://staging.dt-tracker.com` | `https://staging.dt-tracker.com/api/v1` | `dt-tracker-staging` | 3002 |
| Production | `https://api.dt-tracker.com` | `https://api.dt-tracker.com/api/v1` | `dt-tracker-prod` | 3000 |

## 3.1 Realtime Database instances

```text
Development: dttracker-dev-01
Staging:     dttracker-staging-01
Production:  dttracker-prod-01
```

## 3.2 Firestore databases

The system uses one Firebase project with three named Firestore databases:

```text
Development: dttracker-dev
Staging:     dttracker-staging
Production:  dttracker-prod
```

## 3.3 Storage buckets

```text
Development: gs://dttracker-dev-01
Staging:     gs://dttracker-staging-01
Production:  gs://dttracker-prod-01
```

## 3.4 Backend environment variables

Typical environment file:

```env
PORT=3001
FIREBASE_DB_URL=https://dttracker-dev-01.firebaseio.com
FIRESTORE_DATABASE_ID=dttracker-dev
ADMIN_API_KEY=<secret-development-key>
```

Equivalent files exist for staging and production.

Environment files must never be committed to Git.

---

# 4. Backend Project Structure

Current runtime structure confirmed from the backend repository on August 2, 2026:

```text
DT-Tracker-Backend/
├── ecosystem.config.js
├── firebase.js
├── package.json
├── server.js
├── docs/
└── src/
    ├── app.js
    ├── middleware/
    │   ├── adminApiKey.js
    │   ├── authMiddleware.js
    │   ├── deviceAuth.js
    │   ├── errorHandler.js
    │   ├── notFoundHandler.js
    │   ├── rateLimiters.js
    │   ├── security.js
    │   └── vehicleOwnership.js
    ├── modules/
    │   ├── deviceAuth/
    │   │   ├── deviceAuth.service.js
    │   │   ├── deviceAuthHeader.js
    │   │   ├── deviceCredential.repository.js
    │   │   ├── deviceHmac.js
    │   │   └── deviceNonce.repository.js
    │   ├── events/
    │   │   └── README.md
    │   ├── geofences/
    │   │   ├── geofence.module.js
    │   │   └── README.md
    │   └── ingest/
    │       ├── ingest.constants.js
    │       ├── ingest.controller.js
    │       ├── ingest.mapper.js
    │       ├── ingest.repository.js
    │       ├── ingest.responses.js
    │       ├── ingest.service.js
    │       └── ingest.utils.js
    ├── routes/
    │   ├── health.js
    │   ├── ingest.js
    │   ├── trackers.js
    │   └── vehicles.js
    ├── services/
    │   └── geofenceService.js
    ├── shared/
    │   ├── config/
    │   │   └── env.js
    │   └── errors/
    │       └── AppError.js
    ├── utils/
    │   └── geo.js
    └── validators/
        ├── ingestBatchValidator.js
        ├── ingestValidator.js
        ├── registryValidator.js
        ├── trackerValidator.js
        └── vehicleValidator.js
```

## 4.1 Application bootstrap

`server.js` currently:

1. resolves `NODE_ENV`;
2. loads `.env.<NODE_ENV>`;
3. validates configuration through `src/shared/config/env`;
4. imports `db` and `firestore` from root-level `firebase.js`;
5. constructs device-auth repositories and services;
6. configures request IDs and structured Morgan logging;
7. injects runtime dependencies into `createApp(...)`;
8. starts the HTTP server;
9. performs graceful `SIGINT` / `SIGTERM` shutdown;
10. shuts down on unhandled rejections and uncaught exceptions.

Current dependency injection into `createApp(...)` includes:

```text
config
db
firestore
ingestRouter
trackersRouter
vehiclesRouter
requestIdMiddleware
requestLoggingMiddleware
deviceAuthService
```

## 4.2 Firebase Admin bootstrap

The root `firebase.js` initializes one Firebase Admin app using either:

```text
FIREBASE_SERVICE_ACCOUNT
```

or:

```text
FIREBASE_SERVICE_ACCOUNT_PATH
```

and requires:

```text
FIREBASE_DB_URL
FIRESTORE_DATABASE_ID
```

It currently exports:

```javascript
{
  app,
  db,
  firestore
}
```

Firebase Cloud Messaging must reuse this same initialized Admin app. The planned extension is:

```javascript
{
  app,
  db,
  firestore,
  messaging
}
```

Do not initialize a second Admin application for FCM.

## 4.3 Modular migration status

`src/modules/geofences/geofence.module.js` remains the geofence module entry point while `src/services/geofenceService.js` contains current geofence service behavior.

Flutter must not depend on backend folder structure. Flutter depends on HTTP and Firebase data contracts only.

The notification feature should follow the existing modular direction:

```text
src/modules/notifications/
├── notification.constants.js
├── notification.repository.js
└── notification.service.js
```

Additional route/controller/service files for mobile push-device registration should follow existing backend conventions after `authMiddleware.js`, `app.js`, and authenticated routes are inspected.

---

# 5. Authentication Model

## 5.1 Firebase Authentication

Flutter authenticates users through Firebase Authentication.

Protected backend requests must include:

```http
Authorization: Bearer <Firebase ID Token>
```

The backend verifies the token using Firebase Admin SDK.

## 5.2 Obtaining a token in Flutter

```dart
final user = FirebaseAuth.instance.currentUser;

if (user == null) {
  throw StateError('No authenticated Firebase user');
}

final token = await user.getIdToken();
```

Force refresh when required:

```dart
final token = await user.getIdToken(true);
```

## 5.3 Token lifetime

Firebase ID tokens expire. The Flutter network layer should obtain a current token before protected requests.

Do not store a copied ID token permanently.

## 5.4 Backend authentication errors

Missing token:

```json
{
  "error": "unauthorized",
  "message": "Missing Firebase ID token"
}
```

Expired or invalid token:

```json
{
  "error": "unauthorized",
  "message": "Firebase ID token has expired..."
}
```

or:

```json
{
  "error": "unauthorized",
  "message": "Firebase ID token has invalid signature..."
}
```

Flutter should map HTTP `401` to an authentication/session failure.

---


## 5.5 Device authentication for telemetry

Tracker telemetry does not use Firebase user authentication.

The production-hardening baseline now uses per-device HMAC-SHA256 authentication for:

```http
POST /api/v1/ingest
POST /api/v1/ingest/batch
```

Relevant backend components:

```text
src/middleware/deviceAuth.js
src/modules/deviceAuth/deviceAuth.service.js
src/modules/deviceAuth/deviceAuthHeader.js
src/modules/deviceAuth/deviceCredential.repository.js
src/modules/deviceAuth/deviceHmac.js
src/modules/deviceAuth/deviceNonce.repository.js
```

Typical device headers:

```http
x-device-imei: 864643060618008
x-device-timestamp: 1784668800
x-device-nonce: 8e6df0b2-8d52-4c23-a850-54ec6432257e
x-device-signature: <lowercase hex HMAC-SHA256>
```

Canonical signed data includes:

```text
METHOD
PATH
IMEI
TIMESTAMP
NONCE
BODY_SHA256
```

The backend enforces timestamp freshness and nonce replay protection. Device credentials and nonces are server-side and must never be exposed to Flutter.

# 6. Administrative Authentication

The tracker registration endpoint is not intended for the mobile app.

It uses:

```http
x-admin-api-key: <ADMIN_API_KEY>
```

The admin API key:

- Is different per environment.
- Is stored only in backend environment configuration.
- Must not be embedded in the Flutter app.
- Must not be committed to Git.
- Is used by internal provisioning or manufacturing tools.

---

# 7. API Conventions

## 7.1 Base path

```text
/api/v1
```

## 7.2 Content type

JSON requests should use:

```http
Content-Type: application/json
```

## 7.3 General success response

Some endpoints return:

```json
{
  "ok": true
}
```

## 7.4 General error response

Typical error:

```json
{
  "error": "error_code",
  "message": "Human-readable message"
}
```

Validation error:

```json
{
  "error": "invalid_imei",
  "details": [
    {
      "field": "imei",
      "message": "IMEI must be exactly 15 digits"
    }
  ]
}
```

## 7.5 Important HTTP statuses

| Status | Meaning |
|---:|---|
| 200 | Successful request |
| 201 | Resource created |
| 400 | Invalid request |
| 401 | Missing, expired, or invalid authentication |
| 404 | Resource not found |
| 409 | Ownership or availability conflict |
| 500 | Backend processing failure |

---

# 8. Operational Endpoints

These endpoints are not under `/api/v1`.

## 8.1 Root

```http
GET /
```

Example response:

```json
{
  "name": "DT Tracker Backend",
  "description": "GPS Tracking Backend API",
  "environment": "dev",
  "version": "1.0.0",
  "status": "UP"
}
```

## 8.2 Health

```http
GET /health
```

Example:

```json
{
  "status": "UP",
  "environment": "dev",
  "uptime": 12345.67,
  "timestamp": "2026-07-11T15:00:00.000Z"
}
```

## 8.3 Version

```http
GET /version
```

Example:

```json
{
  "version": "1.0.0",
  "node": "v22.22.1",
  "environment": "dev"
}
```

Flutter normally does not need these endpoints, except optionally for diagnostics.

---

# 9. Telemetry Ingest

Flutter does not call the telemetry ingest endpoints. They are used by tracker hardware. Flutter consumes the resulting RTDB state and backend-generated Firestore events.

## 9.1 Live ingest endpoint

```http
POST /api/v1/ingest
```

Used for low-latency live telemetry.

Representative current payload:

```json
{
  "imei": "864643060618008",
  "eventId": "864643060618008-1042",
  "sequence": 1042,
  "lat": 20.182058,
  "lng": -96.865013,
  "speed": 18.1,
  "battery": 90,
  "datetime": "2026-07-21T20:00:00Z",
  "ts": 1234567,
  "firmware": "1.5.0-dev",
  "source": "gnss"
}
```

## 9.2 Batch ingest endpoint

```http
POST /api/v1/ingest/batch
```

Batch and live ingest coexist.

Batch payload schema version is `2`; the normal target size is approximately 1–50 points.

Representative payload:

```json
{
  "schemaVersion": 2,
  "imei": "864643060618008",
  "firmware": "1.5.0-dev",
  "battery": 90,
  "points": [
    {
      "eventId": "864643060618008-1042",
      "sequence": 1042,
      "lat": 20.182058,
      "lng": -96.865013,
      "speed": 18.1,
      "datetime": "2026-07-21T20:00:00Z",
      "ts": 1234567,
      "source": "gnss"
    }
  ]
}
```

Representative success response:

```json
{
  "ok": true,
  "accepted": 1,
  "duplicates": 0,
  "acknowledgedEventIds": [
    "864643060618008-1042"
  ],
  "acknowledgedThroughSequence": 1042,
  "processingTimeMs": 18,
  "requestId": "correlation-id"
}
```

## 9.3 Device authentication

Both current ingest paths use device HMAC authentication.

Do not document ingest as anonymously writable or as pending per-device authentication.

The current security baseline includes:

```text
HMAC-SHA256
timestamp freshness
nonce replay protection
credential activation checks
request correlation IDs
ingest/global rate limiting
```

## 9.4 Validation

Representative ingest rules include:

| Field | Type | Rules |
|---|---|---|
| `imei` | string | validated device IMEI |
| `eventId` | string | telemetry idempotency key |
| `sequence` | integer | ordered acknowledgement |
| `lat` | number | -90 to 90 |
| `lng` | number | -180 to 180 |
| `speed` | number | 0 or greater |
| `battery` | integer | 0–100 |
| `datetime` | ISO-8601 string | required |
| `ts` | integer | non-negative |
| `firmware` | string | supported metadata |
| `source` | string | telemetry source when present |

The exact Joi schemas in `ingestValidator.js` and `ingestBatchValidator.js` remain authoritative.

## 9.5 Persistence side effects

The current ingest pipeline writes tracker state/history to RTDB, including:

```text
trackers_live/{imei}
trackers_status/{imei}
trackers_info/{imei}
trackers_history/{imei}/{YYYY-MM-DD}/{eventId}
```

It then evaluates geofences.

## 9.6 Deduplication and acknowledgements

Current rules:

- `eventId` is the telemetry idempotency key.
- `sequence` provides ordered acknowledgement.
- Existing event IDs count as duplicates.
- Partial duplicates do not invalidate an otherwise valid batch.
- Failed writes must never be acknowledged.
- Firmware deletes only acknowledged records.

## 9.7 Failure isolation

Geofence evaluation is isolated from otherwise successful telemetry persistence.

If geofence evaluation fails after valid telemetry persistence:

```text
telemetry = valid
geofence evaluation = failed
ingest response = should remain successful
```

The same principle applies to FCM. A notification failure must never turn valid telemetry into an ingest failure.

## 9.8 Firmware relevance

The push-notification feature does not require a firmware protocol change.

The device continues to send telemetry through live and batch ingest. Geofence transition detection and notification delivery remain backend responsibilities.

---

# 10. Tracker Registration Endpoint

## 10.1 Endpoint

```http
POST /api/v1/trackers/register
```

## 10.2 Authentication

```http
x-admin-api-key: <ADMIN_API_KEY>
```

Not for Flutter.

## 10.3 Request

```json
{
  "imei": "864643060618008",
  "model": "SIM7670",
  "provider": "Telcel",
  "firmware": "1.0.0",
  "manufacturedAt": "2026-07-03T00:00:00Z"
}
```

## 10.4 Validation

| Field | Requirement |
|---|---|
| `imei` | Exactly 15 digits |
| `model` | Required string, 2–50 chars |
| `provider` | Required string, 2–50 chars |
| `firmware` | Optional, default `unknown` |
| `manufacturedAt` | Optional ISO date |

## 10.5 Success

HTTP `201`:

```json
{
  "ok": true,
  "tracker": {
    "imei": "864643060618008",
    "model": "SIM7670",
    "provider": "Telcel",
    "firmware": "1.0.0",
    "manufacturedAt": "2026-07-03T00:00:00Z",
    "registeredAt": "2026-07-03T00:00:00.000Z",
    "status": "available",
    "ownerId": null,
    "vehicleId": null,
    "linkedAt": null
  }
}
```

## 10.6 Errors

Tracker already exists:

```json
{
  "error": "tracker_already_registered",
  "message": "Tracker is already registered"
}
```

Invalid admin key:

```json
{
  "error": "unauthorized",
  "message": "Invalid admin API key"
}
```

---

# 11. Tracker Validation Endpoint

This is the first tracker endpoint used by Flutter.

## 11.1 Endpoint

```http
POST /api/v1/trackers/validate
```

## 11.2 Authentication

Firebase ID token required.

```http
Authorization: Bearer <Firebase ID Token>
```

## 11.3 Request

```json
{
  "imei": "864643060618008"
}
```

## 11.4 IMEI validation

The IMEI must contain exactly 15 digits.

## 11.5 Success response

Representative response:

```json
{
  "tracker": {
    "imei": "864643060618008",
    "model": "SIM7670",
    "provider": "Telcel",
    "firmware": "1.0.0",
    "status": "available",
    "ownerId": null,
    "vehicleId": null,
    "linkedAt": null
  },
  "isAvailable": true
}
```

## 11.6 Availability meaning

A tracker is available when it is registered and not owned by another user.

Possible situations:

| Registry state | Result |
|---|---|
| No registry entry | `404 tracker_not_found` |
| `status = available`, no owner | available |
| Already owned by current user | implementation may treat idempotently |
| Owned by another user | unavailable/conflict |

## 11.7 Errors

Invalid IMEI:

```json
{
  "error": "invalid_imei",
  "details": [
    {
      "field": "imei",
      "message": "IMEI must be exactly 15 digits"
    }
  ]
}
```

Tracker not registered:

```json
{
  "error": "tracker_not_found",
  "message": "Tracker is not registered"
}
```

Unauthorized:

```json
{
  "error": "unauthorized",
  "message": "Missing Firebase ID token"
}
```

---

# 12. Link Tracker to Vehicle

## 12.1 Endpoint

```http
POST /api/v1/vehicles/{vehicleId}/link
```

## 12.2 Authentication

Firebase ID token required.

## 12.3 Path parameter

`vehicleId` must be a valid UUID.

Example:

```text
df25934b-c7fd-4581-8640-c2384e3e7d5d
```

## 12.4 Request

```json
{
  "imei": "864643060618008"
}
```

## 12.5 Backend flow

1. Verify Firebase ID token.
2. Extract `uid`.
3. Validate `vehicleId`.
4. Validate IMEI.
5. Read Firestore vehicle:

```text
users/{uid}/vehicles/{vehicleId}
```

6. Return `404` if the user does not own that vehicle.
7. Read tracker registry:

```text
trackers_registry/{imei}
```

8. Verify the tracker exists.
9. Claim ownership using an RTDB transaction.
10. Update RTDB:

```text
users/{uid}/devices/{imei} = true
trackers_registry/{imei}/ownerId = uid
trackers_registry/{imei}/vehicleId = vehicleId
trackers_registry/{imei}/status = linked
trackers_registry/{imei}/linkedAt = ISO timestamp
```

11. Update Firestore vehicle:

```text
users/{uid}/vehicles/{vehicleId}
```

Typical fields:

```text
trackerId
trackerLinkedAt
updatedAt
```

## 12.6 Success

```json
{
  "ok": true,
  "vehicleId": "df25934b-c7fd-4581-8640-c2384e3e7d5d",
  "imei": "864643060618008"
}
```

## 12.7 Errors

Vehicle not found:

```json
{
  "error": "vehicle_not_found",
  "message": "Vehicle was not found"
}
```

Tracker not found:

```json
{
  "error": "tracker_not_found",
  "message": "Tracker is not registered"
}
```

Tracker already used by another user:

```json
{
  "error": "tracker_in_use",
  "message": "Tracker is already linked to another user"
}
```

Tracker not available:

```json
{
  "error": "tracker_not_available",
  "message": "Tracker is not available for linking"
}
```

---

# 13. Unlink Tracker from Vehicle

## 13.1 Endpoint

```http
POST /api/v1/vehicles/{vehicleId}/unlink
```

## 13.2 Authentication

Firebase ID token required.

## 13.3 Request body

No request body is required.

## 13.4 Backend flow

1. Verify Firebase ID token.
2. Validate vehicle ID.
3. Verify vehicle ownership.
4. Read `trackerId` from the Firestore vehicle.
5. If no tracker is linked, return idempotent success.
6. Verify registry ownership.
7. Remove RTDB authorization mapping:

```text
users/{uid}/devices/{trackerId}
```

8. Reset tracker registry:

```text
status = available
ownerId = null
vehicleId = null
linkedAt = null
```

9. Remove Firestore vehicle tracker fields:

```text
trackerId
trackerLinkedAt
```

10. Update `updatedAt`.

## 13.5 Success

Representative response:

```json
{
  "ok": true,
  "vehicleId": "df25934b-c7fd-4581-8640-c2384e3e7d5d",
  "trackerId": "864643060618008"
}
```

Idempotent success may include:

```json
{
  "ok": true,
  "vehicleId": "df25934b-c7fd-4581-8640-c2384e3e7d5d",
  "message": "Vehicle has no linked tracker."
}
```

## 13.6 Errors

Vehicle not found:

```json
{
  "error": "vehicle_not_found",
  "message": "Vehicle was not found"
}
```

Owner mismatch:

```json
{
  "error": "tracker_owner_mismatch",
  "message": "Tracker belongs to another user"
}
```

---

# 14. Realtime Database Data Model

## 14.1 Tracker registry

```text
trackers_registry/{imei}
```

Example:

```json
{
  "imei": "864643060618008",
  "model": "SIM7670",
  "provider": "Telcel",
  "firmware": "1.0.0",
  "manufacturedAt": "2026-07-03T00:00:00Z",
  "registeredAt": "2026-07-03T00:00:00Z",
  "status": "linked",
  "ownerId": "USER_UID",
  "vehicleId": "VEHICLE_UUID",
  "linkedAt": "2026-07-10T23:30:00.000Z"
}
```

This is the source of truth for:

- Tracker inventory.
- Tracker owner.
- Linked vehicle.
- Tracker lifecycle status.
- Link timestamp.

Flutter should not directly modify this path.

## 14.2 Live tracker data

```text
trackers_live/{imei}
```

Example:

```json
{
  "imei": "864643060618008",
  "lat": 20.182058,
  "lng": -96.865013,
  "speed": 18.1,
  "battery": 100,
  "datetime": "2026-07-11T18:05:00Z",
  "ts": 1000000,
  "online": true
}
```

Flutter can observe this path after the tracker is linked to the user.

## 14.3 Tracker status

```text
trackers_status/{imei}
```

Example:

```json
{
  "battery": 100,
  "speed": 18.1,
  "lastUpdate": "2026-07-11T18:05:00Z",
  "online": true
}
```

## 14.4 Runtime tracker metadata

```text
trackers_info/{imei}
```

Example:

```json
{
  "imei": "864643060618008",
  "lastSeen": "2026-07-11T18:05:02.000Z",
  "lastDeviceDatetime": "2026-07-11T18:05:00Z",
  "lastTs": 1000000
}
```

This path is runtime metadata only.

Ownership belongs in `trackers_registry`, not `trackers_info`.

## 14.5 Tracker history

```text
trackers_history/{imei}/{YYYY-MM-DD}/{pushId}
```

Example:

```json
{
  "lat": 20.182058,
  "lng": -96.865013,
  "speed": 18.1,
  "battery": 100,
  "datetime": "2026-07-11T18:05:00Z",
  "ts": 1000000
}
```

## 14.6 User device authorization mapping

```text
users/{uid}/devices/{imei} = true
```

This mapping is created by the backend link endpoint.

It is removed by the unlink endpoint.

It is used by RTDB security rules to determine whether the authenticated user may read a tracker.

---

# 15. RTDB Security Rules

Recommended current rules:

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
    "trackers_registry": {
      "$imei": {
        ".read": false,
        ".write": false
      }
    },
    ".read": false,
    ".write": false
  }
}
```

## 15.1 Flutter implications

Flutter may:

- Read linked tracker live data.
- Read linked tracker status.
- Read linked tracker metadata.
- Read linked tracker history.
- Read its own device authorization mapping.

Flutter may not:

- Write tracker telemetry.
- Write ownership.
- Write registry entries.
- Create user-device mappings.

The Firebase Admin SDK bypasses RTDB rules.

---

# 16. Firestore Data Model

All paths below belong to the named Firestore database for the active environment.

## 16.1 User document

```text
users/{uid}
```

Contains profile and settings.

Example settings:

```json
{
  "settings": {
    "geofenceAlertEnabled": true
  }
}
```

## 16.2 Vehicles

```text
users/{uid}/vehicles/{vehicleId}
```

Representative tracker fields:

```json
{
  "trackerId": "864643060618008",
  "trackerLinkedAt": "Firestore Timestamp",
  "updatedAt": "Firestore Timestamp"
}
```

Vehicle-specific application fields may include name, make, model, year, image URL, and other UI data.

## 16.3 Geofence definitions

```text
users/{uid}/geofences/{geofenceId}
```

Example:

```json
{
  "name": "Home",
  "center": {
    "latitude": 20.182058,
    "longitude": -96.865013
  },
  "radiusMeters": 500,
  "vehicleIds": [
    "df25934b-c7fd-4581-8640-c2384e3e7d5d"
  ],
  "triggerOnEnter": true,
  "triggerOnExit": true,
  "isActive": true,
  "createdAt": "Firestore Timestamp",
  "updatedAt": "Firestore Timestamp"
}
```

Flutter creates and manages geofence definitions directly in Firestore.

## 16.4 Geofence state

```text
users/{uid}/geofence_states/{vehicleId}_{geofenceId}
```

Example:

```json
{
  "vehicleId": "df25934b-c7fd-4581-8640-c2384e3e7d5d",
  "geofenceId": "test-home",
  "isInside": true,
  "lastPositionAt": "Firestore Timestamp",
  "updatedAt": "Firestore Timestamp"
}
```

Backend-owned.

Flutter may read it, but must not write it.

## 16.5 Events

```text
users/{uid}/events/{eventId}
```

Example:

```json
{
  "version": 1,
  "source": "backend",
  "type": "geofence_enter",
  "category": "geofence",
  "severity": "info",
  "status": "new",
  "isRead": false,
  "vehicleId": "df25934b-c7fd-4581-8640-c2384e3e7d5d",
  "trackerId": "864643060618008",
  "title": "Geofence entered",
  "message": "Vehicle entered Test Home",
  "occurredAt": "Firestore Timestamp",
  "createdAt": "Firestore Timestamp",
  "location": {
    "latitude": 20.182058,
    "longitude": -96.865013
  },
  "metadata": {
    "geofenceId": "test-home",
    "geofenceName": "Test Home",
    "radiusMeters": 500,
    "distanceMeters": 0,
    "previousIsInside": false,
    "currentIsInside": true
  }
}
```

Current event types:

```text
geofence_enter
geofence_exit
```

---


## 16.6 Mobile push-device registrations — new

FCM mobile registrations belong in Firestore:

```text
users/{uid}/devices/{mobileInstallationId}
```

This is distinct from the RTDB tracker authorization mapping:

```text
RTDB users/{uid}/devices/{imei} = true
```

The two paths share the word `devices` but represent different domains:

```text
RTDB users/{uid}/devices/{imei}
-> physical tracker read authorization

Firestore users/{uid}/devices/{mobileInstallationId}
-> installed Flutter application / FCM registration
```

Recommended Firestore mobile-device document:

```json
{
  "platform": "android",
  "pushToken": "<FCM token>",
  "pushEnabled": true,
  "appVersion": "<optional>",
  "createdAt": "Firestore Timestamp",
  "updatedAt": "Firestore Timestamp",
  "lastSeenAt": "Firestore Timestamp"
}
```

Rules:

- `mobileInstallationId` is persistent for the app installation.
- FCM token rotation updates the same mobile installation document.
- Multiple mobile devices per user are supported.
- Full production FCM tokens must not be logged.
- Do not store one global `fcmToken` directly in `users/{uid}`.

This document is intended to be written through an authenticated backend endpoint, not by trusting a client-provided UID.

# 17. Firestore Security Rules

Current recommended full rule structure:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return isAuthenticated()
        && request.auth.uid == uid;
    }

    match /users/{uid} {
      allow read, create, update: if isOwner(uid);
      allow delete: if false;
    }

    match /users/{uid}/vehicles/{vehicleId} {
      allow read, create, update, delete: if isOwner(uid);
    }

    match /users/{uid}/geofences/{geofenceId} {
      allow read: if isOwner(uid);

      allow create: if isOwner(uid)
        && isValidGeofence();

      allow update: if isOwner(uid)
        && isValidGeofence();

      allow delete: if isOwner(uid);
    }

    match /users/{uid}/geofence_states/{stateId} {
      allow read: if isOwner(uid);
      allow create, update, delete: if false;
    }

    match /users/{uid}/events/{eventId} {
      allow read: if isOwner(uid);

      allow update: if isOwner(uid)
        && request.resource.data
          .diff(resource.data)
          .affectedKeys()
          .hasOnly(["isRead", "status"])
        && request.resource.data.isRead is bool
        && request.resource.data.status is string
        && request.resource.data.status in [
          "new",
          "read",
          "archived"
        ];

      allow create, delete: if false;
    }

    match /{document=**} {
      allow read, write: if false;
    }

    function isValidGeofence() {
      return request.resource.data.keys().hasAll([
          "name",
          "center",
          "radiusMeters",
          "vehicleIds",
          "triggerOnEnter",
          "triggerOnExit",
          "isActive"
        ])
        && request.resource.data.keys().hasOnly([
          "name",
          "center",
          "radiusMeters",
          "vehicleIds",
          "triggerOnEnter",
          "triggerOnExit",
          "isActive",
          "createdAt",
          "updatedAt"
        ])
        && request.resource.data.name is string
        && request.resource.data.name.size() >= 1
        && request.resource.data.name.size() <= 100
        && request.resource.data.center is map
        && request.resource.data.center.keys().hasAll([
          "latitude",
          "longitude"
        ])
        && request.resource.data.center.keys().hasOnly([
          "latitude",
          "longitude"
        ])
        && request.resource.data.center.latitude is number
        && request.resource.data.center.latitude >= -90
        && request.resource.data.center.latitude <= 90
        && request.resource.data.center.longitude is number
        && request.resource.data.center.longitude >= -180
        && request.resource.data.center.longitude <= 180
        && request.resource.data.radiusMeters is number
        && request.resource.data.radiusMeters >= 100
        && request.resource.data.radiusMeters <= 10000
        && request.resource.data.vehicleIds is list
        && request.resource.data.vehicleIds.size() > 0
        && request.resource.data.vehicleIds.size() <= 100
        && request.resource.data.triggerOnEnter is bool
        && request.resource.data.triggerOnExit is bool
        && request.resource.data.isActive is bool;
    }
  }
}
```

## 17.1 Flutter implications

Flutter may:

- Manage its own user document.
- Manage its own vehicles.
- Manage its own valid geofence definitions.
- Read geofence states.
- Read events.
- Update only event `isRead` and `status`.

Flutter may not:

- Create geofence state.
- Create backend events.
- Delete backend events.
- Change event type, location, metadata, timestamps, vehicle, or tracker.

Firebase Admin SDK bypasses Firestore rules.

---

# 18. Firebase Storage

## 18.1 Buckets

```text
gs://dttracker-dev-01
gs://dttracker-staging-01
gs://dttracker-prod-01
```

## 18.2 Recommended user/vehicle image path

```text
users/{uid}/vehicles/{vehicleId}/images/{fileName}
```

Profile example:

```text
users/{uid}/profile/images/{fileName}
```

## 18.3 Recommended Storage rules

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {

    match /users/{uid}/vehicles/{vehicleId}/images/{fileName} {
      allow read, write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    match /users/{uid}/profile/images/{fileName} {
      allow read, write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

For reads of existing objects, `request.resource` may not be available in the same way as writes. Production rules may split `allow read` and `allow write` conditions for clarity.

## 18.4 Flutter upload example

```dart
final uid = FirebaseAuth.instance.currentUser!.uid;

final ref = FirebaseStorage.instance.ref(
  'users/$uid/vehicles/$vehicleId/images/$fileName',
);

await ref.putFile(
  imageFile,
  SettableMetadata(contentType: 'image/jpeg'),
);

final downloadUrl = await ref.getDownloadURL();
```

---

# 19. Geofence Engine

## 19.1 Ownership resolution

Geofence evaluation begins from telemetry IMEI.

```text
IMEI
  -> trackers_registry/{imei}
  -> ownerId
  -> vehicleId
```

It does not use `trackers_info` for ownership.

## 19.2 Query

The backend loads active geofences assigned to a vehicle:

```javascript
firestore
  .collection("users")
  .doc(uid)
  .collection("geofences")
  .where("isActive", "==", true)
  .where("vehicleIds", "array-contains", vehicleId);
```

A Firestore composite index may be required:

```text
Collection group: geofences
isActive: Ascending
vehicleIds: Array contains
```

## 19.3 Geometry

Current implementation supports circular geofences.

Distance is calculated with Haversine distance.

```text
isInside = distanceMeters <= radiusMeters
```

## 19.4 First position

If no state exists:

- Create the state.
- Store current inside/outside result.
- Do not create an event.

This avoids false enter/exit alerts when the engine first observes a vehicle.

## 19.5 Transition detection

```text
false -> true  = geofence_enter
true  -> false = geofence_exit
same value     = no event
```

## 19.6 Atomic behavior

State update and event creation occur in the same Firestore transaction.

This prevents partial state/event writes.

## 19.7 Event suppression and notification semantics

The state always updates.

The older Flutter integration specification documented event suppression when:

```text
triggerOnEnter = false
triggerOnExit = false
settings.geofenceAlertEnabled = false
```

`triggerOnEnter` and `triggerOnExit` clearly control whether the corresponding transition is user-relevant.

However, before FCM is connected, the exact current semantics of:

```text
settings.geofenceAlertEnabled
```

must be verified against the current implementation in:

```text
src/modules/geofences/geofence.module.js
src/services/geofenceService.js
```

Two behaviors are possible:

```text
A. geofenceAlertEnabled=false
   -> suppress Firestore event
   -> suppress push

B. geofenceAlertEnabled=false
   -> retain Firestore event history
   -> suppress push only
```

The backend code is authoritative. Do not change existing event behavior merely to add FCM. The push layer must be attached without duplicating transition detection.

## 19.8 Cache

Active assigned geofences are cached in memory for approximately 60 seconds.

Cache key:

```text
{uid}:{vehicleId}
```

Each PM2 environment process has its own cache.

Direct Flutter Firestore changes may require up to 60 seconds to affect backend evaluation.

Restarting the relevant PM2 process clears the cache.

---

# 20. Event Engine

The `events` collection is the backend-generated domain event stream.

## 20.1 Event principles

Events are:

- Backend-generated.
- Immutable except for client read/archive status.
- Durable.
- Suitable for a Flutter event timeline.
- Suitable for future FCM delivery.
- Generic enough for future event types.

## 20.2 Current types

```text
geofence_enter
geofence_exit
```

## 20.3 Planned types

```text
low_battery
overspeed
tracker_online
tracker_offline
sos
vehicle_linked
vehicle_unlinked
trip_started
trip_finished
maintenance_due
```

## 20.4 Flutter event status behavior

Recommended:

```text
new       = unread
read      = opened by user
archived  = hidden from main timeline
```

When marking an event as read, update both:

```dart
await eventRef.update({
  'isRead': true,
  'status': 'read',
});
```

---


## 20.5 Geofence push notifications — current implementation status

Current feature scope:

```text
geofence_enter
geofence_exit
```

Deferred:

```text
low_battery
overspeed
tracker_online
tracker_offline
iOS/APNs delivery
email
SMS
```

Android Flutter receive-side work is complete:

```text
firebase_messaging dependency                 complete
flutter_local_notifications dependency        complete
POST_NOTIFICATIONS permission                 complete
background handler before runApp              complete
Android channel dt_tracker_geofence            complete
foreground local notification                 complete
onMessageOpenedApp                            complete
getInitialMessage                             complete
tap destination /alerts                       complete
persistent installation deviceId              complete
initial token synchronization                 complete
onTokenRefresh                                complete
non-blocking backend PUT client                complete
physical Android debug verification           complete
```

The Flutter registration request currently receives HTTP `404` because the backend endpoint is not yet implemented.

## 20.6 Planned push-device registration endpoint

Target contract:

```http
PUT /api/v1/users/me/devices/{deviceId}/push-token
Authorization: Bearer <Firebase ID Token>
Content-Type: application/json
```

Representative body:

```json
{
  "pushToken": "<FCM token>",
  "platform": "android",
  "appVersion": "<optional>"
}
```

Required backend behavior:

1. verify the Firebase ID token using existing user authentication middleware;
2. derive `uid` from verified authentication;
3. never trust a request-body UID as ownership proof;
4. validate `deviceId`;
5. validate token and platform;
6. upsert `users/{uid}/devices/{deviceId}`;
7. preserve `createdAt`;
8. update `updatedAt` and `lastSeenAt`;
9. set `pushEnabled: true`;
10. return success without echoing the full token.

Suggested response:

```json
{
  "ok": true,
  "deviceId": "<deviceId>",
  "pushRegistered": true
}
```

## 20.7 Planned notification backend module

Recommended structure:

```text
src/modules/notifications/
├── notification.constants.js
├── notification.repository.js
└── notification.service.js
```

Repository responsibilities:

```text
read users/{uid}/devices
return pushEnabled=true registrations
provide token/device data to notification service
support disabling permanently invalid registrations
```

Service responsibilities:

```text
build FCM payload
call Firebase Admin Messaging
support multiple mobile devices
record safe delivery logs
classify permanent invalid-token errors
```

The notification module must not perform Haversine calculations, `isInside` calculation, or geofence transition detection.

## 20.8 FCM payload contract

Enter:

```javascript
{
  notification: {
    title: "DT Tracker",
    body: `${vehicleName} entró a ${geofenceName}.`
  },
  android: {
    notification: {
      channelId: "dt_tracker_geofence"
    }
  },
  data: {
    type: "geofence_enter",
    eventId: String(eventId),
    vehicleId: String(vehicleId),
    trackerId: String(trackerId),
    geofenceId: String(geofenceId),
    geofenceName: String(geofenceName)
  }
}
```

Exit:

```javascript
{
  notification: {
    title: "DT Tracker",
    body: `${vehicleName} salió de ${geofenceName}.`
  },
  android: {
    notification: {
      channelId: "dt_tracker_geofence"
    }
  },
  data: {
    type: "geofence_exit",
    eventId: String(eventId),
    vehicleId: String(vehicleId),
    trackerId: String(trackerId),
    geofenceId: String(geofenceId),
    geofenceName: String(geofenceName)
  }
}
```

All FCM `data` values must be strings.

## 20.9 Push eligibility

A push may be considered only after the existing backend has detected a real geofence transition.

The intended push preference gates are:

```text
users/{uid}.settings.pushNotificationsEnabled == true
users/{uid}.settings.geofenceAlertEnabled == true
geofence.isActive == true
```

For enter:

```text
geofence.triggerOnEnter == true
```

For exit:

```text
geofence.triggerOnExit == true
```

The exact effect of `geofenceAlertEnabled` on Firestore event generation must be verified against current geofence code before integration. Regardless of that result, no second transition engine may be created.

## 20.10 Push failure isolation

Push delivery is a side effect.

FCM failure must never:

```text
roll back valid telemetry
roll back geofence state
roll back an already committed event
turn a successful ingest into HTTP 500
cause firmware to retry otherwise acknowledged telemetry
```

Target behavior:

```text
telemetry       success
geofence state  success
event           success
push            failure
ingest          success
```

Log the push failure safely and continue.

## 20.11 Required implementation order

1. inspect existing `authMiddleware.js`;
2. inspect `src/app.js`;
3. inspect authenticated `src/routes/vehicles.js` conventions;
4. expose Firebase Admin Messaging from existing `firebase.js`;
5. implement authenticated push-device registration;
6. verify Flutter registration changes from `404` to HTTP `2xx`;
7. verify Firestore `users/{uid}/devices/{deviceId}`;
8. implement notification repository/service;
9. send a controlled manual Backend -> FCM push;
10. verify foreground delivery;
11. verify background delivery;
12. verify terminated app + tap -> `/alerts`;
13. locate existing geofence event commit point;
14. attach FCM only after successful transition/event processing;
15. test enter;
16. test exit;
17. test disabled preferences;
18. test multiple mobile registrations;
19. test invalid-token handling;
20. remove or development-guard any manual push endpoint.

Do not connect FCM to geofences until manual backend-to-device delivery is proven.

# 21. Recommended Flutter Clean Architecture

The Flutter app uses Clean Architecture with BLoC.

Recommended feature-first layout:

```text
lib/
├── core/
│   ├── config/
│   ├── errors/
│   ├── network/
│   ├── firebase/
│   ├── routing/
│   ├── di/
│   └── utils/
├── shared/
│   ├── widgets/
│   ├── models/
│   └── extensions/
└── features/
    ├── authentication/
    ├── dashboard/
    ├── vehicles/
    ├── trackers/
    ├── geofences/
    ├── events/
    └── profile/
```

Each feature:

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   ├── mappers/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── bloc/
    ├── pages/
    └── widgets/
```

---

# 22. Core Flutter Environment Configuration

Recommended model:

```dart
enum AppEnvironment {
  dev,
  staging,
  prod,
}
```

```dart
class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
}
```

Values:

```dart
const devConfig = EnvironmentConfig(
  environment: AppEnvironment.dev,
  apiBaseUrl: 'https://dev.dt-tracker.com/api/v1',
);

const stagingConfig = EnvironmentConfig(
  environment: AppEnvironment.staging,
  apiBaseUrl: 'https://staging.dt-tracker.com/api/v1',
);

const prodConfig = EnvironmentConfig(
  environment: AppEnvironment.prod,
  apiBaseUrl: 'https://api.dt-tracker.com/api/v1',
);
```

Firebase initialization must match the same environment resources.

---

# 23. Flutter HTTP Client

The backend data source should attach a fresh Firebase ID token.

Example using `http`:

```dart
class AuthenticatedApiClient {
  AuthenticatedApiClient({
    required FirebaseAuth firebaseAuth,
    required http.Client client,
    required String baseUrl,
  })  : _firebaseAuth = firebaseAuth,
        _client = client,
        _baseUrl = baseUrl;

  final FirebaseAuth _firebaseAuth;
  final http.Client _client;
  final String _baseUrl;

  Future<http.Response> post(
    String path, {
    Object? body,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('Authenticated user required');
    }

    final token = await user.getIdToken();

    return _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );
  }
}
```

A production implementation should:

- Handle network exceptions.
- Parse structured backend errors.
- Refresh token once after `401`.
- Avoid infinite retry loops.
- Log request IDs when backend request IDs are later added.

---

# 24. Flutter Tracker Feature Mapping

## 24.1 Domain entity

```dart
class Tracker {
  const Tracker({
    required this.imei,
    required this.status,
    required this.isAvailable,
    this.model,
    this.provider,
    this.firmware,
    this.ownerId,
    this.vehicleId,
    this.linkedAt,
  });

  final String imei;
  final String status;
  final bool isAvailable;
  final String? model;
  final String? provider;
  final String? firmware;
  final String? ownerId;
  final String? vehicleId;
  final DateTime? linkedAt;
}
```

## 24.2 Repository contract

```dart
abstract interface class TrackerRepository {
  Future<Tracker> validateImei(String imei);
}
```

## 24.3 Remote data source

```dart
abstract interface class TrackerBackendDataSource {
  Future<TrackerDto> validateImei(String imei);
}
```

## 24.4 Use case

```dart
class ValidateTracker {
  const ValidateTracker(this._repository);

  final TrackerRepository _repository;

  Future<Tracker> call(String imei) {
    return _repository.validateImei(imei);
  }
}
```

## 24.5 BLoC flow

```text
ValidateTrackerRequested
  -> ValidateTracker use case
  -> TrackerRepository
  -> TrackerBackendDataSource
  -> POST /trackers/validate
  -> TrackerValidated or TrackerValidationFailed
```

---

# 25. Flutter Vehicle Link Feature Mapping

## 25.1 Repository contract

```dart
abstract interface class VehicleRepository {
  Future<void> linkTracker({
    required String vehicleId,
    required String imei,
  });

  Future<void> unlinkTracker({
    required String vehicleId,
  });
}
```

## 25.2 Backend data source contract

```dart
abstract interface class VehicleBackendDataSource {
  Future<void> linkTracker({
    required String vehicleId,
    required String imei,
  });

  Future<void> unlinkTracker({
    required String vehicleId,
  });
}
```

## 25.3 Link request

```dart
await apiClient.post(
  '/vehicles/$vehicleId/link',
  body: {
    'imei': imei,
  },
);
```

## 25.4 Unlink request

```dart
await apiClient.post(
  '/vehicles/$vehicleId/unlink',
);
```

## 25.5 Important repository behavior

The backend updates Firestore vehicle linkage.

After a successful link or unlink, Flutter should:

- Refetch the vehicle document, or
- Let the existing Firestore stream update the UI.

Flutter should not duplicate backend ownership writes.

---

# 26. Flutter Tracker Live Data

Flutter may read RTDB directly.

Recommended data source methods:

```dart
Stream<TrackerLiveDto> watchTrackerLive(String imei);
Stream<TrackerStatusDto> watchTrackerStatus(String imei);
Stream<List<TrackerHistoryDto>> watchTrackerHistory(
  String imei,
  DateTime date,
);
```

Paths:

```text
trackers_live/{imei}
trackers_status/{imei}
trackers_history/{imei}/{YYYY-MM-DD}
```

The read succeeds only when:

```text
users/{uid}/devices/{imei} = true
```

If permission is denied after linking:

- Confirm the backend created the mapping.
- Confirm Firebase Auth is signed in.
- Confirm Flutter is using the correct RTDB environment.

---

# 27. Flutter Geofence Feature

Flutter currently manages geofence definitions directly in Firestore.

## 27.1 Repository contract

```dart
abstract interface class GeofenceRepository {
  Stream<List<Geofence>> watchGeofences();
  Future<void> createGeofence(Geofence geofence);
  Future<void> updateGeofence(Geofence geofence);
  Future<void> deleteGeofence(String geofenceId);
}
```

## 27.2 Domain constraints

- Name: 1–100 chars.
- Radius: 100–10,000 meters.
- At least one vehicle ID.
- Valid latitude and longitude.
- Boolean enter/exit triggers.
- Boolean active state.

## 27.3 Write path

```text
users/{uid}/geofences/{geofenceId}
```

## 27.4 Timestamp behavior

Use server timestamps where practical:

```dart
FieldValue.serverTimestamp()
```

## 27.5 Cache warning

Backend geofence evaluation may use an older definition for up to approximately 60 seconds.

The UI may show immediate Firestore changes while the backend cache is still active.

---

# 28. Flutter Events Feature

## 28.1 Repository contract

```dart
abstract interface class EventRepository {
  Stream<List<TrackerEvent>> watchEvents({
    EventStatus? status,
  });

  Future<void> markAsRead(String eventId);
  Future<void> archive(String eventId);
}
```

## 28.2 Query

Main timeline:

```dart
FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .collection('events')
    .orderBy('occurredAt', descending: true);
```

Unread:

```dart
.where('status', isEqualTo: 'new')
.orderBy('occurredAt', descending: true);
```

The unread query may require a composite index:

```text
status: Ascending
occurredAt: Descending
```

## 28.3 Event entity

```dart
class TrackerEvent {
  const TrackerEvent({
    required this.id,
    required this.version,
    required this.source,
    required this.type,
    required this.category,
    required this.severity,
    required this.status,
    required this.isRead,
    required this.vehicleId,
    required this.trackerId,
    required this.title,
    required this.message,
    required this.occurredAt,
    required this.createdAt,
    this.location,
    this.metadata = const {},
  });

  final String id;
  final int version;
  final String source;
  final String type;
  final String category;
  final String severity;
  final String status;
  final bool isRead;
  final String vehicleId;
  final String trackerId;
  final String title;
  final String message;
  final DateTime occurredAt;
  final DateTime createdAt;
  final EventLocation? location;
  final Map<String, dynamic> metadata;
}
```

## 28.4 Unknown event compatibility

Flutter should not crash for a new backend event type.

Use a fallback:

```dart
EventType.unknown
```

Render generic title/message fields when type-specific UI is unavailable.

---

# 29. Error Mapping in Flutter

Recommended exceptions/failures:

```text
UnauthorizedFailure
ValidationFailure
NotFoundFailure
ConflictFailure
NetworkFailure
ServerFailure
PermissionFailure
UnknownFailure
```

Mapping:

| HTTP / Firebase result | Flutter failure |
|---|---|
| 400 | ValidationFailure |
| 401 | UnauthorizedFailure |
| 404 | NotFoundFailure |
| 409 | ConflictFailure |
| 500 | ServerFailure |
| Socket/timeout | NetworkFailure |
| Firestore permission denied | PermissionFailure |

Preserve backend `error` and `message` values for diagnostics.

---

# 30. Recommended BLoCs

## TrackerLinkBloc

Events:

```text
ImeiChanged
ValidateTrackerRequested
LinkTrackerRequested
UnlinkTrackerRequested
```

States:

```text
TrackerLinkInitial
TrackerValidationInProgress
TrackerAvailable
TrackerUnavailable
TrackerLinkInProgress
TrackerLinkSuccess
TrackerUnlinkSuccess
TrackerLinkFailure
```

## GeofenceBloc

Events:

```text
GeofencesSubscriptionRequested
GeofenceCreateRequested
GeofenceUpdateRequested
GeofenceDeleteRequested
```

## EventsBloc

Events:

```text
EventsSubscriptionRequested
EventMarkedRead
EventArchived
EventFilterChanged
```

## TrackerLiveBloc or Cubit

Responsibilities:

- Subscribe to live path.
- Subscribe to status.
- Handle permission and disconnect errors.
- Expose last update and online state.

---

# 31. Dependency Injection

Recommended registrations:

```text
FirebaseAuth
FirebaseFirestore
FirebaseDatabase
FirebaseStorage
HTTP Client
EnvironmentConfig
AuthenticatedApiClient

TrackerBackendDataSource
VehicleBackendDataSource
TrackerRealtimeDataSource
GeofenceFirestoreDataSource
EventFirestoreDataSource
StorageDataSource
PushDeviceBackendDataSource
NotificationService

TrackerRepository
VehicleRepository
GeofenceRepository
EventRepository
```

BLoCs depend on use cases, not data sources.

Widgets must not directly access GetIt/service locator when dependencies can be injected through routing or constructors.

---

# 32. End-to-End Flutter Link Flow

```text
User enters IMEI
  -> TrackerLinkBloc
  -> ValidateTracker
  -> POST /trackers/validate
  -> Show availability

User confirms link
  -> LinkTracker use case
  -> POST /vehicles/{vehicleId}/link
  -> Backend updates registry, authorization map, and vehicle
  -> Firestore vehicle stream emits trackerId
  -> RTDB rules permit tracker reads
  -> Live tracker stream starts
```

---

# 33. End-to-End Geofence and Push Flow

Current event flow:

```text
Flutter creates geofence definition
  -> Firestore users/{uid}/geofences/{geofenceId}

ESP32 sends authenticated telemetry
  -> Backend live/batch ingest
  -> Resolve owner and vehicle
  -> Load active assigned geofences
  -> Calculate membership
  -> Compare persisted state
  -> Update geofence state
  -> Create event on transition

Flutter event stream
  -> New geofence event
  -> EventsBloc updates timeline
```

FCM extension:

```text
Existing transition/event flow
  -> verify notification eligibility
  -> load active mobile push registrations
  -> Firebase Admin Messaging
  -> FCM
  -> Android device
```

Current status:

```text
Flutter Android FCM receive path        complete
Flutter mobile installation deviceId   complete
Flutter token refresh                  complete
Flutter backend PUT client             complete
Backend push-device endpoint           pending
Backend Messaging service              pending
Manual backend -> FCM delivery         pending
Geofence -> FCM integration            pending
```

Tap behavior for the first Android delivery is:

```text
geofence_enter / geofence_exit
  -> notification tap
  -> /alerts
```

The notification payload preserves `eventId`, `vehicleId`, `trackerId`, `geofenceId`, and `geofenceName` for future detail/map navigation.

---

# 34. Current Backend Status and Remaining Work

The former Flutter specification listed several production-hardening items as pending. They are now implemented and must no longer be treated as limitations.

## 34.1 Completed backend baseline

```text
API versioning                              complete
single ingest                              complete
batch ingest                               complete
single/batch coexistence                   complete
Joi validation                             complete
request/correlation IDs                    complete
structured request logging                 complete
centralized error handling                 complete
Helmet/CORS security                       complete
rate limiting                              complete
device HMAC-SHA256 authentication          complete
timestamp freshness validation             complete
nonce replay protection                    complete
Firestore TTL for nonces                   complete
graceful shutdown                          complete
multi-environment runtime                  complete
Firebase ID-token user authentication      implemented baseline
geofence state persistence                 complete
geofence enter/exit event generation       complete
```

## 34.2 Current notification work

```text
Flutter Android FCM receive layer          complete
Flutter installation deviceId              complete
Flutter token refresh handling             complete
Flutter device registration HTTP client    complete
Backend push-device registration           next
Firebase Admin Messaging integration       next
Manual backend FCM test                    next
Geofence enter/exit push delivery          next
invalid FCM token cleanup                  next
multi-phone notification verification      next
```

## 34.3 Other remaining engineering work

```text
automated backend unit/integration tests   next
CI/CD                                      next
monitoring and metrics                     next
tracker offline detection                  future
low-battery events                         future
overspeed engine                           future
trip engine                                future
OTA lifecycle                              future
secret rotation automation                 future
iOS FCM/APNs setup                         future phase
```

## 34.4 Geofence preference semantic verification

Before wiring FCM, inspect the current geofence implementation to confirm whether:

```text
settings.geofenceAlertEnabled=false
```

suppresses the Firestore event itself or only should suppress push delivery.

Do not alter current historical event behavior until this is verified against code.

---

# 35. Security Notes

- Never place `ADMIN_API_KEY` in Flutter.
- Never place Firebase service-account JSON in Flutter.
- Never allow Flutter to write tracker ownership.
- Never allow Flutter to generate backend domain events.
- Do not trust client-provided UID values.
- Use `FirebaseAuth.currentUser.uid`.
- Use Firebase ID tokens for protected backend requests.
- Use environment-specific Firebase configuration.
- Do not mix development and production resources.
- Do not expose `trackers_registry` to clients.
- Treat download URLs as application data and protect Storage paths.

---

# 36. Flutter Implementation Order

Recommended order:

## Phase 1 — Core

- Environment configuration.
- Firebase initialization.
- Authentication.
- Authenticated API client.
- Error mapping.
- Dependency injection.

## Phase 2 — Tracker linking

- Tracker domain entity.
- Tracker backend data source.
- Validate tracker use case.
- Vehicle link/unlink use cases.
- TrackerLinkBloc.
- Link/unlink UI.

## Phase 3 — Live tracking

- RTDB live data source.
- RTDB status data source.
- Domain models.
- Map integration.
- Permission handling.

## Phase 4 — Geofences

- Firestore data source.
- Geofence repository.
- Create/edit/delete use cases.
- GeofenceBloc.
- Map editor.
- Radius validation.

## Phase 5 — Events

- Event data source.
- Event mapper.
- Event repository.
- EventsBloc.
- Timeline.
- Mark read/archive.

## Phase 6 — Storage

- Vehicle image upload.
- Profile image upload.
- Upload progress.
- URL persistence.

---


## Phase 7 — Android push notifications

Flutter receive-side implementation is complete.

Backend continuation order:

```text
push-device registration endpoint
-> Firestore mobile installation record
-> Firebase Admin Messaging
-> manual push test
-> foreground/background/terminated validation
-> geofence_enter integration
-> geofence_exit integration
-> preference gating
-> invalid-token cleanup
```

iOS/APNs is deferred from this phase.

# 37. Integration Test Checklist

## Authentication

- Sign in.
- Obtain ID token.
- Protected endpoint succeeds.
- Expired token is handled.

## Tracker validation

- Valid registered tracker.
- Invalid IMEI.
- Missing tracker.
- Tracker already used.

## Link

- User-owned vehicle.
- Tracker registry updates.
- Vehicle Firestore document updates.
- RTDB user-device mapping exists.
- Live RTDB read succeeds.

## Unlink

- Registry resets.
- Mapping removed.
- Vehicle tracker fields removed.
- RTDB read is denied afterward.

## Geofence

- Create valid geofence.
- Invalid radius rejected by rules.
- First state creates no event.
- Enter creates one event.
- Exit creates one event.
- Same-side points create no duplicates.
- Disabled trigger suppresses event.
- User preference suppresses event.

## Push notifications

- Flutter registration endpoint returns HTTP 2xx.
- Firestore `users/{uid}/devices/{deviceId}` is created.
- Token refresh updates the same mobile installation.
- Manual backend push reaches foreground app.
- Manual backend push reaches background app.
- Manual backend push reaches terminated app.
- Notification tap opens `/alerts`.
- Enter transition sends exactly one push when enabled.
- Exit transition sends exactly one push when enabled.
- Same-side positions do not send duplicate pushes.
- Disabled global push setting prevents push.
- Disabled geofence push setting prevents push.
- Disabled enter/exit trigger prevents corresponding push.
- One invalid FCM registration does not break other recipients.
- FCM failure does not fail `/ingest`.
- Full production FCM tokens are absent from logs.

## Events

- Timeline reads.
- Mark read succeeds.
- Editing protected fields fails.
- Client event creation fails.

## Storage

- User can upload own image.
- User cannot upload another user's image.
- Non-image file rejected.
- Oversized file rejected.

---

# 38. Source-of-Truth Summary

| Concern | Source of truth |
|---|---|
| User authentication | Firebase Authentication |
| Tracker device authentication | Firestore device credentials + backend HMAC verification |
| Device replay protection | Firestore `device_auth_nonces` + backend validation |
| Tracker inventory | RTDB `trackers_registry` |
| Tracker owner | RTDB `trackers_registry/{imei}/ownerId` |
| Linked vehicle | RTDB registry vehicle ID + Firestore vehicle `trackerId` |
| Client tracker read authorization | RTDB `users/{uid}/devices/{imei}` |
| Latest position | RTDB `trackers_live/{imei}` |
| Tracker operational status | RTDB `trackers_status/{imei}` |
| Runtime metadata | RTDB `trackers_info/{imei}` |
| Position history | RTDB `trackers_history/{imei}` |
| Vehicle business data | Firestore `users/{uid}/vehicles` |
| User notification settings | Firestore `users/{uid}.settings` |
| Geofence definitions | Firestore `users/{uid}/geofences` |
| Geofence membership state | Firestore `users/{uid}/geofence_states` |
| Domain event timeline | Firestore `users/{uid}/events` |
| Mobile FCM registrations | Firestore `users/{uid}/devices/{mobileInstallationId}` |
| Images | Firebase Storage |
| Push transport | Firebase Cloud Messaging |
| Geofence transition decision | Existing backend geofence engine |

Important naming distinction:

```text
RTDB users/{uid}/devices/{imei}
= authorization to read a physical tracker

Firestore users/{uid}/devices/{mobileInstallationId}
= mobile app installation / FCM token registration
```

---

# 39. Final Flutter Contract

Flutter should:

- Authenticate with Firebase.
- Call backend for tracker validation/link/unlink.
- Read live tracker data from RTDB after linking.
- Manage vehicle and geofence business data in Firestore.
- Read geofence state and events.
- Update only event read/archive status.
- Upload images to user-scoped Storage paths.
- Use environment-specific configuration.
- Keep backend ownership and event generation server-owned.
- Receive Android geofence pushes through the isolated notification service.
- Maintain a persistent mobile installation `deviceId`.
- Register and refresh FCM tokens through the authenticated backend push-device endpoint.
- Route current geofence notification taps to `/alerts`.

Flutter should not:

- Write telemetry.
- Register trackers.
- Modify tracker registry.
- Assign owners directly.
- Create device authorization mappings.
- Create geofence state.
- Create domain events.
- Store admin secrets.
- Calculate geofence transitions for push purposes.
- Write backend-owned geofence state.
- Treat a failed push-token registration as a reason to block normal app usage.

---

# 40. Document Maintenance

Update this document whenever:

- An endpoint changes.
- A response schema changes.
- A Firebase path changes.
- Rules change.
- A new event type is added.
- Flutter starts using a new backend contract.
- A new environment is created.
- A feature moves from planned to implemented.
- A production-hardening capability changes.
- FCM/APNs contracts, token storage, or notification payloads change.

The backend implementation remains the final authority if this document and code disagree.

---

# 41. v3.0 Merge Notes

This v3.0 document intentionally merges two previously divergent specifications:

```text
1. Flutter-oriented integration contract
2. Backend production-hardening / notification context
```

The Flutter-oriented document remains the primary source for:

```text
API usage from Flutter
Firebase data contracts
RTDB and Firestore rules
Storage
Clean Architecture / BLoC mapping
Flutter feature behavior
geofence/event integration details
```

The production-hardening context supersedes older statements about:

```text
anonymous/pending ingest authentication
missing batch ingest
missing request IDs
missing rate limiting
missing centralized errors
missing replay protection
older runtime folder structure
FCM Android receive-side status
```

When this document and deployed code disagree, deployed backend code and active Firebase rules are authoritative.

Before completing geofence FCM integration, the implementation must specifically verify current `geofenceAlertEnabled` event-suppression semantics in the geofence service.

