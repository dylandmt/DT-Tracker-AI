import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../permissions/permission_status.dart';
import 'notification_payload.dart';
import 'push_device_backend_datasource.dart';

class NotificationService {
  static const _deviceIdKey = 'push_device_id';
  static const _channelId = 'dt_tracker_geofence';

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final SharedPreferences _preferences;
  final Uuid _uuid;
  final PushDeviceBackendDataSource _backendDataSource;

  final _notificationActions =
      StreamController<NotificationPayload>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;

  bool _initialized = false;

  NotificationService({
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required SharedPreferences preferences,
    required Uuid uuid,
    required PushDeviceBackendDataSource backendDataSource,
  }) : _messaging = messaging,
       _localNotifications = localNotifications,
       _preferences = preferences,
       _uuid = uuid,
       _backendDataSource = backendDataSource;

  Stream<NotificationPayload> get notificationActions =>
      _notificationActions.stream;

  Future<void> initialize() async {
    if (
        _initialized ||
        (!Platform.isAndroid && !Platform.isIOS)
    ) {
      return;
    }

    _initialized = true;

    debugPrint(
      '[PUSH] Initializing notification service '
      'platform=${Platform.isIOS ? 'ios' : 'android'}',
    );

    if (Platform.isAndroid) {
      const initializationSettings =
          InitializationSettings(
        android: AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        ),
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload =
              NotificationPayload.tryFromJson(
            response.payload,
          );

          if (payload != null) {
            _notificationActions.add(payload);
          }
        },
      );

      const channel =
          AndroidNotificationChannel(
        _channelId,
        'Geofence alerts',
        description:
            'Notifications when a vehicle enters or exits a geofence.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            channel,
          );
    }

    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    _openedAppSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );

    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen(
      (token) {
        debugPrint(
          '[PUSH] FCM token refresh received',
        );

        _registerToken(token);
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          '[PUSH] FCM token refresh failed: $error',
        );
      },
    );

    /*
 * Do not block push-token initialization while waiting
 * for a possible notification that launched the app.
 */
unawaited(
  _processInitialMessage(),
);

try {
      debugPrint(
        '[PUSH] Checking notification settings before token sync',
      );

      final settings =
          await _messaging.getNotificationSettings();

      debugPrint(
        '[PUSH] initialize authorizationStatus='
        '${settings.authorizationStatus}',
      );

      final isGranted =
          settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus ==
              AuthorizationStatus.provisional;

      debugPrint(
        '[PUSH] initialize permission granted=$isGranted',
      );

      if (isGranted) {
        debugPrint(
          '[PUSH] Permission granted, calling _syncCurrentToken()',
        );

        await _syncCurrentToken();

        debugPrint(
          '[PUSH] _syncCurrentToken() completed',
        );
      } else {
        debugPrint(
          '[PUSH] Token sync skipped because '
          'notification permission is not granted',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[PUSH] initialize token synchronization failed: $error',
      );

      debugPrint(
        '[PUSH] initialize stackTrace=$stackTrace',
      );
    }
  }

  Future<AppPermissionStatus>
  notificationPermissionStatus() async {
    if (
        !Platform.isAndroid &&
        !Platform.isIOS
    ) {
      return AppPermissionStatus.denied;
    }

    final settings =
        await _messaging
            .getNotificationSettings();

    debugPrint(
      '[PUSH] Firebase authorizationStatus='
      '${settings.authorizationStatus}',
    );

    return switch (
        settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        AppPermissionStatus.granted,

      AuthorizationStatus.denied =>
        AppPermissionStatus.denied,

      AuthorizationStatus.notDetermined =>
        AppPermissionStatus.unknown,
    };
  }

  /// This is the sole notification permission request
  /// in the setup flow.
  Future<AppPermissionStatus>
  requestPermissionAndRegister() async {
    await initialize();

    if (
        !Platform.isAndroid &&
        !Platform.isIOS
    ) {
      return AppPermissionStatus.denied;
    }

    final currentStatus =
        await notificationPermissionStatus();

    debugPrint(
      '[PUSH] requestPermissionAndRegister '
      'currentStatus=${currentStatus.name}',
    );

    if (currentStatus.isGranted) {
      await _syncCurrentToken();
      return currentStatus;
    }

    debugPrint(
      '[PUSH] Requesting notification permission',
    );

    final settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final status = switch (
        settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        AppPermissionStatus.granted,

      AuthorizationStatus.denied =>
        AppPermissionStatus.denied,

      AuthorizationStatus.notDetermined =>
        AppPermissionStatus.unknown,
    };

    debugPrint(
      '[PUSH] Permission request result='
      '${status.name}',
    );

    if (status.isGranted) {
      await _syncCurrentToken();
    }

    return status;
  }

  Future<void> _syncCurrentToken() async {
    debugPrint(
      '[PUSH] Starting current token sync',
    );

    if (Platform.isIOS) {
      String? apnsToken;

      try {
        debugPrint(
          '[PUSH] Requesting APNs token',
        );

        apnsToken =
            await _messaging.getAPNSToken();

        debugPrint(
          '[PUSH] getAPNSToken() returned',
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[PUSH] Failed to obtain APNs token: '
          '$error',
        );

        debugPrint(
          '[PUSH] APNs stackTrace=$stackTrace',
        );
      }

      final apnsAvailable =
          apnsToken != null &&
          apnsToken.isNotEmpty;

      debugPrint(
        '[PUSH] APNs token available=$apnsAvailable',
      );

      if (!apnsAvailable) {
        debugPrint(
          '[PUSH] FCM token sync deferred because '
          'APNs token is not available yet',
        );

        return;
      }
    }

    String? token;

    try {
      debugPrint(
        '[PUSH] Requesting FCM token',
      );

      token =
          await _messaging.getToken();

      debugPrint(
        '[PUSH] getToken() returned',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[PUSH] Failed to obtain FCM token: '
        '$error',
      );

      debugPrint(
        '[PUSH] FCM token stackTrace=$stackTrace',
      );

      return;
    }

    if (
        token == null ||
        token.isEmpty
    ) {
      debugPrint(
        '[PUSH] FCM token is unavailable',
      );

      return;
    }

    if (
        kDebugMode &&
        const bool.fromEnvironment(
          'LOG_FCM_TOKEN',
        )
    ) {
      debugPrint(
        '[PUSH] FCM token: $token',
      );
    } else {
      debugPrint(
        '[PUSH] FCM token available: true',
      );

      debugPrint(
        '[PUSH] FCM token length=${token.length}',
      );
    }

    await _registerToken(
      token,
    );
  }

  Future<void> _registerToken(
    String token,
  ) async {
    try {
      final deviceId =
          await _getDeviceId();

      debugPrint(
        '[PUSH] Registering FCM installation '
        'deviceId=$deviceId',
      );

      await _backendDataSource
          .registerPushToken(
        deviceId: deviceId,
        pushToken: token,
      );

      debugPrint(
        '[PUSH] FCM device registration succeeded',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[PUSH] FCM device registration deferred: '
        '$error',
      );

      debugPrint(
        '[PUSH] Registration stackTrace=$stackTrace',
      );
    }
  }

  Future<String> _getDeviceId() async {
    final existingId =
        _preferences.getString(
      _deviceIdKey,
    );

    if (
        existingId != null &&
        existingId.isNotEmpty
    ) {
      return existingId;
    }

    final deviceId =
        _uuid.v4();

    await _preferences.setString(
      _deviceIdKey,
      deviceId,
    );

    return deviceId;
  }

  Future<void> _handleForegroundMessage(
    RemoteMessage message,
  ) async {
    final payload =
        NotificationPayload.fromData(
      message.data,
    );

    if (!payload.isGeofenceEvent) {
      return;
    }

    debugPrint(
      '[PUSH] FCM foreground event: '
      '${payload.type}',
    );

    if (Platform.isAndroid) {
      await _localNotifications.show(
        DateTime.now()
            .millisecondsSinceEpoch
            .remainder(
              1 << 31,
            ),
        message.notification?.title ??
            'DT Tracker',
        message.notification?.body ??
            'Geofence alert received.',
        const NotificationDetails(
          android:
              AndroidNotificationDetails(
            _channelId,
            'Geofence alerts',
            channelDescription:
                'Notifications when a vehicle enters or exits a geofence.',
            importance:
                Importance.high,
            priority:
                Priority.high,
          ),
        ),
        payload:
            payload.toJson(),
      );
    }
  }

  void _handleOpenedMessage(
    RemoteMessage message,
  ) {
    final payload =
        NotificationPayload.fromData(
      message.data,
    );

    if (!payload.isGeofenceEvent) {
      return;
    }

    debugPrint(
      '[PUSH] FCM notification opened: '
      '${payload.type}',
    );

    _notificationActions.add(
      payload,
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription
        ?.cancel();

    await _foregroundSubscription
        ?.cancel();

    await _openedAppSubscription
        ?.cancel();

    await _notificationActions.close();
  }

  Future<void> _processInitialMessage() async {
  try {
    debugPrint(
      '[PUSH] Checking initial FCM message',
    );

    final initialMessage =
        await _messaging
            .getInitialMessage()
            .timeout(
              const Duration(
                seconds: 5,
              ),
            );

    debugPrint(
      '[PUSH] Initial FCM message check completed '
      'hasMessage=${initialMessage != null}',
    );

    if (initialMessage != null) {
      _handleOpenedMessage(
        initialMessage,
      );
    }
  } on TimeoutException {
    debugPrint(
      '[PUSH] Initial FCM message check timed out',
    );
  } catch (error, stackTrace) {
    debugPrint(
      '[PUSH] Initial FCM message check failed: $error',
    );

    debugPrint(
      '[PUSH] Initial message stackTrace=$stackTrace',
    );
  }
}

}