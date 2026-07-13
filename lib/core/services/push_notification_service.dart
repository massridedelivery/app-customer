import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/router/app_routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(ref),
);

/// Receives FCM messages and routes notification taps through the same
/// deeplink paths the router already supports (see docs/deeplinks.md).
///
/// Backend payload contract: `data: {"deeplink": "/promos/123"}` — a path
/// matching a route in lib/router/app_routes.dart.
class PushNotificationService {
  PushNotificationService(this._ref) {
    // Register the device on every login (all login paths flip this flag).
    _ref.listen(authControllerProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        _requestPermissionAndRegister();
      }
    });
  }

  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Must match com.google.firebase.messaging.default_notification_channel_id
  /// in AndroidManifest.xml so background and foreground notifications land
  /// in the same channel.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'massmove_default',
    'การแจ้งเตือน',
    description: 'สถานะออเดอร์ การเดินทาง และข้อความจากคนขับ',
    importance: Importance.high,
  );

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool _initialized = false;

  Future<void> init() async {
    if (!_isSupportedPlatform || _initialized) return;
    _initialized = true;

    // iOS shows foreground notifications natively with these options;
    // Android needs the local-notifications plugin (below).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permissions are requested after login via FirebaseMessaging.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _openDeeplink(response.payload),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // App opened from terminated state by tapping a notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    _messaging.onTokenRefresh.listen((token) {
      if (_ref.read(authControllerProvider).isAuthenticated) {
        _registerToken(token);
      }
    });

    // Session restored from storage before this service existed.
    if (_ref.read(authControllerProvider).isAuthenticated) {
      await _requestPermissionAndRegister();
    }
  }

  /// Called from AuthController.logout() while the session is still valid so
  /// the backend can drop this device's token.
  Future<void> unregisterOnLogout() async {
    if (!_isSupportedPlatform) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _ref.read(apiRepositoryProvider).unregisterDeviceToken(token);
      }
    } catch (e) {
      debugPrint('Push: unregister failed (ignored): $e');
    }
    try {
      // Invalidate the token client-side so stale server copies stop working.
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Push: deleteToken failed (ignored): $e');
    }
  }

  Future<void> _requestPermissionAndRegister() async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await _messaging.getToken();
      if (token != null) {
        // Handy for sending test messages from the Firebase console.
        debugPrint('Push: FCM token: $token');
        await _registerToken(token);
      }
    } catch (e) {
      debugPrint('Push: permission/registration failed (ignored): $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _ref
          .read(apiRepositoryProvider)
          .registerDeviceToken(
            token: token,
            platform: defaultTargetPlatform == TargetPlatform.iOS
                ? 'ios'
                : 'android',
          );
    } catch (e) {
      // TODO(backend): endpoint not live yet — login must keep working.
      debugPrint('Push: token registration failed (ignored): $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return; // Data-only: nothing to display.

    final deeplink = message.data['deeplink'] as String?;
    // Skip the banner when the user is already on the target screen — the
    // WebSocket-driven UI is the source of truth there.
    if (deeplink != null) {
      try {
        if (_ref.read(routerProvider).state.uri.toString() == deeplink) {
          return;
        }
      } catch (_) {
        // Router not ready yet — show the banner anyway.
      }
    }

    // iOS presents foreground notifications itself (options set in init()).
    if (defaultTargetPlatform != TargetPlatform.android) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: deeplink,
    );
  }

  void _handleMessageTap(RemoteMessage message) =>
      _openDeeplink(message.data['deeplink'] as String?);

  void _openDeeplink(String? deeplink) {
    if (deeplink == null || !deeplink.startsWith('/')) return;
    // go() runs the router redirect, so splash/auth gating and the
    // pending-link stash apply exactly like massmove:// deeplinks.
    _ref.read(routerProvider).go(deeplink);
  }
}
