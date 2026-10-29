import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/ride_ongoing_notification.dart';
import 'package:customer_app/features/call/presentation/call_controller.dart';
import 'package:customer_app/features/chat/domain/chat_room_ids.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/inbox/presentation/inbox_controller.dart';
import 'package:customer_app/router/app_routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>(
  (ref) => PushNotificationService(ref),
);

/// The customer turned notifications off for the app (iOS, Android 13+). The
/// token is still registered; the inbox shows how to turn them back on.
final pushPermissionDeniedProvider =
    NotifierProvider<PushPermissionDenied, bool>(PushPermissionDenied.new);

class PushPermissionDenied extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool denied) => state = denied;
}

/// Removes a chat's delivered notifications (the FCM ones and ours) — called
/// when that chat opens. A chat push is keyed on its `room_id`: the iOS
/// `thread-id` and the Android notification tag (id 0).
final chatNotificationsProvider = Provider<ChatNotifications>(
  (ref) => ChatNotifications(),
);

class ChatNotifications {
  static const _ios = MethodChannel('massmove/notifications');

  Future<void> clear(String roomId) async {
    if (kIsWeb || roomId.isEmpty) return;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _ios.invokeMethod<void>('removeDelivered', roomId);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await FlutterLocalNotificationsPlugin().cancel(id: 0, tag: roomId);
      }
    } catch (e) {
      debugPrint('Push: clearing chat notifications failed (ignored): $e');
    }
  }
}

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
  AppLifecycleListener? _lifecycle;

  Future<void> _refreshPermission() async {
    if (!_ref.read(authControllerProvider).isAuthenticated) return;
    try {
      final settings = await _messaging.getNotificationSettings();
      _ref
          .read(pushPermissionDeniedProvider.notifier)
          .set(settings.authorizationStatus == AuthorizationStatus.denied);
    } catch (_) {}
  }

  Future<void> init() async {
    if (!_isSupportedPlatform || _initialized) return;
    _initialized = true;

    // Back from Settings, where notifications may have been turned on.
    _lifecycle = AppLifecycleListener(onResume: _refreshPermission);
    _ref.onDispose(() => _lifecycle?.dispose());

    // While the app is open both platforms show pushes through the
    // local-notifications plugin (below), so a chat already on screen can be
    // left out; iOS's own foreground presentation would show every one.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
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
      onDidReceiveNotificationResponse: (response) {
        if (RideOngoingNotification.handles(response)) {
          _ref.read(rideOngoingNotificationProvider).onAction(response);
          return;
        }
        _openDeeplink(response.payload);
      },
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
      final token = await _fcmToken();
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

  /// Runs after every login and at start when signed in. The backend drops
  /// all of a user's devices on each login, so this must follow it.
  Future<void> _requestPermissionAndRegister() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // Denied: the token is still valid (and the choice can change in
      // Settings), so register it anyway.
      _ref
          .read(pushPermissionDeniedProvider.notifier)
          .set(settings.authorizationStatus == AuthorizationStatus.denied);
    } catch (e) {
      debugPrint('Push: permission request failed (ignored): $e');
    }
    try {
      final token = await _fcmToken();
      if (token != null) {
        // Handy for sending test messages from the Firebase console.
        debugPrint('Push: FCM token: $token');
        await _registerToken(token);
      } else {
        debugPrint('Push: no FCM token, device not registered');
      }
    } catch (e) {
      debugPrint('Push: registration failed (ignored): $e');
    }
  }

  /// What this device holds, for support (long-press the version on the
  /// account tab): the APNs token iOS gave the app (64 hex characters, iOS
  /// only — null means no APNs token at all, so every push to the FCM token
  /// fails) and the FCM token to paste into the Firebase console's test send.
  Future<({String? apns, String? fcm, String? error})> diagnose() async {
    if (!_isSupportedPlatform) return (apns: null, fcm: null, error: null);
    String? apns;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        apns = await _messaging.getAPNSToken();
      }
      return (apns: apns, fcm: await _fcmToken(), error: null);
    } catch (e) {
      return (apns: apns, fcm: null, error: e.toString());
    }
  }

  /// The FCM registration token — never the APNs one. On iOS FCM can only
  /// mint it once APNs has handed the app its device token, which arrives a
  /// moment after launch; asked earlier, getToken() throws "APNS token has not
  /// been set yet" and the device never registers.
  Future<String?> _fcmToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apns;
      for (var i = 0; i < 10 && apns == null; i++) {
        apns = await _messaging.getAPNSToken();
        if (apns == null) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      if (apns == null) {
        debugPrint('Push: APNs token never arrived (no aps-environment?)');
        return null;
      }
      debugPrint('Push: APNs token: ${apns.length} hex chars');
    }
    return _messaging.getToken();
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
      // Login must keep working even if the backend refuses the token.
      debugPrint('Push: token registration failed (ignored): $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    // A driver's call while the app is open: the socket usually brought it
    // already, and the controller ignores the copy.
    if (_handleCallPush(message.data)) return;
    // A campaign push also lands in the inbox: reload it so the tab badge
    // counts it straight away.
    if (_ref.read(authControllerProvider).isAuthenticated) {
      _ref.read(inboxControllerProvider.notifier).refresh();
    }
    final notification = message.notification;
    if (notification == null) return; // Data-only: nothing to display.

    final deeplink = _targetPath(message.data);
    // Skip the banner when the user is already on the target screen — the
    // WebSocket-driven UI is the source of truth there. Every chat message is
    // pushed, even with the socket up, so this is what keeps the open chat
    // quiet.
    if (deeplink != null) {
      try {
        if (_ref.read(routerProvider).state.uri.toString() == deeplink) {
          return;
        }
      } catch (_) {
        // Router not ready yet — show the banner anyway.
      }
    }

    // A chat's notifications share its room id (as the backend's do), so
    // opening the chat clears them all — see [ChatNotifications].
    final room = message.data['type'] == 'chat_message'
        ? message.data['room_id'] as String?
        : null;
    _localNotifications.show(
      id: room != null ? 0 : notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          tag: room,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          presentBadge: true,
          threadIdentifier: room,
        ),
      ),
      payload: deeplink,
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    if (_handleCallPush(message.data)) return;
    _openDeeplink(_targetPath(message.data));
  }

  /// `call_incoming` (rings, if it still does) and `call_ended`. Returns
  /// whether the push was about a call.
  bool _handleCallPush(Map<String, dynamic> data) {
    final calls = _ref.read(callControllerProvider.notifier);
    switch (data['type']) {
      case 'call_incoming':
        calls.onIncomingPush(data);
        return true;
      case 'call_ended':
        final callId = data['call_id'];
        if (callId is String) {
          final reason = data['end_reason'];
          calls.onRemoteEnded(callId, reason is String ? reason : null);
        }
        return true;
    }
    return false;
  }

  /// The tap target from a push payload: the explicit `deeplink` path, or the
  /// `route` some notifications send instead (e.g. the stuck-ride auto-cancel
  /// sends `type=job_cancelled`, `route=/`, SCRUM-111). A bare "/" means home,
  /// which is "/main" in this app's router.
  String? _targetPath(Map<String, dynamic> data) {
    // A chat push (e.g. "ไรเดอร์ส่งรูปภาพ") names its room as
    // job:/order:/messenger:{id}; open that order's chat.
    final room = data['room_id'];
    if (data['type'] == 'chat_message' && room is String && room.isNotEmpty) {
      return chatRouteForRoom(room);
    }
    final raw = (data['deeplink'] ?? data['route']) as String?;
    if (raw == null || raw.isEmpty) return null;
    return raw == '/' ? '/main' : raw;
  }

  void _openDeeplink(String? deeplink) {
    if (deeplink == null || !deeplink.startsWith('/')) return;
    // go() runs the router redirect, so splash/auth gating and the
    // pending-link stash apply exactly like massmove:// deeplinks.
    _ref.read(routerProvider).go(deeplink);
  }
}
