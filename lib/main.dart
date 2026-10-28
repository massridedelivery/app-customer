import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/services/ride_ongoing_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer_app/app.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/call/data/call_background.dart';
import 'package:customer_app/features/call/data/voip_token_registrar.dart';
import 'package:customer_app/features/call/presentation/call_controller.dart';

bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// FCM background isolate entrypoint. Notification-type messages are
/// displayed by the OS; the data-only ones handled here are a driver's call
/// (Android: the full-screen incoming call) and the end of a ride.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (await handleCallPushInBackground(message.data)) return;
  // A ride that ends while the app is backgrounded must not leave its pinned
  // "ride in progress" notification behind.
  final type = message.data['type'];
  final status = '${message.data['status'] ?? ''}'.toUpperCase();
  if (type == 'job_cancelled' ||
      (type == 'job_status' &&
          (status == 'COMPLETED' || status == 'CANCELLED'))) {
    await RideOngoingNotification.clearInBackground();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only across the app (iOS is also locked in Info.plist; Android has
  // no manifest lock, so this covers both).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Firebase reads its config from the native files (google-services.json /
  // GoogleService-Info.plist); other platforms have no Firebase setup.
  if (_isMobilePlatform) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  // Calls are wired before any widget: an iPhone woken by a driver's call
  // runs this with no screen, and the call is answered on the lock screen.
  if (_isMobilePlatform) {
    container.read(callControllerProvider.notifier).start();
    container.read(voipTokenRegistrarProvider).start();
  }

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
