# Feature Completeness Context

Updated: 2026-08-21

This document captures the current product and release-readiness backlog for DT Tracker.

## Recent Work

- Added `settings.emailNotificationsEnabled` in Flutter.
  - Default for new users: `false`.
  - Missing Firestore field is interpreted as `false`.
  - The setting is persisted with the next Settings update.
  - Flutter UI includes an Email alerts switch.
  - Backend email delivery must apply the same missing-field default and only send geofence email when `geofenceAlertEnabled`, `emailNotificationsEnabled`, and the matching enter/exit trigger are enabled.
- Added a My location control to the geofence create/edit map.
  - It requests location permission and checks device location services.
  - It only moves the camera to the user's location.
  - It deliberately does not change the geofence center. The user confirms a new center by tapping the map.

## Definition Of Complete

The application is feature-complete when a user can register, complete required permissions, manage profile/vehicles/trackers, view live locations and history, manage geofences, receive/manage alerts according to preferences, and use all promised controls on Android and iOS release builds.

## P0: Release Blockers

1. Complete iOS push notifications.
   - Configure APNs, the Push Notifications capability, and `aps-environment` entitlement.
   - Verify FCM token registration and delivery while the app is foregrounded, backgrounded, and terminated.
   - `FirebaseAppDelegateProxyEnabled` is disabled, so manual APNs/FCM integration must be correct.
   - Test notification tap routing on iOS.

2. Validate end-to-end alert delivery.
   - Confirm backend registration, token refresh, invalid-token cleanup, multi-device support, and retries.
   - Android push is reported as working; iOS is not.
   - Do not rely solely on older backend documents: some state that push delivery is pending and may be outdated.

3. Complete email alert enforcement in the backend.
   - Only send an email when all of these are true:
     - `settings.geofenceAlertEnabled`
     - `settings.emailNotificationsEnabled`
     - the geofence trigger for the event (`triggerOnEnter` or `triggerOnExit`)
   - Missing `emailNotificationsEnabled` must mean `false`.

4. Make release builds distributable.
   - Android release must use a real release signing key, not the debug signing configuration.
   - Resolve the missing `android/app/proguard-rules.pro` referenced by the Android release build configuration.
   - Establish signed Android App Bundle and iOS/TestFlight build flows.

5. Secure production configuration.
   - Restrict Maps keys by package/bundle ID, signing certificate where applicable, APIs, and quotas.
   - Inject Firebase and Maps configuration through secure CI/environment setup.
   - Verify Firestore rules constrain profile documents to an allowed schema and safe fields.

## P1: Visible Features To Finish Or Remove

1. Speed Alerts is visible in Settings but currently says Coming soon.
   - Implement configuration, backend evaluation, events, delivery, and tests; or hide the tile.

2. Vehicle navigation action is visible but only shows a snackbar.
   - Open Google Maps on Android and Apple Maps/Google Maps on iOS using the selected vehicle coordinates.

3. Alert detail route is declared but does not have a detail screen.
   - Implement it or remove the route/affordance.

4. Geofence list activation switch appears disabled.
   - Connect it to `isActive` persistence or use a non-interactive status indicator.

5. Push preference should be user-configurable if `pushNotificationsEnabled` remains part of settings.

6. Help & Support is visible but currently says Coming soon.
   - Add a support channel/documentation link or remove it.

7. Complete account lifecycle behavior.
   - Email verification policy.
   - Recovery for Firebase accounts created when profile creation fails.
   - Token/device deregistration on sign out and notification-consent changes.

## P1: Flow Consistency

- Apply the permissions gate immediately after login and registration, not only at Splash startup.
- Add HTTP timeouts, controlled retries, safe user-facing error messages, and structured backend error handling.
- Validate geofence behavior on physical devices: create/edit, current-location camera action, map tap center confirmation, radius updates, enter, exit, and backend cache delay.

## P2: Quality And Operations

- Add Crashlytics or Sentry plus structured logging for startup, backend, FCM, and location errors.
- Add CI/CD for format, analysis, tests, signed builds, and internal distribution.
- Add integration tests for auth, permissions, trackers, geofences, email/push preferences, push states, and sign out.
- Replace the minimal smoke test with meaningful app-flow tests.
- Update README and agent documentation to reflect actual feature status and backend dependencies.
- Review background-location declarations. Remove unneeded permissions/modes or provide valid App Store/Play Store justification.

## Current Status Summary

| Area | Status |
| --- | --- |
| Authentication, profile, vehicles, tracker linking | Implemented; needs lifecycle hardening |
| Live map and trip history | Implemented; external navigation remains pending |
| Geofence CRUD and event generation | Implemented; list activation control needs completion |
| Geofence email preference | Flutter implemented; backend enforcement must be verified |
| Push notifications Android | Reported working; end-to-end regression tests still needed |
| Push notifications iOS | Incomplete; highest mobile-platform priority |
| Speed alerts and support | Visible but not implemented |
| Release automation and observability | Missing |

## Suggested Next Session Order

1. Diagnose and complete iOS APNs/FCM push delivery on a physical device.
2. Confirm backend behavior for email alert preferences and token registration.
3. Fix signed Android release configuration and build an Android App Bundle.
4. Decide whether to implement or hide Speed Alerts, Help & Support, and alert detail.
5. Add CI/CD, crash reporting, and integration tests.
