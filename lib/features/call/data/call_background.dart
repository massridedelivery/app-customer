import 'package:customer_app/features/call/data/call_system_ui.dart';
import 'package:customer_app/features/call/domain/call_models.dart';

/// A call push that reached the FCM background isolate (Android, the app in
/// the background or closed): `call_incoming` shows the full-screen incoming
/// call, `call_ended` stops it ringing. Returns whether it was a call push.
Future<bool> handleCallPushInBackground(Map<String, dynamic> data) async {
  final ui = CallKitSystemUi();
  switch (data['type']) {
    case 'call_incoming':
      final call = CallView.fromPush(data);
      if (call != null) await ui.showIncoming(call);
      return true;
    case 'call_ended':
      final callId = data['call_id'];
      if (callId is String && callId.isNotEmpty) await ui.end(callId);
      return true;
  }
  return false;
}
