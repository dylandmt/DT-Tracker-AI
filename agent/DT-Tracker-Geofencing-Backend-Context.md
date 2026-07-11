# DT Tracker Geofencing Backend Context

## Purpose

This document defines the backend and Firebase work required to support
circular vehicle geofences with enter and exit alerts.

The Flutter application manages and displays zones. The Node.js backend
evaluates zone transitions because tracker telemetry continues to arrive while
the mobile application is closed or offline.

## Confirmed Behavior

- A geofence applies only to the vehicles selected in its `vehicleIds` list.
- Geofences are circles defined by a latitude, longitude, and radius in
  meters.
- Radius validation is 100 to 10,000 meters.
- A newly created, enabled, or newly assigned geofence initializes silently.
- The first tracker position only stores whether the vehicle is inside or
  outside the zone. It creates no alert.
- Alerts are generated only after a later boundary crossing:
  - outside to inside: `geofence_enter`
  - inside to outside: `geofence_exit`
- Disabled zones never generate alerts.

## Existing Architecture

Tracker telemetry currently flows through the backend before Firebase:

```text
ESP32/SIM7670 -> POST /api/v1/ingest -> Node.js/Express -> Firebase Admin SDK
```

The current ingest route writes to:

```text
trackers_live/{imei}
trackers_status/{imei}
trackers_info/{imei}
trackers_history/{imei}/{YYYY-MM-DD}/{pushId}
```

Relevant backend reference implementation:

```text
src/routes/ingest.js
```

Tracker ownership is already stored in RTDB:

```text
trackers_info/{imei}/ownerId = uid
users/{uid}/devices/{imei} = true
```

## Firebase Data Model

### Firestore: Geofences

The Flutter client creates and manages zone definitions here:

```text
users/{uid}/geofences/{geofenceId}
```

Example document:

```json
{
  "name": "Home",
  "center": {
    "latitude": 19.4326,
    "longitude": -99.1332
  },
  "radiusMeters": 500,
  "vehicleIds": ["vehicle-id-1"],
  "triggerOnEnter": true,
  "triggerOnExit": true,
  "isActive": true,
  "createdAt": "Firestore Timestamp",
  "updatedAt": "Firestore Timestamp"
}
```

### Firestore: Server-Owned Membership State

The backend maintains one state document per vehicle/geofence pair:

```text
users/{uid}/geofence_states/{vehicleId}_{geofenceId}
```

Example document:

```json
{
  "vehicleId": "vehicle-id-1",
  "geofenceId": "geofence-id-1",
  "isInside": false,
  "lastPositionAt": "Firestore Timestamp",
  "updatedAt": "Firestore Timestamp"
}
```

Firestore is used for state so changing state and creating an alert can occur
within the same transaction.

### Firestore: Alerts

The backend writes immutable alert records here:

```text
users/{uid}/alerts/{alertId}
```

Example document:

```json
{
  "type": "geofence_enter",
  "vehicleId": "vehicle-id-1",
  "geofenceId": "geofence-id-1",
  "message": "Vehicle A entered Home",
  "latitude": 19.4326,
  "longitude": -99.1332,
  "occurredAt": "Firestore Timestamp",
  "isRead": false
}
```

## Firebase Security and Indexes

### Firestore Rules

Allow an authenticated user to read and create, update, or delete only their
own geofence documents.

Allow an authenticated user to read only their own alert documents.

Do not allow mobile clients to write either of these backend-owned paths:

```text
users/{uid}/geofence_states/{stateId}
users/{uid}/alerts/{alertId}
```

The Firebase Admin SDK used by the backend bypasses Firestore rules.

### Firestore Index

The backend queries active zones assigned to one vehicle:

```js
firestore
  .collection('users')
  .doc(uid)
  .collection('geofences')
  .where('isActive', '==', true)
  .where('vehicleIds', 'array-contains', vehicleId);
```

Create the composite index requested by Firestore for this query. It combines
`isActive` ascending with `vehicleIds` array-contains.

## Step 1: Extend Tracker Metadata

Update the backend tracker link endpoint to write the linked vehicle ID:

```text
trackers_info/{imei}/ownerId = uid
trackers_info/{imei}/vehicleId = vehicleId
trackers_info/{imei}/linkedAt = ISO timestamp
```

Update the unlink endpoint to remove `ownerId`, `vehicleId`, and `linkedAt`.

This avoids a Firestore vehicle lookup for every telemetry packet.

## Step 2: Add Geofence Services

Create these backend modules:

```text
src/services/geofenceService.js
src/utils/geo.js
```

`geo.js` exposes a pure Haversine distance helper:

```js
function distanceMeters(latitudeA, longitudeA, latitudeB, longitudeB) {
  // Return the great-circle distance in meters.
}
```

`geofenceService.js` should expose:

```js
async function evaluateGeofences({ imei, latitude, longitude, occurredAt }) {
  // Resolve owner and vehicle, evaluate active zones, and persist transitions.
}
```

Evaluation sequence:

1. Read `trackers_info/{imei}` from RTDB.
2. Return immediately if `ownerId` or `vehicleId` is absent.
3. Load active geofences assigned to `vehicleId`.
4. Calculate the current `isInside` value for each zone:

```js
const isInside = distance <= geofence.radiusMeters;
```

5. Process the state transition transaction described below.

## Step 3: Persist Transitions Atomically

For every evaluated zone, use a Firestore transaction.

1. Read `users/{uid}/geofence_states/{vehicleId}_{geofenceId}`.
2. If the state does not exist, create it with the current `isInside` value,
   `lastPositionAt`, and `updatedAt`; do not create an alert.
3. If the saved value equals the current `isInside` value, do nothing.
4. If the state changed:
   - Determine `geofence_enter` or `geofence_exit`.
   - Respect `triggerOnEnter` or `triggerOnExit`.
   - Update the state document.
   - Create one alert document in `users/{uid}/alerts` within the same
     transaction when the trigger is enabled.

Generating the alert within this transaction prevents duplicate alerts from
telemetry retries and concurrent ingest requests.

## Step 4: Integrate with GPS Ingest

Update `src/routes/ingest.js` after the existing writes to live, status, info,
and history data:

```js
try {
  await evaluateGeofences({
    imei,
    latitude: lat,
    longitude: lng,
    occurredAt: datetime,
  });
} catch (error) {
  // Log and monitor this failure without rejecting valid GPS telemetry.
  console.error('Geofence evaluation failed', { imei, error });
}
```

Do not let an alert-processing failure return HTTP 500 for a valid ingest
request. Location tracking must remain available even if Firestore alert work
temporarily fails.

## Step 5: Cache Zone Definitions

Do not query Firestore zone definitions for every telemetry request.

Use an in-memory cache keyed by:

```text
{uid}:{vehicleId}
```

Recommended initial policy:

- Cache active geofences for 60 seconds.
- Invalidate the entry after zone create, update, disable, delete, or vehicle
  assignment changes.
- Keep Firestore membership state authoritative; the cache contains only zone
  definitions.

The short cache period means geofence edits can take up to one minute to affect
incoming tracker positions unless the backend provides explicit invalidation.

## Step 6: Respect User Alert Preferences

Before creating an alert, read the user document preference as needed:

```text
users/{uid}: settings.geofenceAlertEnabled
```

The current Flutter user model stores this as `settings.geofenceAlertEnabled`.
When disabled, membership state should continue to update, but no alert record
should be created.

## Step 7: Tests

Add backend unit tests for the distance utility and geofence service.

Required scenarios:

1. First observed position inside a zone initializes state without an alert.
2. First observed position outside a zone initializes state without an alert.
3. Outside to inside creates exactly one `geofence_enter` alert.
4. Inside to outside creates exactly one `geofence_exit` alert.
5. Repeated positions on the same side create no alert.
6. Disabled geofence creates no alert.
7. Zone assigned to a different vehicle creates no alert.
8. Disabled enter or exit trigger creates no corresponding alert.
9. Unlinked tracker skips geofence evaluation.
10. Concurrent or retried ingestion creates only one transition alert.
11. Disabled user geofence notifications update state but create no alert.

## Step 8: Deploy and Verify

1. Deploy Firestore rules and the composite index.
2. Deploy the tracker link/unlink metadata changes.
3. Deploy the geofence service and ingest integration to development first.
4. Create a test zone and assign one test vehicle.
5. Send a first tracker position inside or outside the zone; confirm no alert.
6. Send a point across the boundary; confirm one alert document is created.
7. Send additional points on the same side; confirm no duplicate alerts.
8. Cross back over the boundary; confirm the opposite transition alert.
9. Verify normal `trackers_live` and `trackers_history` writes still succeed if
   geofence evaluation is deliberately made to fail.

## Future Work

After Firestore alerts work end-to-end:

1. Register FCM device tokens per user/device.
2. Send a push notification after a geofence alert is committed.
3. Add an in-app alerts list with Firestore streaming.
4. Add schedules, dwell-time alerts, cooldown periods, and optional polygon
   zones.
