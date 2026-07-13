import 'dart:async';

import 'package:customer_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:customer_app/features/payment/domain/models/payment_intent.dart';
import 'package:customer_app/features/payment/presentation/states/promptpay_state.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'promptpay_controller.g.dart';

/// Drives the PromptPay QR flow: create intent → show QR → poll status until
/// PAID / EXPIRED / FAILED (SCRUM-35 §2.2). Works for both a ride job
/// (§3.1, `job_id`) and a messenger/food order (§3.3, `order_id`).
@riverpod
class PromptPayController extends _$PromptPayController {
  static const _pollEverySeconds = 3;
  static const _graceSeconds = 5;

  Timer? _ticker;
  DateTime? _expiresAt;
  int _tick = 0;
  String? _jobId;
  String? _orderId;

  @override
  PromptPayState build() {
    ref.onDispose(() => _ticker?.cancel());
    return const PromptPayState();
  }

  /// Create (or reuse) an intent for a ride [jobId] and begin polling.
  Future<void> startForJob(String jobId) {
    _jobId = jobId;
    _orderId = null;
    return _start();
  }

  /// Create (or reuse) an intent for a messenger/food [orderId] and begin
  /// polling. NOTE: the backend rejects order intents until its order-total
  /// lookup ships (SCRUM-35 §3.3) — the error state covers that path.
  Future<void> startForOrder(String orderId) {
    _orderId = orderId;
    _jobId = null;
    return _start();
  }

  Future<void> _start() async {
    _ticker?.cancel();
    _tick = 0;
    state = const PromptPayState(isCreating: true);

    final repo = ref.read(paymentRepositoryProvider);
    final jobId = _jobId;
    final orderId = _orderId;

    try {
      // Idempotency (§7): reuse the existing intent instead of minting a new
      // one where possible.
      final existing = jobId != null
          ? await repo.getIntentByJob(jobId)
          : await repo.getIntentByOrder(orderId!);
      if (existing != null) {
        // Already paid → done, don't create a duplicate.
        if (existing.status == PaymentIntentStatus.paid) {
          state = state.copyWith(intent: existing, isCreating: false);
          return;
        }

        // Still awaiting payment with a live QR → resume the same QR rather
        // than issuing a new one. We require a confirmed *future* expiry: the
        // by-job/by-order lookup may omit expires_at, and without it we can't
        // prove the QR is still valid, so we fall through and create fresh.
        final expiry = DateTime.tryParse(existing.expiresAt ?? '');
        final isResumable =
            existing.status == PaymentIntentStatus.awaitingPayment &&
            (existing.qrCodeUrl?.isNotEmpty ?? false) &&
            expiry != null &&
            expiry.isAfter(DateTime.now());
        if (isResumable) {
          _expiresAt = expiry;
          state = state.copyWith(
            intent: existing,
            isCreating: false,
            error: null,
            secondsLeft: _computeSecondsLeft(),
          );
          _startTicker();
          return;
        }
      }

      final intent = jobId != null
          ? await repo.createIntent(jobId: jobId, paymentMethod: 'PROMPTPAY')
          : await repo.createIntentForOrder(
              orderId: orderId!,
              paymentMethod: 'PROMPTPAY',
            );

      _expiresAt = DateTime.tryParse(intent.expiresAt ?? '');
      state = state.copyWith(
        intent: intent,
        isCreating: false,
        error: null,
        secondsLeft: _computeSecondsLeft(),
      );

      if (!intent.status.isTerminal) {
        _startTicker();
      }
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
    }
  }

  /// Discards the current intent and creates a fresh one (retry after expiry).
  Future<void> retry() async {
    if (_jobId == null && _orderId == null) return;
    await _start();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> _onTick() async {
    _tick++;
    final secondsLeft = _computeSecondsLeft();
    state = state.copyWith(secondsLeft: secondsLeft);

    // Hard-stop once the QR window (plus a small grace) has elapsed.
    if (secondsLeft <= -_graceSeconds) {
      _ticker?.cancel();
      // Reflect EXPIRED locally if the backend hasn't flipped it yet.
      final current = state.intent;
      if (current != null && !current.status.isTerminal) {
        state = state.copyWith(
          intent: current.copyWith(status: PaymentIntentStatus.expired),
        );
      }
      return;
    }

    if (_tick % _pollEverySeconds != 0) return;

    final intentId = state.intent?.id;
    if (intentId == null) return;

    try {
      final updated = await ref
          .read(paymentRepositoryProvider)
          .getIntent(intentId);
      // The real poll response omits qr_code_url/expires_at (deviates from
      // SCRUM-35 §2.2) — replacing the intent wholesale wiped the QR after the
      // first poll. Merge: keep the values from create when the poll lacks them.
      final current = state.intent;
      final merged = updated.copyWith(
        qrCodeUrl: (updated.qrCodeUrl?.isNotEmpty ?? false)
            ? updated.qrCodeUrl
            : current?.qrCodeUrl,
        expiresAt: updated.expiresAt ?? current?.expiresAt,
      );
      state = state.copyWith(intent: merged);
      if (updated.status.isTerminal) {
        _ticker?.cancel();
      }
    } catch (e) {
      // Transient poll failure — keep the timer running and try next tick.
      debugPrint('PromptPay poll failed: $e');
    }
  }

  int _computeSecondsLeft() {
    final expiry = _expiresAt;
    if (expiry == null) return 0;
    return expiry.difference(DateTime.now()).inSeconds;
  }
}
