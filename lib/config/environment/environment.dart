enum Environment { dev, staging, prod }

class EnvironmentConfig {
  EnvironmentConfig._();

  /// Current environment, determined at build time
  static const String _envString = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  /// Parsed environment enum
  static Environment get current {
    switch (_envString.toLowerCase()) {
      case 'prod':
      case 'production':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      case 'dev':
      case 'development':
      default:
        return Environment.dev;
    }
  }

  /// Check if running in development
  static bool get isDev => current == Environment.dev;

  /// Check if running in production
  static bool get isProd => current == Environment.prod;

  /// Environment display name (for UI banner/logging)
  static String get name => isDev ? 'Development' : 'Production';

  /// Firestore database ID
  static String get firestoreDatabase {
    switch (current) {
      case Environment.dev:
        return 'dttracker-dev';
      case Environment.staging:
        return 'dttracker-staging';
      case Environment.prod:
        return 'dttracker-prod';
    }
  }

  /// Realtime Database URL
  static String get realtimeDatabaseUrl {
    switch (current) {
      case Environment.dev:
        return 'https://dttracker-dev-01.firebaseio.com';
      case Environment.staging:
        return 'https://dttracker-staging-01.firebaseio.com';
      case Environment.prod:
        return 'https://dttracker-prod-01.firebaseio.com';
    }
  }

  /// Storage URL
  static String get storageUrl {
    switch (current) {
      case Environment.dev:
        return 'gs://dttracker-dev-01';
      case Environment.staging:
        return 'gs://dttracker-staging-01';
      case Environment.prod:
        return 'gs://dttracker-prod-01';
    }
  }

  /// Backend API base URL for secure operations
  static String get apiBaseUrl {
    switch (current) {
      case Environment.dev:
        return 'https://dev.dt-tracker.com/api/v1';
      case Environment.staging:
        return 'https://staging.dt-tracker.com/api/v1';
      case Environment.prod:
        return 'https://api.dt-tracker.com/api/v1';
    }
  }
}
