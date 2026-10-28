import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/call/domain/call_models.dart';
import 'package:customer_app/features/call/presentation/call_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The call screen: ringing out, ringing in, and talking. It follows
/// [callControllerProvider] and closes itself when the call is gone.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Screen off against the ear, like a phone call.
    CallProximity.set(true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(callControllerProvider) == null) _close();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    CallProximity.set(false);
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(callControllerProvider, (_, next) {
      if (next == null) _close();
    });
    final session = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);
    if (session == null) {
      return const Scaffold(backgroundColor: _background);
    }
    final call = session.call;
    final name = call.peer.fullName.isNotEmpty
        ? call.peer.fullName
        : call.kind == CallKind.ride
        ? l10n.callPeerDriver
        : l10n.callPeerRider;

    return PopScope(
      canPop: session.phase == CallPhase.ended,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                _Avatar(url: call.peer.avatarUrl),
                const SizedBox(height: 24),
                Text(
                  name,
                  key: const Key('callPeerName'),
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _status(l10n, session),
                  key: const Key('callStatus'),
                  style: AppTypography.body2.copyWith(
                    color: AppColors.foundationAlphaWhite400,
                  ),
                ),
                const Spacer(flex: 3),
                if (session.phase == CallPhase.incoming)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundButton(
                        key: const Key('callDecline'),
                        icon: Icons.call_end_rounded,
                        label: l10n.callDecline,
                        color: AppColors.error,
                        onTap: controller.decline,
                      ),
                      _RoundButton(
                        key: const Key('callAccept'),
                        icon: Icons.call_rounded,
                        label: l10n.callAccept,
                        color: AppColors.foundationGreen600,
                        onTap: controller.accept,
                      ),
                    ],
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundButton(
                        key: const Key('callMute'),
                        icon: session.muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_none_rounded,
                        label: l10n.callMute,
                        selected: session.muted,
                        onTap: session.phase == CallPhase.ended
                            ? null
                            : controller.toggleMute,
                      ),
                      _RoundButton(
                        key: const Key('callSpeaker'),
                        icon: Icons.volume_up_rounded,
                        label: l10n.callSpeaker,
                        selected: session.speaker,
                        onTap: session.phase == CallPhase.ended
                            ? null
                            : controller.toggleSpeaker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _RoundButton(
                    key: const Key('callHangUp'),
                    icon: Icons.call_end_rounded,
                    label: l10n.callHangUp,
                    color: AppColors.error,
                    onTap: session.phase == CallPhase.ended
                        ? null
                        : controller.hangUp,
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _status(AppLocalizations l10n, CallSession session) {
    switch (session.phase) {
      case CallPhase.outgoing:
        return l10n.callStatusCalling;
      case CallPhase.incoming:
        return l10n.callStatusIncoming;
      case CallPhase.connecting:
        return l10n.callStatusConnecting;
      case CallPhase.active:
        return formatCallDuration(
          DateTime.now().difference(session.connectedAt ?? DateTime.now()),
        );
      case CallPhase.ended:
        return callEndedText(l10n, session.endReason);
    }
  }
}

const _background = AppColors.semanticGrayNeutralFgHigh;

/// `m:ss` (or `h:mm:ss`) for the call timer.
String formatCallDuration(Duration d) {
  final s = d.isNegative ? 0 : d.inSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = (s % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
}

/// What an ended call says, by its end reason.
String callEndedText(AppLocalizations l10n, String? reason) => switch (reason) {
  'missed' => l10n.callEndedMissed,
  'declined' => l10n.callEndedDeclined,
  'cancelled' => l10n.callEndedCancelled,
  'failed' || 'microphone' => l10n.callEndedFailed,
  'lost' => l10n.callEndedLost,
  _ => l10n.callEndedHangup,
};

class _Avatar extends StatelessWidget {
  const _Avatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 120.0;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.foundationAlphaWhite100,
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 64,
        color: AppColors.foundationAlphaWhite400,
      ),
    );
    if (url == null) return placeholder;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// A filled action (accept / hang up); null for a toggle.
  final Color? color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background =
        color ?? (selected ? Colors.white : AppColors.foundationAlphaWhite100);
    final foreground = color != null
        ? Colors.white
        : selected
        ? _background
        : Colors.white;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: background,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 68,
                child: Icon(icon, color: foreground, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption4.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Turns the screen off when the phone is held to the ear (iOS proximity
/// monitoring, an Android proximity wake lock). See AppDelegate.swift and
/// MainActivity.kt.
abstract final class CallProximity {
  static const _channel = MethodChannel('massmove/call_proximity');

  static Future<void> set(bool on) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('set', on);
    } catch (_) {
      // Not wired on this platform (tests, desktop).
    }
  }
}
