import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/payment/domain/models/payment_intent.dart';
import 'package:customer_app/features/payment/presentation/controllers/promptpay_controller.dart';
import 'package:customer_app/features/payment/presentation/states/promptpay_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card payment via Beam hosted checkout (SCRUM-118).
///
/// Creates a `CARD` payment intent for a ride [jobId] or a messenger/food
/// [orderId] (no card token — the server returns a `charge_url` to Beam's
/// hosted page), opens that URL in the device browser, and resumes polling
/// (shared with PromptPay) until PAID / FAILED / EXPIRED. On PAID it replaces
/// itself with [onPaidRoute].
class CardCheckoutScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final String? orderId;
  final String? onPaidRoute;

  const CardCheckoutScreen({
    super.key,
    this.jobId,
    this.orderId,
    this.onPaidRoute,
  }) : assert(
          (jobId != null) ^ (orderId != null),
          'Provide exactly one of jobId or orderId',
        );

  @override
  ConsumerState<CardCheckoutScreen> createState() => _CardCheckoutScreenState();
}

class _CardCheckoutScreenState extends ConsumerState<CardCheckoutScreen> {
  // The charge_url is opened automatically the first time it arrives; guard so
  // returning to this screen (after paying) doesn't reopen the browser.
  String? _launchedUrl;

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
        notifier.startForJob(widget.jobId!, paymentMethod: 'CARD');
      } else {
        notifier.startForOrder(widget.orderId!, paymentMethod: 'CARD');
      }
    });
  }

  Future<void> _openChargeUrl(String url, {bool auto = false}) async {
    if (auto) {
      if (_launchedUrl == url) return; // already auto-opened this URL
      _launchedUrl = url;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('เปิดหน้าชำระเงินไม่สำเร็จ')),
        );
    }
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

    // Auto-open the Beam hosted page as soon as the charge_url is available.
    final chargeUrl = state.intent?.chargeUrl;
    if (chargeUrl != null && chargeUrl.isNotEmpty && !state.isTerminal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openChargeUrl(chargeUrl, auto: true);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ชำระเงินด้วยบัตร', style: AppTypography.heading4),
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
    if (state.isCreating) {
      return const Center(child: MassLoadingM(size: 72));
    }

    if (state.error != null && state.intent == null) {
      return _StatusMessage(
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        title: 'เริ่มการชำระเงินไม่สำเร็จ',
        subtitle: state.error!,
        primaryLabel: 'ลองอีกครั้ง',
        onPrimary: () =>
            ref.read(promptPayControllerProvider.notifier).retry(),
        secondaryLabel: 'ยกเลิก',
        onSecondary: () => context.pop(),
      );
    }

    if (state.status == PaymentIntentStatus.expired) {
      return _StatusMessage(
        icon: Icons.timer_off_rounded,
        color: AppColors.error,
        title: 'รายการหมดอายุแล้ว',
        subtitle: 'กรุณาเริ่มการชำระเงินใหม่อีกครั้ง',
        primaryLabel: 'เริ่มใหม่',
        onPrimary: () =>
            ref.read(promptPayControllerProvider.notifier).retry(),
        secondaryLabel: 'ยกเลิก',
        onSecondary: () => context.pop(),
      );
    }

    if (state.status == PaymentIntentStatus.failed) {
      return _StatusMessage(
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        title: 'ชำระเงินไม่สำเร็จ',
        subtitle: 'กรุณาลองสร้างรายการใหม่อีกครั้ง',
        primaryLabel: 'ลองอีกครั้ง',
        onPrimary: () =>
            ref.read(promptPayControllerProvider.notifier).retry(),
        secondaryLabel: 'ยกเลิก',
        onSecondary: () => context.pop(),
      );
    }

    final chargeUrl = state.intent?.chargeUrl;
    if (chargeUrl == null || chargeUrl.isEmpty) {
      return _StatusMessage(
        icon: Icons.credit_card_off_rounded,
        color: AppColors.textSecondary,
        title: 'ยังเปิดการชำระด้วยบัตรไม่ได้',
        subtitle: 'ขณะนี้ยังไม่รองรับการชำระด้วยบัตร กรุณาเลือกวิธีอื่น',
        primaryLabel: 'ลองอีกครั้ง',
        onPrimary: () =>
            ref.read(promptPayControllerProvider.notifier).retry(),
        secondaryLabel: 'เลือกวิธีอื่น',
        onSecondary: () => context.pop(),
      );
    }

    return _AwaitingCardPayment(
      amount: state.intent?.amount,
      onOpen: () => _openChargeUrl(chargeUrl),
      onCheck: () => ref.read(promptPayControllerProvider.notifier).pollNow(),
    );
  }
}

class _AwaitingCardPayment extends StatelessWidget {
  final double? amount;
  final VoidCallback onOpen;
  final Future<void> Function() onCheck;

  const _AwaitingCardPayment({
    required this.amount,
    required this.onOpen,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.credit_card_rounded,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'ชำระเงินในหน้าเว็บที่เปิดขึ้น',
            style: AppTypography.heading4,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'กรอกข้อมูลบัตรในหน้าชำระเงินที่ปลอดภัย '
            'เมื่อชำระเสร็จแล้วให้กลับมาที่แอป ระบบจะยืนยันให้อัตโนมัติ',
            style: AppTypography.body2.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (amount != null) ...[
            const SizedBox(height: 20),
            Text(
              '฿${amount! == amount!.roundToDouble() ? amount!.toStringAsFixed(0) : amount!.toStringAsFixed(2)}',
              style: AppTypography.heading2,
            ),
          ],
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('กำลังรอการชำระเงิน...'),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpen,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('เปิดหน้าชำระเงินอีกครั้ง',
                  style: AppTypography.label2),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => onCheck(),
              child: Text('ฉันชำระเงินแล้ว · ตรวจสอบสถานะ',
                  style: AppTypography.label2),
            ),
          ),
        ],
      ),
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
