# DT Tracker Backend Endpoints

## Base URLs

```text
Development: https://dev.dt-tracker.com/api/v1
Staging:     https://staging.dt-tracker.com/api/v1
Production:  https://api.dt-tracker.com/api/v1
```

## Authentication

Flutter endpoints:

```http
Authorization: Bearer <Firebase ID Token>
```

Admin endpoint:

```http
x-admin-api-key: <ADMIN_API_KEY>
```

---

## GET /health

```bash
curl https://dev.dt-tracker.com/health
```

Response:

```json
{
  "status": "UP",
  "environment": "dev",
  "uptime": 123.45,
  "timestamp": "2026-07-03T00:00:00.000Z"
}
```

---

## GET /version

```bash
curl https://dev.dt-tracker.com/version
```

Response:

```json
{
  "version": "1.0.0",
  "node": "v22.22.1",
  "environment": "dev"
}
```

---

## POST /api/v1/ingest

Used by ESP32.

```json
{
  "imei": "864643060618008",
  "lat": 20.182058,
  "lng": -96.865013,
  "speed": 18.1,
  "battery": 100,
  "datetime": "2026-07-02T13:59:11Z",
  "ts": 31151
}
```

Curl:

```bash
curl -X POST "https://dev.dt-tracker.com/api/v1/ingest" \
  -H "Content-Type: application/json" \
  -d '{
    "imei": "864643060618008",
    "lat": 20.182058,
    "lng": -96.865013,
    "speed": 18.1,
    "battery": 100,
    "datetime": "2026-07-02T13:59:11Z",
    "ts": 31151
  }'
```

Response:

```json
{ "ok": true }
```

---

## POST /api/v1/trackers/register

Admin-only tracker registration endpoint.

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

---

## POST /api/v1/trackers/validate

Flutter authenticated endpoint.

```bash
TOKEN="FIREBASE_ID_TOKEN"
IMEI="864643060618008"

curl -X POST "https://dev.dt-tracker.com/api/v1/trackers/validate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"imei\":\"$IMEI\"}"
```

---

## POST /api/v1/vehicles/{vehicleId}/link

Flutter authenticated endpoint.

```bash
TOKEN="FIREBASE_ID_TOKEN"
IMEI="864643060618008"
VEHICLE_ID="df25934b-c7fd-4581-8640-c2384e3e7d5d"

curl -X POST "https://dev.dt-tracker.com/api/v1/vehicles/$VEHICLE_ID/link" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"imei\":\"$IMEI\"}"
```

---

## POST /api/v1/vehicles/{vehicleId}/unlink

Flutter authenticated endpoint.

```bash
TOKEN="FIREBASE_ID_TOKEN"
VEHICLE_ID="df25934b-c7fd-4581-8640-c2384e3e7d5d"

curl -X POST "https://dev.dt-tracker.com/api/v1/vehicles/$VEHICLE_ID/unlink" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Common Errors

### 401

```json
{
  "error": "unauthorized",
  "message": "Missing Firebase ID token"
}
```

### invalid_imei

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

### tracker_not_found

```json
{
  "error": "tracker_not_found",
  "message": "Tracker is not registered"
}
```

### vehicle_not_found

```json
{
  "error": "vehicle_not_found",
  "message": "Vehicle was not found"
}
```

### tracker_not_available

```json
{
  "error": "tracker_not_available",
  "message": "Tracker is not available for linking"
}
```
