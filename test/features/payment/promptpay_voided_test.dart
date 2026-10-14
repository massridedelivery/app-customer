import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:customer_app/features/payment/domain/models/payment_intent.dart';
import 'package:customer_app/features/payment/domain/repositories/i_payment_repository.dart';
import 'package:customer_app/features/payment/presentation/controllers/promptpay_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _QuietSocket extends SocketService {
  _QuietSocket(super.tokenStorage);

  @override
  void connect({bool isReconnect = false}) {}

  @override
  void disconnect() {}
}

/// Scripted repository: [creates] are handed out in order (a `null` entry
/// throws a 409), [polls] answers getIntent, [byJob] answers getIntentByJob.
class _FakeRepo implements IPaymentRepository {
  _FakeRepo({required this.creates});

  final List<PaymentIntent?> creates;
  PaymentIntent? byJob;
  PaymentIntent? polled;
  int createCalls = 0;

  @override
  Future<PaymentIntent> createIntent({
    required String jobId,
    required String paymentMethod,
    String? cardToken,
  }) async {
    final next = creates[createCalls++];
    if (next == null) {
      throw ServerException('conflict', statusCode: 409);
    }
    return next;
  }

  @override
  Future<PaymentIntent> getIntent(String intentId) async => polled!;

  @override
  Future<PaymentIntent?> getIntentByJob(String jobId) async => byJob;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PaymentIntent _intent(
  String id,
  PaymentIntentStatus status, {
  String? qr,
  double amount = 120,
}) => PaymentIntent(
  id: id,
  jobId: 'job-1',
  amount: amount,
  status: status,
  qrCodeUrl: qr,
  expiresAt: DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
);

Future<ProviderContainer> _container(_FakeRepo repo) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      paymentRepositoryProvider.overrideWithValue(repo),
      socketServiceProvider.overrideWithValue(
        _QuietSocket(TokenStorage(prefs)),
      ),
    ],
  );
  addTearDown(container.dispose);
  // Keep the auto-dispose controller alive for the test.
  container.listen(promptPayControllerProvider, (_, _) {});
  return container;
}

void main() {
  test('a voided QR (amount changed) is replaced by a new intent', () async {
    final first = _intent('A', PaymentIntentStatus.awaitingPayment, qr: 'qr-A');
    final second = _intent(
      'B',
      PaymentIntentStatus.awaitingPayment,
      qr: 'qr-B',
      amount: 160,
    );
    final repo = _FakeRepo(creates: [first, second]);
    final container = await _container(repo);
    final notifier = container.read(promptPayControllerProvider.notifier);

    await notifier.startForJob('job-1');
    expect(container.read(promptPayControllerProvider).intent?.id, 'A');

    repo.polled = first.copyWith(status: PaymentIntentStatus.voided);
    await notifier.pollNow();

    final state = container.read(promptPayControllerProvider);
    expect(state.intent?.id, 'B');
    expect(state.intent?.qrCodeUrl, 'qr-B');
    expect(state.intent?.amount, 160);
    expect(state.status.isVoided, isFalse);
    expect(state.notice, PromptPayController.amountChangedNotice);
    expect(repo.createCalls, 2);
  });

  test('a refused re-issue (409) settles on voided without looping', () async {
    final first = _intent('A', PaymentIntentStatus.awaitingPayment, qr: 'qr-A');
    final voided = first.copyWith(status: PaymentIntentStatus.voided);
    final repo = _FakeRepo(creates: [first, null, null]);
    final container = await _container(repo);
    final notifier = container.read(promptPayControllerProvider.notifier);

    await notifier.startForJob('job-1');
    repo
      ..polled = voided
      ..byJob = voided; // e.g. the trip switched to cash
    await notifier.pollNow();

    var state = container.read(promptPayControllerProvider);
    expect(state.status.isVoided, isTrue);
    expect(state.isCreating, isFalse);
    expect(repo.createCalls, 2);

    // Another poll of the same voided intent must not try again.
    await notifier.pollNow();
    state = container.read(promptPayControllerProvider);
    expect(state.status.isVoided, isTrue);
    expect(repo.createCalls, 2);
  });

  test('a 409 that points at an already-paid intent ends as paid', () async {
    final first = _intent('A', PaymentIntentStatus.awaitingPayment, qr: 'qr-A');
    final repo = _FakeRepo(creates: [first, null]);
    final container = await _container(repo);
    final notifier = container.read(promptPayControllerProvider.notifier);

    await notifier.startForJob('job-1');
    repo
      ..polled = first.copyWith(status: PaymentIntentStatus.voided)
      ..byJob = _intent('C', PaymentIntentStatus.paid);
    await notifier.pollNow();

    final state = container.read(promptPayControllerProvider);
    expect(state.isPaid, isTrue);
    expect(state.notice, isNull);
  });
}
