# AGENTS.md

Instructions for AI agents working on DT Tracker.

## Quick Reference

```bash
# Run app (dev environment - default)
flutter run

# Run app (production environment)
flutter run --dart-define=ENV=prod

# Build APK
flutter build apk --dart-define=ENV=dev
flutter build apk --dart-define=ENV=prod

# Analyze code
flutter analyze

# Run tests
flutter test

# Get dependencies
flutter pub get
```

## Architecture

**Clean Architecture** with feature-based structure:

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp setup
├── injection_container.dart     # GetIt DI registration
├── config/
│   ├── environment/             # ENV switching (dev/prod)
│   └── router/                  # GoRouter setup
├── core/                        # Shared code
│   ├── errors/                  # Failure classes (use with dartz Either)
│   ├── usecases/                # Base UseCase<T, Params>
│   └── ...
└── features/
    └── {feature}/
        ├── domain/
        │   ├── entities/        # Business objects (Equatable)
        │   ├── repositories/    # Abstract interfaces
        │   └── usecases/        # Single-purpose operations
        ├── data/
        │   ├── models/          # Firestore serialization (extends entity)
        │   ├── datasources/     # Remote/local data access
        │   └── repositories/    # Implements domain interface
        └── presentation/
            ├── bloc/            # BLoC + Events + States
            ├── pages/           # Screen widgets
            └── widgets/         # Reusable UI components
```

## Multi-Environment Firebase

Environment is set at **build time** via `--dart-define=ENV=dev|prod`.

**Config location**: `lib/config/environment/`
- `environment.dart` - `EnvironmentConfig` class with database IDs
- `firebase_config.dart` - Factory for configured Firebase instances

**Databases per environment**:
| Service | Dev | Prod |
|---------|-----|------|
| Firestore | `dttracker-dev` | `dttracker-prod` |
| RTDB | `https://dttracker-dev-01.firebaseio.com` | `https://dttracker-prod-01.firebaseio.com` |
| Storage | `gs://dttracker-dev-01` | `gs://dttracker-prod-01` |

**Auth is shared** across environments (same Firebase project).

**In `injection_container.dart`**, use `FirebaseConfig.getFirestore()` etc., NOT `.instance`.

## Key Conventions

### Imports
- Use **relative imports** within the project (e.g., `import '../../config/...'`)
- Package name is `dt_tracker_ai` - do NOT use `package:dttracker/...`

### Error Handling
- Use `dartz` `Either<Failure, T>` for all repository/usecase returns
- Failure types in `lib/core/errors/failures.dart`
- Exceptions in `lib/core/errors/exceptions.dart`

### BLoC Pattern
- Events: `{Feature}Event` - sealed class with Equatable
- States: `{Feature}State` - sealed class with Equatable
- Use `BlocProvider` at route level in `app_router.dart`
- Register BLoCs as `Factory` in DI (not Singleton)

### Dependency Injection
- Global instance: `final sl = GetIt.instance;`
- Data sources, repos, use cases: `registerLazySingleton`
- BLoCs: `registerFactory`

### Adding a New Feature

1. Create domain layer first (entities, repository interface, use cases)
2. Create data layer (model, data sources, repository impl)
3. Create presentation layer (bloc, pages, widgets)
4. Register in `injection_container.dart`
5. Add routes in `config/router/app_router.dart`

## Android Build Gotchas

**Pinned versions in `android/settings.gradle.kts`** - required for compatibility:
- AGP 8.9.1, Kotlin 2.1.0
- Gradle 8.11.1 (in `gradle-wrapper.properties`)
- `android-maps-utils` pinned to 4.0.0 (in `build.gradle.kts`)

If build fails with version conflicts, check these pins first.

**If Gradle cache corrupts**, run:
```bash
cd android && ./gradlew --stop
rm -rf ~/.gradle/caches android/.gradle
flutter clean && flutter pub get
```

## Firebase Setup Requirements

User must manually add:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Google Maps API key placeholders in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## Current State

- **Phase 1-5 Complete**: Project setup, auth feature, vehicles feature, real-time map tracking with My Location
- **Phase 6 Next**: Geofencing (create/edit zones, enter/exit alerts)
- **Future**: Alerts (Phase 7), Trip playback animation polish

---

## Implemented Features

### Feature: Authentication
**Status**: Complete  
**Location**: `lib/features/auth/`

#### Screens
| Screen | Route | Description |
|--------|-------|-------------|
| `SplashPage` | `/` | Initial screen, checks auth state, redirects to login or home |
| `LoginPage` | `/login` | Email/password sign-in with validation |
| `RegisterPage` | `/register` | Sign-up with name, email, password, confirm password |
| `ForgotPasswordPage` | `/forgot-password` | Password reset via email |

#### BLoC Pattern
**File**: `presentation/bloc/auth_bloc.dart` (uses `part` for events/states)

**Events**:
```dart
CheckAuthStatus()           // Check if user is logged in (on app start)
SignInRequested(email, password)
SignUpRequested(email, password, displayName)
SignOutRequested()
PasswordResetRequested(email)
AuthStateChanged(user)      // Internal: fired by auth stream listener
ClearAuthError()            // Clear error state after showing snackbar
```

**States** (`AuthStatus` enum):
```dart
initial          // App just started
loading          // Auth operation in progress
authenticated    // User logged in (state.user available)
unauthenticated  // No user / logged out
error            // Auth failed (state.errorMessage available)
passwordResetSent // Reset email sent successfully
```

**State Helpers**:
```dart
state.isLoading        // bool
state.isAuthenticated  // bool
state.isUnauthenticated // bool
state.hasError         // bool
state.user             // UserEntity?
state.errorMessage     // String?
```

#### Domain Layer

**Entity** (`domain/entities/user.dart`):
```dart
UserEntity {
  String id;
  String email;
  String? displayName;
  String? photoUrl;
  DateTime createdAt;
  UserSettings settings;
}

UserSettings {
  bool speedAlertEnabled;      // default: true
  double speedLimitKmh;        // default: 120.0
  bool geofenceAlertEnabled;   // default: true
  bool pushNotificationsEnabled; // default: true
}
```

**Repository Interface** (`domain/repositories/auth_repository.dart`):
```dart
Future<Either<Failure, UserEntity>> signInWithEmail({email, password})
Future<Either<Failure, UserEntity>> signUpWithEmail({email, password, displayName?})
Future<Either<Failure, void>> signOut()
Future<Either<Failure, UserEntity?>> getCurrentUser()
Future<Either<Failure, void>> sendPasswordReset({email})
Stream<UserEntity?> authStateChanges()
Future<Either<Failure, UserEntity>> updateUserProfile({displayName?, photoUrl?})
Future<Either<Failure, UserEntity>> updateUserSettings({settings})
```

**Use Cases** (`domain/usecases/`):
| UseCase | Params | Returns |
|---------|--------|---------|
| `SignInWithEmail` | `SignInParams(email, password)` | `Either<Failure, UserEntity>` |
| `SignUpWithEmail` | `SignUpParams(email, password, displayName?)` | `Either<Failure, UserEntity>` |
| `SignOut` | `NoParams()` | `Either<Failure, void>` |
| `GetCurrentUser` | `NoParams()` | `Either<Failure, UserEntity?>` |
| `SendPasswordReset` | `PasswordResetParams(email)` | `Either<Failure, void>` |
| `AuthStateChanges` | `NoParams()` | `Stream<UserEntity?>` (StreamUseCase) |

#### Data Layer

**Firestore Collection**: `users/{uid}`
```json
{
  "email": "string",
  "displayName": "string | null",
  "photoUrl": "string | null",
  "createdAt": "Timestamp",
  "settings": {
    "speedAlertEnabled": "bool",
    "speedLimitKmh": "number",
    "geofenceAlertEnabled": "bool",
    "pushNotificationsEnabled": "bool"
  }
}
```

**Model** (`data/models/user_model.dart`):
- Extends `UserEntity`
- `fromFirestore(DocumentSnapshot)` - parse Firestore doc
- `fromJson(Map, id)` - parse JSON with explicit ID
- `toJson()` - serialize for Firestore
- `UserModel.newUser(id, email, displayName?)` - factory for registration

**Data Sources**:
| DataSource | Purpose |
|------------|---------|
| `AuthRemoteDataSource` | Firebase Auth operations (sign in, sign up, sign out, etc.) |
| `UserRemoteDataSource` | Firestore user document CRUD |

#### Reusable Widgets (`presentation/widgets/`)

**AuthButton** - Primary action button with loading state
```dart
AuthButton(
  text: 'Sign In',
  onPressed: () {},
  isLoading: false,      // Shows spinner, disables button
  isOutlined: false,     // OutlinedButton vs FilledButton
  icon: Icons.login,     // Optional leading icon
)
```

**AuthTextButton** - Secondary text button
```dart
AuthTextButton(text: 'Forgot Password?', onPressed: () {})
```

**AuthLinkButton** - "Don't have account? Sign Up" style
```dart
AuthLinkButton(
  prefixText: "Don't have an account?",
  linkText: 'Sign Up',
  onPressed: () {},
)
```

**AuthTextField** - Base text field with validation
```dart
AuthTextField(
  controller: _controller,
  labelText: 'Email',
  hintText: 'Enter email',
  prefixIcon: Icons.email,
  obscureText: false,
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.next,
  validator: (v) => v!.isEmpty ? 'Required' : null,
  onFieldSubmitted: (_) {},
  enabled: true,
  focusNode: _focusNode,
)
```

**Preset Text Fields** (use these instead of AuthTextField directly):
```dart
EmailTextField(controller: _, validator: _, onFieldSubmitted: _, enabled: _, focusNode: _)
PasswordTextField(controller: _, labelText: _, hintText: _, validator: _, textInputAction: _, ...)
NameTextField(controller: _, validator: _, onFieldSubmitted: _, enabled: _, focusNode: _)
```

**AuthHeader** - Title + subtitle for auth screens
```dart
AuthHeader(title: 'Welcome Back', subtitle: 'Sign in to continue')
```

---

### Core Utilities

#### Error Handling (`core/errors/`)

**Failures** (for `Either<Failure, T>` returns):
| Failure | Fields | Use Case |
|---------|--------|----------|
| `ServerFailure` | `message`, `statusCode?` | API/Firebase errors |
| `CacheFailure` | `message` | Local storage errors |
| `NetworkFailure` | `message` | No internet connection |
| `AuthFailure` | `message`, `code?` | Auth-specific errors |
| `LocationFailure` | `message` | GPS/location errors |
| `PermissionFailure` | `message` | Permission denied |
| `ValidationFailure` | `message`, `fieldErrors?` | Form validation |
| `NotFoundFailure` | `message` | Resource not found |
| `UnknownFailure` | `message` | Catch-all |

**AuthFailure.fromCode(code)** - Factory for Firebase Auth error codes:
- `invalid-email`, `user-disabled`, `user-not-found`, `wrong-password`
- `email-already-in-use`, `weak-password`, `operation-not-allowed`
- `too-many-requests`, `invalid-credential`

**Exceptions** (throw in data layer, catch in repository):
- `ServerException`, `CacheException`, `NetworkException`
- `AuthException`, `LocationException`, `PermissionException`, `ValidationException`

#### Validators (`core/utils/validators.dart`)

```dart
Validators.validateEmail(value)           // null if valid, error message if not
Validators.validatePassword(value)        // min 6 chars, 1 letter, 1 number
Validators.validateConfirmPassword(value, password)
Validators.validateRequired(value, fieldName)
Validators.validateDisplayName(value)     // 2-50 chars
Validators.validatePlateNumber(value)     // min 2 chars
Validators.validateVehicleName(value)     // 2-100 chars
Validators.validateGeofenceName(value)    // 2-100 chars
Validators.validateGeofenceRadius(value)  // 100-10000 meters
Validators.validateSpeedLimit(value)      // 1-300 km/h
```

#### Extensions (`core/utils/extensions.dart`)

**String**:
```dart
'hello'.capitalize          // 'Hello'
'hello world'.capitalizeWords // 'Hello World'
'test@email.com'.isValidEmail // true
'Long text here'.truncate(5)  // 'Long ...'
```

**DateTime**:
```dart
dateTime.formattedDate      // 'Jun 26, 2026'
dateTime.formattedTime      // '14:30'
dateTime.formattedDateTime  // 'Jun 26, 2026 14:30'
dateTime.timeAgo            // '5 minutes ago'
dateTime.isToday            // bool
dateTime.isYesterday        // bool
```

**BuildContext**:
```dart
context.theme               // ThemeData
context.colorScheme         // ColorScheme
context.textTheme           // TextTheme
context.screenWidth         // double
context.screenHeight        // double
context.isKeyboardVisible   // bool
context.showSnackBar('msg', isError: false)
context.showSuccessSnackBar('msg')
context.showErrorSnackBar('msg')
```

**Double**:
```dart
speed.formatSpeed           // '65.5 km/h'
distance.formatDistance     // '1.50 km' or '500 m'
coord.formatCoordinate      // '37.421998' (6 decimals)
```

**Duration**:
```dart
duration.formatted          // '01:30:45'
duration.humanReadable      // '1h 30m' or '45s'
```

#### UseCase Base Classes (`core/usecases/usecase.dart`)

```dart
// Standard use case (returns Future)
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

// Stream use case (returns Stream)
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

// Common param classes
NoParams()
IdParams(id: 'abc123')
PaginationParams(page: 1, limit: 20)
```

---

### Theme System (`core/theme/`)

**Usage**:
```dart
// In MaterialApp (already configured in app.dart)
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
)

// Access in widgets
Theme.of(context).colorScheme.primary
context.colorScheme.error  // via extension
```

**Seed Color**: `#1976D2` (Material Blue)

**AppColors** - Static color constants:
```dart
AppColors.seedColor         // Primary seed
AppColors.statusOnline      // #4CAF50 (green)
AppColors.statusOffline     // #9E9E9E (grey)
AppColors.statusMoving      // #2196F3 (blue)
AppColors.statusIdle        // #FF9800 (orange)
AppColors.statusAlert       // #F44336 (red)
AppColors.geofenceStroke    // #1976D2
AppColors.geofenceFill      // #331976D2 (20% opacity)
AppColors.routeColor        // #1976D2
```

**Theme Features**:
- Material 3 enabled (`useMaterial3: true`)
- Rounded corners: 12px buttons/inputs, 16px dialogs, 20px bottom sheets
- Floating snackbars with 8px radius
- Centered app bar titles
- Navigation bar with always-visible labels

---

### Route Constants (`core/constants/route_constants.dart`)

**Implemented Routes**:
| Constant | Path | Description |
|----------|------|-------------|
| `splash` | `/` | Initial screen |
| `login` | `/login` | Login page |
| `register` | `/register` | Registration page |
| `forgotPassword` | `/forgot-password` | Password reset |
| `home` | `/home` | Redirects to `/home/vehicles` |
| `homeVehicles` | `/home/vehicles` | Vehicles list (with bottom nav) |
| `homeMap` | `/home/map` | Map placeholder (with bottom nav) |
| `homeSettings` | `/home/settings` | Settings (with bottom nav) |
| `vehicleAdd` | `/home/vehicles/add` | Add vehicle form |
| `vehicleDetail` | `/home/vehicles/:id` | Vehicle details |
| `vehicleEdit` | `/home/vehicles/:id/edit` | Edit vehicle form |
| `vehicleLinkTracker` | `/home/vehicles/:id/link-tracker` | Link GPS tracker |

**Defined but NOT Implemented** (for future phases):
| Constant | Path |
|----------|------|
| `geofences` | `/geofences` |
| `geofenceAdd` | `/geofences/add` |
| `geofenceEdit` | `/geofences/:id/edit` |
| `alerts` | `/alerts` |
| `alertDetail` | `/alerts/:id` |
| `profile` | `/settings/profile` |

---

### Environment Banner (`core/widgets/environment_banner.dart`)

Shows "DEV" banner in top-right corner for non-production builds.

**Usage** (already in `app.dart`):
```dart
MaterialApp(
  builder: (context, child) => EnvironmentBanner(child: child!),
)
```

**Behavior**:
- Shows orange "DEV" banner when `EnvironmentConfig.isDev`
- Hidden in production (`EnvironmentConfig.isProd`)

---

### Dependencies (from pubspec.yaml)

| Category | Package | Version |
|----------|---------|---------|
| **Firebase** | firebase_core | ^3.8.1 |
| | firebase_auth | ^5.3.4 |
| | cloud_firestore | ^5.6.0 |
| | firebase_database | ^11.2.0 |
| | firebase_storage | ^12.4.0 |
| | firebase_messaging | ^15.2.0 |
| **State** | flutter_bloc | ^8.1.6 |
| | equatable | ^2.0.7 |
| **DI** | get_it | ^8.0.3 |
| **Maps** | google_maps_flutter | ^2.10.0 |
| | geolocator | ^13.0.2 |
| | geocoding | ^3.0.0 |
| **Background** | flutter_background_service | ^5.1.0 |
| | workmanager | ^0.7.0 |
| **Network** | dartz | ^0.10.1 |
| | connectivity_plus | ^6.1.1 |
| **Storage** | shared_preferences | ^2.3.4 |
| **Routing** | go_router | ^14.6.3 |
| **UI** | flutter_svg | ^2.0.16 |
| | cached_network_image | ^3.4.1 |
| | shimmer | ^3.0.0 |
| | flutter_spinkit | ^5.2.1 |
| **Utils** | intl | ^0.20.2 |
| | uuid | ^4.5.1 |
| | permission_handler | ^11.3.1 |
| **Image** | image_picker | ^1.0.7 |
| | flutter_image_compress | ^2.1.0 |
| **Notifications** | flutter_local_notifications | ^18.0.1 |
| **Dev** | bloc_test | ^9.1.7 |
| | mocktail | ^1.0.4 |

---

## Feature: Vehicles (Phase 4)
**Status**: Complete  
**Location**: `lib/features/vehicles/`

### Screens
| Screen | Route | Description |
|--------|-------|-------------|
| `VehiclesPage` | `/home/vehicles` | Grid view of user's vehicles |
| `VehicleDetailPage` | `/home/vehicles/:id` | Vehicle details with tracker status |
| `VehicleFormPage` | `/home/vehicles/add`, `/home/vehicles/:id/edit` | Create/edit vehicle |
| `LinkTrackerPage` | `/home/vehicles/:id/link-tracker` | Link GPS tracker via IMEI |

### BLoC Pattern

**VehiclesBloc** - Vehicle list management
```dart
// Events
LoadVehicles()
StartWatchingVehicles()
StopWatchingVehicles()
DeleteVehicleRequested(vehicleId)
RefreshVehicles()
ClearVehiclesError()

// States (VehiclesStatus enum)
initial, loading, loaded, error, deleting, deleted
```

**VehicleFormBloc** - Create/edit form
```dart
// Events
LoadVehicleForEdit(vehicleId)
SubmitVehicleForm(name, plateNumber, brand?, model?, year?, color?)
AddVehicleImage(filePath)
RemoveVehicleImage(imageUrl)
ResetVehicleForm()
ClearFormError()

// States (VehicleFormStatus enum)
initial, loading, loaded, submitting, success, error, uploadingImage, deletingImage
```

**TrackerLinkBloc** - Link/unlink tracker
```dart
// Events
ValidateImei(imei)
LinkTrackerToVehicle(vehicleId, imei)
UnlinkTrackerFromVehicle(vehicleId)
ResetTrackerLink()
ClearTrackerError()

// States (TrackerLinkStatus enum)
initial, validating, valid, invalid, linking, linked, unlinking, unlinked, error
```

### Domain Layer

**Entities**:
```dart
VehicleEntity {
  String id;
  String name;              // Required
  String plateNumber;       // Required
  String? brand;
  String? model;
  int? year;
  String? color;
  List<String> imageUrls;   // Max 5 images
  String? trackerId;        // IMEI, null if no tracker
  DateTime? trackerLinkedAt;
  DateTime createdAt;
  DateTime updatedAt;
  
  // Computed
  bool hasTracker;
  bool canAddMoreImages;
  int remainingImageSlots;
  String? primaryImageUrl;
}

TrackerInfoEntity {
  String imei;
  String? model;
  String? provider;
  String? ownerId;
  DateTime? linkedAt;
  
  bool isAvailable;
}

TrackerLiveEntity {
  String imei;
  int battery;
  double lat, lng;
  double speed;
  bool online;
  DateTime datetime;
}

TrackerStatusEntity {
  String imei;
  int battery;
  bool online;
  double speed;
  DateTime lastUpdate;
}
```

**Use Cases**:
| UseCase | Params | Returns |
|---------|--------|---------|
| `GetVehicles` | `NoParams` | `List<VehicleEntity>` |
| `GetVehicleById` | `IdParams(id)` | `VehicleEntity` |
| `WatchVehicles` | `NoParams` | `Stream<List<VehicleEntity>>` |
| `CreateVehicle` | `CreateVehicleParams(...)` | `VehicleEntity` |
| `UpdateVehicle` | `UpdateVehicleParams(...)` | `VehicleEntity` |
| `DeleteVehicle` | `IdParams(id)` | `void` |
| `UploadVehicleImage` | `UploadImageParams(vehicleId, filePath)` | `String` (URL) |
| `DeleteVehicleImage` | `DeleteImageParams(vehicleId, imageUrl)` | `void` |
| `LinkTracker` | `LinkTrackerParams(vehicleId, trackerId)` | `VehicleEntity` |
| `UnlinkTracker` | `IdParams(vehicleId)` | `VehicleEntity` |
| `GetTrackerInfo` | `ImeiParams(imei)` | `TrackerInfoEntity` |
| `IsTrackerAvailable` | `ImeiParams(imei)` | `bool` |

### Data Layer

**Firestore Collection**: `users/{uid}/vehicles/{vehicleId}`
```json
{
  "name": "string",
  "plateNumber": "string",
  "brand": "string | null",
  "model": "string | null",
  "year": "number | null",
  "color": "string | null",
  "imageUrls": ["string"],
  "trackerId": "string | null",
  "trackerLinkedAt": "Timestamp | null",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}
```

**Firebase Storage Path**: `vehicles/{userId}/{vehicleId}/{uuid}.jpg`

**RTDB Structure** (tracker data from external GPS):
```
trackers_info/{imei}/
  imei, model, provider, ownerId, linkedAt

trackers_live/{imei}/
  imei, battery, lat, lng, speed, online, datetime, ts

trackers_status/{imei}/
  battery, online, speed, lastUpdate
```

### Reusable Widgets

**VehicleCard** - Grid card with image, name, plate, tracker indicator
```dart
VehicleCard(
  vehicle: vehicle,
  onTap: () {},
  onLongPress: () {},
)
```

**VehiclesEmptyState** - Empty state with "Add Vehicle" CTA
```dart
VehiclesEmptyState(onAddVehicle: () {})
```

**DeleteVehicleDialog** - Confirmation dialog (warns about tracker unlink)
```dart
showDeleteVehicleDialog(context, vehicle) // Returns bool?
```

**VehicleImagePicker** - Horizontal image list with add/remove
```dart
VehicleImagePicker(
  vehicle: vehicle,
  imageUrls: urls,
  isUploading: false,
  uploadingIndex: null,
  onImageAdded: (path) {},
  onImageRemoved: (url) {},
  enabled: true,
)
```

**TrackerStatusCard** - Shows tracker status or link CTA
```dart
TrackerStatusCard(
  vehicle: vehicle,
  trackerStatus: status,
  isLoading: false,
  onLinkTracker: () {},
  onUnlinkTracker: () {},
)
```

**VehicleFormFields** - Reusable form fields with color picker
```dart
VehicleFormFields(
  nameController: _name,
  plateNumberController: _plate,
  brandController: _brand,
  modelController: _model,
  yearController: _year,
  selectedColor: 'White',
  onColorChanged: (color) {},
  enabled: true,
)
```

---

## Feature: Home Dashboard
**Status**: Complete  
**Location**: `lib/features/home/`

**HomePage** - Shell with bottom NavigationBar
- Uses GoRouter ShellRoute
- 3 tabs: Vehicles, Map, Settings

**AppNavigationBar** - Material 3 NavigationBar
- Icons: directions_car, map, settings

---

## Feature: Settings
**Status**: Basic (Phase 4)  
**Location**: `lib/features/settings/`

**SettingsPage** - User info + sign out
- User avatar and info header
- Placeholder links for Profile, Notifications, Speed Alerts, Geofences
- About dialog
- Sign out with confirmation

---

## Feature: Map (Phase 5)
**Status**: Complete  
**Location**: `lib/features/map/`

### Screens
| Screen | Route | Description |
|--------|-------|-------------|
| `MapPage` | `/home/map` | Real-time vehicle tracking map with Google Maps |

### BLoC Pattern

**MapBloc** - Real-time map state management
```dart
// Events
StartWatchingLocations()     // Start real-time location stream
StopWatchingLocations()      // Stop watching
LocationsUpdated(locations)  // Internal: when locations update
LocationsError(message)      // Internal: when error occurs
SelectVehicle(vehicle)       // Select vehicle for focus/details
ClearVehicleSelection()      // Deselect vehicle
LoadTripHistory(startDate, endDate)  // Load trip history
ClearTripHistory()           // Clear trip data
StartTripPlayback()          // Start trip replay
PauseTripPlayback()          // Pause replay
StopTripPlayback()           // Stop and reset replay
UpdatePlaybackPosition(position)  // Seek to position
ClearMapError()              // Clear error state
ToggleTrafficLayer()         // Toggle traffic overlay
ChangeMapType(mapType)       // Switch map type

// States (MapStatus enum)
initial, loading, loaded, error

// TripStatus enum
initial, loading, loaded, error

// PlaybackStatus enum
idle, playing, paused

// MapViewType enum
normal, satellite, terrain, hybrid
```

**State Helpers**:
```dart
state.isLoading              // bool
state.isLoaded               // bool
state.hasError               // bool
state.hasSelectedVehicle     // bool
state.hasTripHistory         // bool
state.isPlaying              // bool
state.isPaused               // bool
state.onlineVehicleCount     // int
state.movingVehicleCount     // int
state.currentPlaybackPoint   // TripPointEntity?
state.playbackProgress       // double (0.0-1.0)
```

### Domain Layer

**Entities**:
```dart
VehicleLocationEntity {
  String vehicleId;
  String vehicleName;
  String plateNumber;
  String? color;
  String? imageUrl;
  String trackerId;
  double latitude, longitude;
  double speed;
  int battery;
  bool isOnline;
  DateTime lastUpdate;
  
  // Computed
  bool isMoving;
  bool isIdle;
  bool isBatteryLow;
  VehicleStatus status;       // moving, idle, offline
  String formattedSpeed;
  String formattedCoordinates;
}

TripPointEntity {
  DateTime timestamp;
  double latitude, longitude;
  double speed;
  int battery;
}

TripEntity {
  String vehicleId;
  String trackerId;
  DateTime startTime, endTime;
  List<TripPointEntity> points;
  
  // Computed
  Duration duration;
  double totalDistanceKm;
  double averageSpeed;
  double maxSpeed;
}
```

**Use Cases**:
| UseCase | Params | Returns |
|---------|--------|---------|
| `GetVehicleLocations` | `NoParams` | `List<VehicleLocationEntity>` |
| `WatchVehicleLocations` | `NoParams` | `Stream<List<VehicleLocationEntity>>` |
| `GetVehicleLocation` | `IdParams(id)` | `VehicleLocationEntity` |
| `WatchVehicleLocation` | `IdParams(id)` | `Stream<VehicleLocationEntity>` |
| `GetTripHistory` | `TripHistoryParams(vehicleId, startDate, endDate)` | `TripEntity` |
| `GetDayTripPoints` | `DayTripParams(vehicleId, date)` | `List<TripPointEntity>` |

### Data Layer

**Data Flow**:
1. `MapRemoteDataSource` combines Firestore vehicle data with RTDB tracker live data
2. Streams Firestore `vehicles` collection + RTDB `trackers_live/{imei}` for each vehicle
3. Trip history reads from RTDB `trackers_history/{imei}` with timestamp range query

**RTDB Structure** (referenced from Phase 4):
```
trackers_live/{imei}/
  battery, lat, lng, speed, online, datetime, ts

trackers_history/{imei}/{timestamp}/
  battery, lat, lng, speed, datetime, ts
```

### Widgets

**MapPage** - Full-screen map with:
- Google Maps with vehicle markers (color-coded by status)
- Top bar with vehicle counts (total, online, moving)
- Sliding vehicle list panel (left side)
- Map controls (right side: zoom, map type, traffic, fit bounds)
- Vehicle info card (bottom sheet when vehicle selected)

**VehicleListPanel** - Sliding panel with vehicle list
```dart
VehicleListPanel(
  vehicles: locations,
  selectedVehicle: selected,
  onVehicleSelected: (v) {},
  onClose: () {},
)
```

**VehicleInfoCard** - Bottom sheet with vehicle details
```dart
VehicleInfoCard(
  vehicle: location,
  onClose: () {},
  onViewHistory: () {},
  onNavigate: () {},
)
```

**MapControls** - Floating control buttons
```dart
MapControls(
  mapType: MapViewType.normal,
  showTraffic: false,
  onZoomIn: () {},
  onZoomOut: () {},
  onMyLocation: () {},
  onFitBounds: () {},
  onToggleTraffic: () {},
  onMapTypeChanged: (type) {},
)
```

### Features
- Real-time vehicle positions with color-coded markers (blue=moving, orange=idle, red=offline)
- Vehicle list with status indicators and live speed
- Vehicle info card with speed, battery, last update time
- Map controls: zoom, map type selector, traffic toggle, fit all vehicles
- **My Location button** - Gets current GPS position with permission handling
- Blue dot overlay showing user's current location (when permission granted)
- Trip history date picker (loads from RTDB)
- Playback controls for trip replay (pending full implementation)

### My Location Implementation
The "My Location" button uses `geolocator` package with the reusable permission system:

```dart
// In MapPage
Future<void> _goToMyLocation() async {
  // 1. Check/request location permission via AppPermissionHandler
  // 2. Check if location services enabled
  // 3. Get current position with Geolocator.getCurrentPosition()
  // 4. Animate map camera to user's location
  // 5. If permanently denied, show dialog to open settings
}
```

**State Variables**:
- `_locationPermissionGranted` - Enables `myLocationEnabled` on GoogleMap
- `_isGettingLocation` - Prevents multiple simultaneous requests

### Next Steps (Phase 6)
- Full trip playback with polyline animation
- Navigation integration (Google Maps / Apple Maps)
- Geofencing zones on map

---

## Core: Permissions System
**Location**: `lib/core/permissions/`

**AppPermission** enum: camera, photos, location, locationAlways, notification, storage

**AppPermissionStatus** enum: granted, denied, permanentlyDenied, restricted, limited, unknown

**AppPermissionHandler** - Abstract interface
```dart
Future<AppPermissionStatus> checkPermission(permission)
Future<AppPermissionStatus> requestPermission(permission)
Future<Map<...>> requestPermissions(permissions)
Future<bool> isGranted(permission)
Future<bool> openSettings()
Future<bool> ensurePermission(permission)  // Check + request if needed
```

**PermissionDeniedWidget** - Full-screen permission denied UI
**PermissionDeniedBanner** - Compact inline banner

---

## Core: Image Compression
**Location**: `lib/core/utils/image_compressor.dart`

**ImageCompressor** - Compresses images before upload
```dart
Future<String> compressImage(filePath, quality: 70, maxWidth: 1080, maxHeight: 1080)
Future<List<String>> compressImages(filePaths, ...)
Future<Uint8List?> compressBytes(bytes, ...)
Future<Uint8List?> compressFileToBytes(filePath, ...)
```
