import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/call/data/call_repository.dart';
import 'package:customer_app/features/call/domain/call_models.dart';
import 'package:customer_app/features/call/presentation/call_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Call button of an order's screen (tracking, chat header). [builder]
/// gets a null `onCall` (show no button) unless calling is switched on and the
/// order can be called: it runs, or finished less than 24h ago ([doneAt]), and
/// the backend hasn't refused it. A null [status] (a chat opened without the
/// order) leaves that to the backend.
class OrderCallButton extends ConsumerStatefulWidget {
  const OrderCallButton({
    super.key,
    required this.kind,
    required this.jobId,
    required this.status,
    required this.builder,
    this.doneAt,
  });

  final CallKind kind;
  final String jobId;
  final String? status;
  final DateTime? doneAt;

  /// The button and what surrounds it; `onCall` rings the driver, null when
  /// there is no call to offer.
  final Widget Function(BuildContext context, VoidCallback? onCall) builder;

  @override
  ConsumerState<OrderCallButton> createState() => _OrderCallButtonState();
}

class _OrderCallButtonState extends ConsumerState<OrderCallButton> {
  bool _askedFullScreen = false;

  bool _visible() {
    final enabled = ref.watch(callSettingsProvider).value?.enabled ?? false;
    if (!enabled || widget.jobId.isEmpty) return false;
    if (ref.watch(callRefusedOrdersProvider).contains(widget.jobId)) {
      return false;
    }
    return widget.status == null ||
        isOrderCallable(widget.kind, widget.status, doneAt: widget.doneAt);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible()) return widget.builder(context, null);
    if (!_askedFullScreen) {
      _askedFullScreen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) askForFullScreenCalls(context, ref);
      });
    }
    return widget.builder(
      context,
      () => placeOrderCall(context, ref, widget.kind, widget.jobId),
    );
  }
}

/// Rings the driver of an order; a refusal is told in a snackbar.
Future<void> placeOrderCall(
  BuildContext context,
  WidgetRef ref,
  CallKind kind,
  String jobId,
) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final error = await ref
      .read(callControllerProvider.notifier)
      .startCall(kind, jobId);
  if (error == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(callErrorText(l10n, error)),
        action: error == CallError.microphone
            ? SnackBarAction(
                label: l10n.chatOpenSettings,
                onPressed: () => AppSettings.openAppSettings(),
              )
            : null,
      ),
    );
}

String callErrorText(AppLocalizations l10n, CallError error) => switch (error) {
  CallError.busy => l10n.callErrorBusy,
  CallError.notAllowed => l10n.callErrorNotAllowed,
  CallError.blocked => l10n.callErrorBlocked,
  CallError.disabled => l10n.callErrorDisabled,
  CallError.notFound => l10n.callErrorNotFound,
  CallError.microphone => l10n.callErrorMicrophone,
  CallError.ended || CallError.failed => l10n.callErrorFailed,
};

const _fullScreenAskedKey = 'call_full_screen_asked';

/// Android 14+ grants full-screen incoming calls per app: without it a
/// driver's call to a locked phone is only a heads-up notification. Asked
/// once, the first time an order that can be called is on screen.
Future<void> askForFullScreenCalls(BuildContext context, WidgetRef ref) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final prefs = ref.read(sharedPreferencesProvider);
  if (prefs.getBool(_fullScreenAskedKey) ?? false) return;
  try {
    if (await FlutterCallkitIncoming.canUseFullScreenIntent()) return;
  } catch (_) {
    return;
  }
  await prefs.setBool(_fullScreenAskedKey, true);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final allow = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.callFullScreenTitle),
      content: Text(l10n.callFullScreenBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.callFullScreenLater),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.callFullScreenAllow),
        ),
      ],
    ),
  );
  if (allow == true) await FlutterCallkitIncoming.requestFullIntentPermission();
}

/// The call icon in an order's chat header.
class ChatHeaderCallButton extends StatelessWidget {
  const ChatHeaderCallButton({
    super.key,
    required this.kind,
    required this.jobId,
    required this.status,
  });

  final CallKind kind;
  final String jobId;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return OrderCallButton(
      kind: kind,
      jobId: jobId,
      status: status,
      builder: (context, onCall) => onCall == null
          ? const SizedBox.shrink()
          : IconButton(
              key: const Key('chatCallButton'),
              tooltip: AppLocalizations.of(context)!.callButton,
              icon: const Icon(Icons.call_outlined, color: Colors.white),
              onPressed: onCall,
            ),
    );
  }
}
