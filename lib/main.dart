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

bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// FCM background isolate entrypoint. Notification-type messages are
/// displayed by the OS; data-only messages need no processing yet.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
