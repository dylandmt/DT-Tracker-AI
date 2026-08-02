# DT Tracker — Geofence Push Notifications Implementation Guide

## Objective

Implement push notifications in DT Tracker when a vehicle:

- enters an established geofence;
- exits an established geofence.

Battery alerts are explicitly out of scope for this phase.

The existing geofence detection flow must remain the source of truth. Do not reimplement geofence calculations in Flutter or in the notification layer.

---

## Current Architecture Context

### Firestore

Current relevant structure:

```text
users/{userId}
├── settings
│   ├── pushNotificationsEnabled: bool
│   ├── geofenceAlertEnabled: bool
│   ├── speedAlertEnabled: bool
│   └── speedLimitKmh: number
│
├── vehicles/{vehicleId}
│   ├── name
│   ├── brand
│   ├── model
│   ├── year
│   ├── color
│   ├── plateNumber
│   ├── imageUrls[]
│   ├── trackerId
│   ├── trackerLinkedAt
│   ├── createdAt
│   └── updatedAt
│
├── geofences/{geofenceId}
│   ├── center.latitude
│   ├── center.longitude
│   ├── name
│   ├── radiusMeters
│   ├── isActive
│   ├── triggerOnEnter
│   ├── triggerOnExit
│   ├── vehicleIds[]
│   ├── createdAt
│   └── updatedAt
│
├── geofence_states/{vehicleId}_{geofenceId}
│   ├── vehicleId
│   ├── geofenceId
│   ├── isInside
│   ├── lastPositionAt
│   └── updatedAt
│
└── events/{eventId}
    ├── category
    ├── type
    ├── title
    ├── message
    ├── vehicleId
    ├── trackerId
    ├── location
    ├── metadata
    ├── severity
    ├── status
    ├── isRead
    ├── occurredAt
    ├── createdAt
    ├── source
    └── version
```

Known event types already used:

```text
geofence_enter
geofence_exit
```

`geofence_states` already handles the transition:

```text
false -> true  = geofence_enter
true  -> false = geofence_exit
false -> false = no event
true  -> true  = no event
```

Do not add another geofence state mechanism.

---

## Realtime Database

Relevant current nodes:

```text
trackers_live/{imei}
trackers_status/{imei}
trackers_history/
trackers_info/
trackers_registry/
users/
```

Realtime Database is not the focus of this feature.

---

# Desired Notification Flow

```text
ESP32
  |
  v
POST /api/v1/ingest
  |
  v
Existing geofence evaluator
  |
  +---- geofence_enter
  |
  +---- geofence_exit
  |
  v
Create Firestore event
  |
  v
Evaluate push notification settings
  |
  v
Firebase Cloud Messaging
  |
  v
Flutter application
```

The FCM notification must be triggered only from an actual geofence transition already detected by the backend.

---

# Notification Eligibility

Before sending a push notification, all applicable conditions must pass.

Global user settings:

```text
users/{userId}.settings.pushNotificationsEnabled == true
users/{userId}.settings.geofenceAlertEnabled == true
```

For enter:

```text
geofence.isActive == true
geofence.triggerOnEnter == true
```

For exit:

```text
geofence.isActive == true
geofence.triggerOnExit == true
```

The existing event-generation behavior should not be duplicated by the notification module.

---

# New Firestore Subcollection for Mobile Devices

Add:

```text
users/{userId}/devices/{deviceId}
```

Recommended document:

```json
{
  "platform": "android",
  "pushToken": "FCM_TOKEN",
  "pushEnabled": true,
  "appVersion": "1.0.0",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "lastSeenAt": "Timestamp"
}
```

Do not store a single `fcmToken` directly on the user document.

Reason:

- a user can have multiple phones;
- FCM tokens can rotate;
- the app can be reinstalled;
- Android and iOS devices may coexist.

---

# Phase 1 — Flutter FCM Setup

## Goal

Get a valid FCM registration token from the real device before changing geofence backend logic.

## Required packages

Add or verify:

```yaml
dependencies:
  firebase_core: <compatible version>
  firebase_messaging: <compatible version>
  flutter_local_notifications: <compatible version>
```

Use versions compatible with the current Flutter/Dart/Firebase package set in the project. Do not blindly upgrade unrelated packages.

Run:

```bash
flutter pub get
```

---

## Firebase initialization

Ensure Firebase is initialized before `runApp`.

Typical structure:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

If the project already initializes Firebase, reuse that implementation. Do not initialize it twice.

---

## Background message handler

Create a top-level handler:

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Keep processing minimal here.
}
```

Register before `runApp`:

```dart
FirebaseMessaging.onBackgroundMessage(
  firebaseMessagingBackgroundHandler,
);
```

---

## Notification service

Recommended Flutter structure:

```text
lib/
└── core/
    └── notifications/
        ├── notification_service.dart
        ├── notification_handler.dart
        └── notification_payload.dart
```

The notification service should:

1. request notification permission;
2. retrieve the FCM token;
3. listen for token refresh;
4. listen for foreground messages;
5. handle notification tap;
6. handle the initial notification when the app was terminated;
7. optionally use `flutter_local_notifications` to show foreground notifications.

Do not place notification logic directly in UI widgets.

---

## Notification permission

Request permission through `FirebaseMessaging`.

Handle at least:

```text
authorized
provisional
denied
```

Do not repeatedly prompt the user on every app start.

---

## Retrieve FCM token

Use:

```dart
final token = await FirebaseMessaging.instance.getToken();
```

During development, log it safely:

```dart
debugPrint('FCM token available: ${token != null}');
```

If manual backend testing requires the full token, print it temporarily in development only.

Do not hardcode the token in source control.

---

## Listen for token refresh

Use:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((token) {
  // Send latest token to backend.
});
```

The same registration API used for the initial token must be reused for token refresh.

---

# Phase 2 — Android Configuration

Verify the project has the Firebase Android configuration already required by Firebase Core.

For Android 13+, notification runtime permission must be supported.

Ensure the manifest contains the appropriate notification permission when required by the current Firebase Messaging setup:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Create an Android notification channel for geofence notifications.

Suggested channel:

```text
id: dt_tracker_geofence
name: Geofence alerts
importance: high
```

Do not create a new channel for every notification.

---

# Phase 3 — iOS Configuration

If iOS is part of the current app:

- enable Push Notifications capability;
- enable Background Modes -> Remote notifications;
- configure APNs in Firebase;
- request notification permission;
- verify the app receives an FCM token.

Do not block Android implementation if iOS credentials are not ready, but keep the Dart layer platform-neutral.

---

# Phase 4 — Backend Device Registration Endpoint

Create an authenticated endpoint for the Flutter app.

Recommended:

```http
PUT /api/v1/users/me/devices/{deviceId}/push-token
```

Alternative route naming is acceptable if it follows the existing backend routing conventions.

Suggested body:

```json
{
  "pushToken": "FCM_TOKEN",
  "platform": "android",
  "appVersion": "1.0.0"
}
```

Expected behavior:

- identify the authenticated user;
- upsert `users/{userId}/devices/{deviceId}`;
- set/update `pushToken`;
- set/update `platform`;
- set `pushEnabled: true`;
- update `updatedAt`;
- update `lastSeenAt`;
- preserve `createdAt` if document already exists.

Do not trust a `userId` from the request body if authentication already provides the user identity.

---

# Phase 5 — Backend Notification Module

Recommended structure:

```text
src/
└── modules/
    └── notifications/
        ├── notification.service.js
        ├── notification.repository.js
        └── notification.constants.js
```

## notification.repository.js

Responsibilities:

- read active user mobile devices;
- return enabled FCM tokens;
- disable/remove invalid tokens when Firebase reports them permanently invalid.

Example conceptual function:

```javascript
async function getActivePushTokens(userId) {
  // Read:
  // users/{userId}/devices
  //
  // Filter:
  // pushEnabled === true
  // pushToken exists
}
```

---

## notification.service.js

Responsibilities:

- construct FCM payloads;
- send push notifications;
- support multiple tokens;
- log failures;
- distinguish invalid tokens from temporary transport errors;
- not calculate geofence transitions.

Suggested interface:

```javascript
async function sendGeofenceNotification({
  userId,
  vehicleId,
  trackerId,
  vehicleName,
  geofenceId,
  geofenceName,
  eventId,
  eventType,
}) {
  // ...
}
```

---

# Phase 6 — Manual FCM Test Before Geofence Integration

This phase is mandatory.

Create a temporary backend test path or controlled development-only script that sends a notification to the registered token.

Example notification:

```text
Title: DT Tracker
Body: Push notifications are working.
```

Expected result:

```text
Backend
  -> Firebase Admin Messaging
  -> FCM
  -> Android/iOS device
```

Test all relevant app states:

```text
foreground
background
terminated
```

Do not integrate FCM into `evaluateGeofences()` until this test succeeds.

---

# Phase 7 — Geofence Notification Payload

For enter:

```javascript
{
  notification: {
    title: "DT Tracker",
    body: "CUERVO entró a CASA."
  },
  data: {
    type: "geofence_enter",
    eventId: "...",
    vehicleId: "...",
    trackerId: "864643060618008",
    geofenceId: "...",
    geofenceName: "CASA"
  }
}
```

For exit:

```javascript
{
  notification: {
    title: "DT Tracker",
    body: "CUERVO salió de CASA."
  },
  data: {
    type: "geofence_exit",
    eventId: "...",
    vehicleId: "...",
    trackerId: "864643060618008",
    geofenceId: "...",
    geofenceName: "CASA"
  }
}
```

All FCM `data` values should be serialized as strings.

---

# Phase 8 — Integrate with Existing Geofence Event Flow

Do not add another geofence evaluator.

After the backend has identified an actual transition and created the existing Firestore event:

```text
geofence_enter
or
geofence_exit
```

evaluate whether a push should be sent.

Conceptual flow:

```javascript
const pushEnabled =
  user.settings?.pushNotificationsEnabled === true &&
  user.settings?.geofenceAlertEnabled === true;

if (!pushEnabled) {
  return;
}

if (
  event.type === 'geofence_enter' &&
  geofence.triggerOnEnter !== true
) {
  return;
}

if (
  event.type === 'geofence_exit' &&
  geofence.triggerOnExit !== true
) {
  return;
}

await notificationService.sendGeofenceNotification({
  userId,
  vehicleId,
  trackerId,
  vehicleName,
  geofenceId,
  geofenceName,
  eventId,
  eventType: event.type,
});
```

Important: push delivery failure should not roll back or invalidate the geofence event.

The event is the source-of-truth historical record. Push is a delivery mechanism.

---

# Phase 9 — Flutter Handling

The Flutter app must process:

```text
geofence_enter
geofence_exit
```

Example:

```dart
void handleNotification(RemoteMessage message) {
  final type = message.data['type'];

  switch (type) {
    case 'geofence_enter':
    case 'geofence_exit':
      handleGeofenceNotification(message.data);
      break;
    default:
      break;
  }
}
```

When a user taps a notification, preserve enough information to navigate to the appropriate vehicle/map/event.

Recommended IDs to use:

```text
eventId
vehicleId
trackerId
geofenceId
```

Avoid navigating directly from low-level Firebase callback code if the navigation system is not ready. Pass the notification action through the app's existing routing/state architecture.

---

# Phase 10 — Test Matrix

Test at minimum:

| Scenario | Expected |
|---|---|
| outside -> outside | no event, no push |
| inside -> inside | no event, no push |
| outside -> inside | `geofence_enter`, one push |
| inside -> outside | `geofence_exit`, one push |
| `pushNotificationsEnabled=false` | event may remain, no push |
| `geofenceAlertEnabled=false` | event may remain, no push |
| `triggerOnEnter=false` | no ENTER push |
| `triggerOnExit=false` | no EXIT push |
| geofence `isActive=false` | no active geofence processing |
| duplicate location packet | no duplicate transition push |
| two registered phones | both enabled phones receive push |
| expired FCM token | valid tokens still receive push |
| app foreground | notification handled |
| app background | notification handled |
| app terminated | notification tap handled |

---

# Important Constraints for the AI Agent

1. Do not redesign Firestore.
2. Do not create an `alerts` collection.
3. Reuse `events`.
4. Reuse `geofence_states`.
5. Do not implement geofence calculations in Flutter.
6. Do not implement geofence calculations in `notification.service`.
7. Do not modify tracker firmware for this feature.
8. Do not implement battery alerts in this phase.
9. Keep FCM code isolated from geofence business logic.
10. Respect the project's existing architecture, DI, navigation, BLoC/Cubit, naming and lint conventions.
11. Avoid direct dependency lookup from widgets if the project already injects services through constructors/routes.
12. Preserve existing behavior before adding push side effects.
13. Add concise logging for token registration, FCM send success/failure and notification event type.
14. Never log full production FCM tokens.
15. Push failure must never make `/ingest` fail after the location/event was processed successfully.

---

# Recommended Implementation Order for the AI Agent

1. Inspect existing Flutter Firebase initialization.
2. Inspect authentication/user ID source.
3. Inspect networking layer/API conventions.
4. Inspect dependency injection conventions.
5. Inspect routing/navigation conventions.
6. Add Firebase Messaging dependencies only if missing.
7. Implement notification service.
8. Request permissions.
9. Obtain FCM token.
10. Handle token refresh.
11. Add backend token registration call.
12. Add foreground notification behavior.
13. Add background handler.
14. Add terminated notification handling.
15. Verify manual FCM delivery.
16. Only then connect backend geofence events to `notification.service`.
17. Test ENTER.
18. Test EXIT.
19. Test disabled settings.
20. Test duplicate prevention.
21. Clean temporary debug token logging.

---

# Acceptance Criteria

The feature is complete when:

- a user with notifications enabled receives exactly one push when a linked vehicle enters an enabled geofence;
- a user with notifications enabled receives exactly one push when a linked vehicle exits an enabled geofence;
- no push is generated without a real state transition;
- `pushNotificationsEnabled` is respected;
- `geofenceAlertEnabled` is respected;
- `triggerOnEnter` and `triggerOnExit` are respected;
- existing Firestore `events` continue to work;
- existing `geofence_states` continue to work;
- multiple registered mobile devices are supported;
- token refresh is handled;
- invalid tokens do not break ingest;
- foreground, background and terminated flows work;
- existing tracking behavior is not degraded.

---

# Out of Scope

Do not implement yet:

```text
low_battery
speed notifications
offline notifications
online notifications
GPS signal notifications
email notifications
SMS notifications
```

Those can reuse the notification infrastructure after geofence push notifications are stable.
