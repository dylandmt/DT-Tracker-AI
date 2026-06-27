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

**Pinned versions in `android/build.gradle.kts`** - required for compatibility:
- AGP 8.7.3, Kotlin 2.1.0
- `androidx.core:core` pinned to 1.15.0
- `kotlin-stdlib` pinned to 2.1.0
- `android-maps-utils` pinned to 4.0.0

If build fails with version conflicts, check these pins first.

**If Gradle cache corrupts**, run:
```bash
cd android && ./gradlew --stop
rm -rf ~/.gradle/caches/8.10.2 android/.gradle
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

- **Phase 1-3 Complete**: Project setup, auth feature
- **Phase 4 Next**: Vehicles feature (CRUD, images, device linking)
- **Future**: Real-time tracking (Phase 5), Geofencing (Phase 6), Alerts (Phase 7)
