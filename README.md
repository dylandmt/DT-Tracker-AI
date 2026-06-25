# DT Tracker

Real-time GPS Vehicle Tracking App built with Flutter and Firebase.

## Features

- Email/Password Authentication
- Real-time GPS Tracking (coming soon)
- Geofencing (coming soon)
- Speed Alerts (coming soon)
- Push Notifications (coming soon)

## Architecture

This project follows **Clean Architecture** with:

- **Presentation Layer**: BLoC pattern for state management
- **Domain Layer**: Use cases and entities
- **Data Layer**: Repositories, data sources, and models

## Setup

### 1. Firebase Configuration

Add your Firebase configuration files:

- **Android**: `android/app/google-services.json`
- **iOS**: `ios/Runner/GoogleService-Info.plist`

### 2. Google Maps API Key

Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` in:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

### 3. Enable Firebase Services

In Firebase Console, enable:

- Authentication (Email/Password)
- Cloud Firestore
- Realtime Database
- Cloud Storage

### 4. Run the App

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── theme/
│   ├── usecases/
│   └── utils/
├── features/
│   └── auth/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── config/
│   └── router/
├── main.dart
├── app.dart
└── injection_container.dart
```

## Tech Stack

- Flutter
- Firebase (Auth, Firestore, Realtime DB, Storage, Messaging)
- BLoC for state management
- GetIt for dependency injection
- GoRouter for navigation
- Google Maps Flutter

## License

MIT License
