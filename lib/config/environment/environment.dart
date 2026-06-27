enum Environment {
    dev,
    prod,
}

class EnvironmentConfig {
    EnvironmentConfig._();

    /// Current environment, determined at build time
    static const String _envString = String.fromEnvironment('ENV',defaultValue: 'dev',);
    /// Parsed environment enum
    static Environment get current {
        switch (_envString.toLowerCase()) {
        case 'prod':
        case 'production':
            return Environment.prod;
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
        case Environment.prod:
            return 'dttracker-prod';
        }
    }

     /// Realtime Database URL
    static String get realtimeDatabaseUrl {
        switch (current) {
        case Environment.dev:
            // TODO: Confirm full URL format from Firebase Console
            return 'https://dttracker-dev-01.firebaseio.com';
        case Environment.prod:
            return 'https://dttracker-prod-01.firebaseio.com';
        }
    }

    /// Storage URL
    static String get storageUrl {
        switch (current) {
        case Environment.dev:
            return 'gs://dttracker-dev-01';
        case Environment.prod:
            return 'gs://dttracker-prod-01';
        }
    }
}