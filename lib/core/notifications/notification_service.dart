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
    if (_initialized || (!Platform.isAndroid && !Platform.isIOS)) return;
    _initialized = true;

    if (Platform.isAndroid) {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = NotificationPayload.tryFromJson(response.payload);
          if (payload != null) _notificationActions.add(payload);
        },
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        'Geofence alerts',
        description: 'Notifications when a vehicle enters or exits a geofence.',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      _registerToken,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM token refresh failed: $error');
      },
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleOpenedMessage(initialMessage);

    if ((await notificationPermissionStatus()).isGranted) {
      await _syncCurrentToken();
    }
  }

  Future<AppPermissionStatus> notificationPermissionStatus() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return AppPermissionStatus.denied;
    }

    final settings = await _messaging.getNotificationSettings();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => AppPermissionStatus.granted,
      AuthorizationStatus.denied => AppPermissionStatus.denied,
      AuthorizationStatus.notDetermined => AppPermissionStatus.unknown,
    };
  }

  /// This is the sole notification permission request in the setup flow.
  Future<AppPermissionStatus> requestPermissionAndRegister() async {
    await initialize();
    if (!Platform.isAndroid && !Platform.isIOS) {
      return AppPermissionStatus.denied;
    }

    final currentStatus = await notificationPermissionStatus();
    if (currentStatus.isGranted) {
      await _syncCurrentToken();
      return currentStatus;
    }

    final settings = await _messaging.requestPermission();
    final status = switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => AppPermissionStatus.granted,
      AuthorizationStatus.denied => AppPermissionStatus.denied,
      AuthorizationStatus.notDetermined => AppPermissionStatus.unknown,
    };
    if (status.isGranted) await _syncCurrentToken();
    return status;
  }

  Future<void> _syncCurrentToken() async {
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('FCM token is unavailable');
      return;
    }

    if (kDebugMode && const bool.fromEnvironment('LOG_FCM_TOKEN')) {
      debugPrint('FCM token: $token');
    } else {
      debugPrint('FCM token available: true');
    }
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    try {
      final deviceId = await _getDeviceId();
      await _backendDataSource.registerPushToken(
        deviceId: deviceId,
        pushToken: token,
      );
      debugPrint('FCM device registration succeeded');
    } catch (error) {
      // The backend endpoint may not be deployed yet; FCM remains usable.
      debugPrint('FCM device registration deferred: $error');
    }
  }

  Future<String> _getDeviceId() async {
    final existingId = _preferences.getString(_deviceIdKey);
    if (existingId != null && existingId.isNotEmpty) return existingId;

    final deviceId = _uuid.v4();
    await _preferences.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final payload = NotificationPayload.fromData(message.data);
    if (!payload.isGeofenceEvent) return;

    debugPrint('FCM foreground event: ${payload.type}');
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      message.notification?.title ?? 'DT Tracker',
      message.notification?.body ?? 'Geofence alert received.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Geofence alerts',
          channelDescription:
              'Notifications when a vehicle enters or exits a geofence.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload.toJson(),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    final payload = NotificationPayload.fromData(message.data);
    if (!payload.isGeofenceEvent) return;

    debugPrint('FCM notification opened: ${payload.type}');
    _notificationActions.add(payload);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _notificationActions.close();
  }
}
