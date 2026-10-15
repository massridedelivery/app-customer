import 'dart:typed_data';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/payment/presentation/controllers/promptpay_controller.dart';
import 'package:customer_app/features/payment/presentation/screens/qr_payload.dart';
import 'package:customer_app/features/payment/presentation/states/promptpay_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// PromptPay QR payment screen for either a ride job ([jobId]) or a
/// messenger/food order ([orderId]) — exactly one must be provided.
/// On PAID it replaces itself with [onPaidRoute] (defaults to the ride
/// live screen for jobs / messenger tracking for orders).
class PromptPayQrScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final String? orderId;
  final String? onPaidRoute;

  const PromptPayQrScreen({
    super.key,
    this.jobId,
    this.orderId,
    this.onPaidRoute,
  }) : assert(
          (jobId != null) ^ (orderId != null),
          'Provide exactly one of jobId or orderId',
        );

  @override
  ConsumerState<PromptPayQrScreen> createState() => _PromptPayQrScreenState();
}

class _PromptPayQrScreenState extends ConsumerState<PromptPayQrScreen> {
  String get _paidRoute {
    if (widget.onPaidRoute != null) return widget.onPaidRoute!;
    return widget.jobId != null
        ? '/live/${widget.jobId}'
        : '/messenger/tracking/${widget.orderId}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(promptPayControllerProvider.notifier);
      if (widget.jobId != null) {
        notifier.startForJob(widget.jobId!);
      } else {
        notifier.startForOrder(widget.orderId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promptPayControllerProvider);

    // On PAID → proceed to matching/tracking.
    ref.listen(promptPayControllerProvider.select((s) => s.isPaid), (
      prev,
      isPaid,
    ) {
      if (isPaid == true) {
        context.pushReplacement(_paidRoute);
      }
    });

    // The intent is voided and couldn't be replaced (the controller re-issues
    // one when only the amount changed): the trip went cash, was cancelled or
    // is paid another way. Close the QR screen so the customer is back on the
    // trip's live status instead of staring at a dead QR.
    ref.listen(promptPayControllerProvider.select((s) => s.status.isVoided), (
      prev,
      isVoided,
    ) {
      if (isVoided == true) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.payQrVoidedTitle),
            ),
          );
        if (context.canPop()) context.pop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.payPromptPayTitle,
          style: AppTypography.heading4,
        ),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(state),
        ),
      ),
    );
  }

  Widget _buildBody(PromptPayState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.isCreating) {
      return const Center(child: MassLoadingM(size: 72));
    }

    if (state.error != null && state.intent == null) {
      return _StatusMessage(
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        title: l10n.payQrCreateFailed,
        subtitle: state.error!,
        primaryLabel: l10n.payTryAgain,
        onPrimary: () =>
            ref.read(promptPayControllerProvider.notifier).retry(),
        secondaryLabel: l10n.payPayCashInstead,
        onSecondary: () => context.pop(),
      );
    }

    if (state.status.isVoided) {
      return _StatusMessage(
        icon: Icons.info_outline_rounded,
        color: AppColors.textSecondary,
        title: l10n.payQrVoidedTitle,
        subtitle: l10n.payVoidedSubtitle,
        primaryLabel: l10n.payBack,
        onPrimary: () => context.pop(),
      );
    }

    if (state.isExpired) {
      return _StatusMessage(
        icon: Icons.timer_off_rounded,
        color: AppColors.error,
        title: l10n.payQrExpiredTitle,
        subtitle: l10n.payQrExpiredSubtitle,
        primaryLabel: l10n.payQrCreateNew,
        onPrimary: () =>
            ref.read(promptPayControllerProvider.notifier).retry(),
        secondaryLabel: l10n.payPayCashInstead,
        onSecondary: () => context.pop(),
      );
    }

    if (state.status.name == 'failed') {
      return _StatusMessage(
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        title: l10n.payFailedTitle,
        subtitle: l10n.payFailedSubtitle,
        primaryLabel: l10n.payQrCreateNew,
        onPrimary: () =>
            ref.read(promptPayControllerProvider.notifier).retry(),
        secondaryLabel: l10n.payPayCashInstead,
        onSecondary: () => context.pop(),
      );
    }

    final intent = state.intent;
    final qrUrl = intent?.qrCodeUrl;
    if (intent == null || qrUrl == null || qrUrl.isEmpty) {
      return _StatusMessage(
        icon: Icons.qr_code_2_rounded,
        color: AppColors.textSecondary,
        title: l10n.payQrNotFoundTitle,
        subtitle: l10n.payQrNotFoundSubtitle,
        primaryLabel: l10n.payTryAgain,
        onPrimary: () =>
            ref.read(promptPayControllerProvider.notifier).retry(),
      );
    }

    return _QrView(
      qrUrl: qrUrl,
      amount: intent.amount,
      secondsLeft: state.secondsLeft < 0 ? 0 : state.secondsLeft,
      // The controller flags a re-issued QR with a sentinel; say it in the
      // app's language here.
      notice: state.notice == PromptPayController.amountChangedNotice
          ? l10n.payAmountChangedNotice
          : state.notice,
    );
  }
}

class _QrView extends StatelessWidget {
  final String qrUrl;
  final double? amount;
  final int secondsLeft;
  final String? notice;

  const _QrView({
    required this.qrUrl,
    required this.amount,
    required this.secondsLeft,
    this.notice,
  });

  String get _countdown {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // The previous QR was voided because the amount changed (waiting
        // time / tolls); say why there's a new one.
        if (notice != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.semanticWarningBgLowOnWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.semanticWarningFgHigh,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice!,
                    style: AppTypography.label2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.payQrScanHint,
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E2E1)),
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: _QrImage(url: qrUrl),
          ),
        ),
        const SizedBox(height: 24),
        if (amount != null)
          Text(
            // Whole-baht fares (ride/messenger) show no decimals; a value that
            // carries satang (e.g. a food order with menu satang) still shows
            // them (SCRUM-89 — don't force ".00").
            '฿${amount! == amount!.roundToDouble() ? amount!.toStringAsFixed(0) : amount!.toStringAsFixed(2)}',
            style: AppTypography.heading2,
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 18, color: AppColors.error),
            const SizedBox(width: 6),
            Text(
              l10n.payQrExpiresIn(_countdown),
              style: AppTypography.label1.copyWith(color: AppColors.error),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _WaitingIndicator(),
      ],
    );
  }
}

/// Renders the gateway QR from whatever shape `qr_code_url` arrives in:
/// - http(s) URL — Omise serves an **SVG** (302 → S3 `qrcode.svg`), which
///   `Image.network` cannot decode, so we fetch bytes ourselves
/// - `data:` URI (e.g. `data:image/png;base64,...`)
/// - raw base64 payload
/// The bytes are then format-sniffed: SVG → flutter_svg, bitmap → Image.
class _QrImage extends StatefulWidget {
  final String url;

  const _QrImage({required this.url});

  @override
  State<_QrImage> createState() => _QrImageState();
}

class _QrImageState extends State<_QrImage> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _fetch();
  }

  @override
  void didUpdateWidget(covariant _QrImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A retry creates a new intent → new URL → refetch.
    if (oldWidget.url != widget.url) {
      setState(() => _bytesFuture = _fetch());
    }
  }

  Future<Uint8List> _fetch() async {
    final value = widget.url.trim();

    // http(s) URL — fetch with a bare Dio: the QR host (Omise/S3) must not
    // receive our BFF auth header. Other shapes (data URI / base64) decode
    // inline via QrPayload.
    if (QrPayload.isHttpUrl(value)) {
      final response = await Dio().get<List<int>>(
        value,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const []);
    }
    return QrPayload.decodeInline(value);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: MassLoadingM(size: 56));
        }
        final bytes = snapshot.data;
        if (snapshot.hasError || bytes == null || bytes.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.payQrLoadFailed),
          );
        }
        if (QrPayload.isSvg(bytes)) {
          return SvgPicture.memory(bytes, fit: BoxFit.contain);
        }
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => Center(
            child: Text(AppLocalizations.of(context)!.payQrLoadFailed),
          ),
        );
      },
    );
  }
}

class _WaitingIndicator extends StatelessWidget {
  const _WaitingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Text(
          AppLocalizations.of(context)!.payAwaitingPayment,
          style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StatusMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.heading4, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(primaryLabel, style: AppTypography.label2),
            ),
          ),
          if (secondaryLabel != null && onSecondary != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!, style: AppTypography.label2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
