import 'package:customer_app/core/localization/locale_controller.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/live_ride/presentation/states/live_ride_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:customer_app/router/app_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Safety buffer added to the backend ETA before it is shown anywhere, so the
/// app under-promises (the rider tends to arrive a little earlier than shown).
const int kRideEtaBufferMinutes = 15;

final rideOngoingNotificationProvider = Provider<RideOngoingNotification>(
  (ref) => RideOngoingNotification(ref),
);

/// The Android "ride in progress" notification (design L2): pinned while a
/// driver is assigned, showing the plate first, the driver and vehicle, a
/// native countdown to the ETA (it keeps ticking with the app backgrounded),
/// and แชท / โทร buttons. Cleared when the ride ends or the active job goes
/// away. A no-op on other platforms (iOS needs a Live Activity instead).
class RideOngoingNotification {
  RideOngoingNotification(this._ref) {
    // The active job was cleared (ride ended, cancelled, logged out) while the
    // live screen was not open to say so.
    _ref.listen(authControllerProvider.select((s) => s.activeJobId), (
      previous,
      next,
    ) {
      if (previous != null && next == null) clear();
    });
  }

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int notificationId = 7101;
  static const String actionChat = 'ride_chat';
  static const String actionCall = 'ride_call';
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'massmove_ride',
    'การเดินทางที่กำลังดำเนินอยู่',
    description: 'คนขับ ทะเบียนรถ และเวลาที่จะถึง ระหว่างการเดินทาง',
    importance: Importance.defaultImportance,
    playSound: false,
    enableVibration: false,
  );

  static bool get _enabled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  String? _shownKey;
  String? _jobId;
  String? _driverPhone;

  /// Reflects [state] in the notification: shows or updates it while a driver
  /// is assigned, clears it once the ride is over.
  Future<void> sync(LiveRideState state) async {
    if (!_enabled) return;
    final status = (state.jobStatus ?? '').toUpperCase();
    final hasDriver = state.driverId?.isNotEmpty ?? false;
    if (!hasDriver ||
        state.jobId == null ||
        status == 'COMPLETED' ||
        status == 'CANCELLED') {
      if (status == 'COMPLETED' || status == 'CANCELLED') await clear();
      return;
    }

    final l10n = lookupAppLocalizations(_ref.read(localeControllerProvider));
    final plate = (state.vehiclePlate ?? '').trim();
    final title = switch (status) {
      'ARRIVED_AT_PICK_UP' => l10n.rideNotifArrived(plate),
      'PICKED_UP' => l10n.rideNotifOnTrip(plate),
      _ => l10n.rideNotifComing(plate),
    }.trim();
    final body = [
      state.driverName,
      [
        state.vehicleColor,
        state.vehicleType,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' '),
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    // Count down to the arrival only while the driver is still on the way.
    final eta = status == 'ARRIVED_AT_PICK_UP'
        ? null
        : state.etaArriveAt?.add(
            const Duration(minutes: kRideEtaBufferMinutes),
          );

    _jobId = state.jobId;
    _driverPhone = state.driverProfile?.driverInfo.phone;
    final key = '$title|$body|${eta?.millisecondsSinceEpoch}';
    if (key == _shownKey) return;
    _shownKey = key;

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    await _plugin.show(
      id: notificationId,
      title: title,
      body: body,
      payload: '/live/${state.jobId}',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.defaultImportance,
          priority: Priority.high,
          category: AndroidNotificationCategory.status,
          visibility: NotificationVisibility.public,
          color: const Color(0xFFDB1439),
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: eta != null,
          when: eta?.millisecondsSinceEpoch,
          usesChronometer: eta != null,
          chronometerCountDown: eta != null,
          actions: [
            AndroidNotificationAction(
              actionChat,
              l10n.liveChat,
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              actionCall,
              l10n.liveCall,
              showsUserInterface: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> clear() async {
    if (!_enabled) return;
    _shownKey = null;
    await _plugin.cancel(id: notificationId);
  }

  /// True when [response] is a tap on one of this notification's buttons.
  static bool handles(NotificationResponse response) =>
      response.id == notificationId &&
      (response.actionId == actionChat || response.actionId == actionCall);

  void onAction(NotificationResponse response) {
    final jobId = _jobId ?? response.payload?.split('/').last;
    if (response.actionId == actionChat && jobId != null) {
      _ref.read(routerProvider).go('/chat/$jobId');
    } else if (response.actionId == actionCall) {
      final phone = (_driverPhone ?? '').trim();
      if (phone.isNotEmpty) {
        launchUrl(Uri(scheme: 'tel', path: phone));
      } else if (jobId != null) {
        _ref.read(routerProvider).go('/live/$jobId');
      }
    }
  }

  /// Clears the notification from the FCM background isolate, where no
  /// provider exists: called when a push says the ride ended.
  static Future<void> clearInBackground() async {
    if (!_enabled) return;
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await plugin.cancel(id: notificationId);
  }
}
