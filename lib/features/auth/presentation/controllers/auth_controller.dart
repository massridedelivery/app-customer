import 'package:customer_app/features/auth/data/datasources/email_otp_data_source.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/core/services/ride_ongoing_notification.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
import 'package:customer_app/features/auth/domain/entities/phone_login_response.dart';
import 'package:customer_app/features/auth/domain/usecases/phone_login_usecase_impl.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:customer_app/features/call/data/voip_token_registrar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Added imports for PhoneLoginUseCase and Failure
import 'package:customer_app/core/error/failures.dart';
import 'package:customer_app/core/localization/locale_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';

// Added imports for LiveRideController
import 'package:customer_app/features/active_orders/data/repositories/active_orders_repository_impl.dart';
import 'package:customer_app/features/live_ride/presentation/controllers/live_ride_controller.dart';
import 'package:customer_app/features/profile/presentation/controllers/loyalty_providers.dart';
import 'package:customer_app/features/profile/presentation/screens/promo_list_screen.dart';
import 'package:customer_app/features/ride_booking/presentation/providers/discover_promos_provider.dart';
import 'package:customer_app/features/profile/data/repositories/profile_repository_impl.dart';

part 'auth_controller.g.dart';

/// A user-facing message for an error — prefers the backend's own message on a
/// Dio error, otherwise the given localized [fallback]. Never surfaces a raw
/// `Exception: …` / stack string to the user.
String _authErrorMessage(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      if (m is String && m.isNotEmpty) return m;
    }
  }
  return fallback;
}

@riverpod
class AuthController extends _$AuthController {
  /// Strings for the app's current language (controllers have no context).
  AppLocalizations get _l10n => lookupAppLocalizations(
    Locale(ref.read(localeControllerProvider).languageCode),
  );

  String _errorMessage(Object e) =>
      _authErrorMessage(e, _l10n.authGenericError);

  @override
  AuthState build() {
    // Listen to LiveRideController for job status changes
    ref.listen(liveRideControllerProvider, (previous, next) {
      if (previous?.jobStatus != next.jobStatus) {
        if (next.jobStatus == 'CANCELLED' || next.jobStatus == 'COMPLETED') {
          clearActiveJob();
        }
        // Any cancel (customer, driver or system) makes the backend return the
        // promo code and loyalty points and void/refund the QR — drop the
        // cached copies so coupon lists and points show them again.
        if (next.jobStatus == 'CANCELLED') {
          ref.invalidate(promoListProvider);
          ref.invalidate(discoverPromosProvider);
          ref.invalidate(loyaltySummaryProvider);
        } else if (next.jobStatus == 'ACCEPTED') {
          checkActiveJob();
        }
      }
    });

    // Initialize based on saved token presence
    final hasToken = ref.read(tokenStorageProvider).hasToken;
    if (hasToken) {
      // Small delay to allow build to finish before calling async check
      Future.microtask(() => checkActiveJob());
      _openSocket();
      _syncLanguage();
      return const AuthState(isAuthenticated: true);
    }
    return const AuthState(isAuthenticated: false);
  }

  /// Brings the real-time socket up now that a valid token exists.
  ///
  /// [SocketService.connect] bails out when there is no token, and the
  /// controllers that would otherwise call it (live ride, chat, tracking) are
  /// built once — LiveRideController as early as this controller's `build`.
  /// So without an explicit call here a socket that was skipped for lack of a
  /// token at startup would never come up for the rest of the session, leaving
  /// the app on its REST polling fallback.
  void _openSocket() {
    ref.read(socketServiceProvider).ensureConnected();
  }

  /// Pushes the app's current language (th|en) to the backend so push
  /// notifications are localized. Best-effort — never blocks or fails auth.
  void _syncLanguage() {
    try {
      final lang = ref.read(localeControllerProvider).languageCode;
      ref.read(apiRepositoryProvider).updateLanguage(lang).catchError((_) {});
    } catch (_) {}
  }

  Future<void> checkActiveJob() async {
    try {
      final repo = ref.read(activeOrdersRepositoryProvider);
      final items = await repo.getActiveOrders();
      // Only a RIDE drives the /live/{id} recovery redirect (≤1 at a time per
      // SCRUM-45); food/messenger actives surface via the home banner instead.
      final rides = items.where((i) => i.isRide && i.id.isNotEmpty);
      state = state.copyWith(
        activeJobId: rides.isEmpty ? null : rides.first.id,
      );
      // A pinned "ride in progress" notification outlives a ride that ended
      // while the app was closed; tapped, it would open that old ride.
      if (rides.isEmpty) {
        await ref.read(rideOngoingNotificationProvider).clear();
      }
    } catch (e) {
      // On error, assume no active job
      state = state.copyWith(activeJobId: null);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.dio.post(
        '/auth/login',
        // role selects the customer account when one email/phone has several
        // account types (driver/merchant/customer) — identity change, BE #133.
        data: {'email': email, 'password': password, 'role': 'customer'},
      );

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      if (accessToken != null && refreshToken != null) {
        await ref
            .read(tokenStorageProvider)
            .saveTokens(accessToken: accessToken, refreshToken: refreshToken);
        state = state.copyWith(isLoading: false, isAuthenticated: true);
        _openSocket();
        _syncLanguage();

        // Check for active job after login
        await checkActiveJob();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _l10n.authInvalidServerResponse,
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['error'] ?? _l10n.authInvalidCredentials,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
    }
  }

  Future<void> logout() async {
    // Every side-effect below is best-effort and individually guarded: a
    // failure (e.g. the push-token call throwing) must never abort the state
    // reset. Previously an unguarded throw here left the app "authenticated"
    // with no token — an infinite 401 loop.
    try {
      // Drop this device's push token while the session token is still valid.
      await ref.read(pushNotificationServiceProvider).unregisterOnLogout();
    } catch (_) {}
    try {
      await ref.read(voipTokenRegistrarProvider).unregisterOnLogout();
    } catch (_) {}
    try {
      if (ref.read(tokenStorageProvider).hasToken) {
        await ref.read(profileRepositoryProvider).logout();
      }
    } catch (_) {}
    try {
      // Disconnect socket connection on logout
      ref.read(socketServiceProvider).disconnect();
    } catch (_) {}

    // Always land in a clean logged-out state so the router redirects to login.
    await ref.read(tokenStorageProvider).clearTokens();
    state = const AuthState(isAuthenticated: false, activeJobId: null);
  }

  void clearActiveJob() {
    state = state.copyWith(activeJobId: null);
  }

  // ─── FORGOT PASSWORD FLOW ─────────────────────────────────────────────────

  Future<String?> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(apiRepositoryProvider);
      final response = await repo.forgotPassword(email);
      state = state.copyWith(isLoading: false);
      return response['ref_id'] as String?;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return null;
    }
  }

  Future<String?> verifyResetOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(apiRepositoryProvider);
      final response = await repo.verifyResetOtp(email: email, otp: otp);
      state = state.copyWith(isLoading: false);
      return response['token'] as String?;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return null;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String password,
    required String refId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(apiRepositoryProvider);
      await repo.resetPassword(email: email, password: password, refId: refId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return false;
    }
  }

  // ─── PHONE LOGIN USE CASE ──────────────────────────────────────────────────

  /// Calls PhoneLoginUseCase to send OTP.
  Future<SendOtpResponse?> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Assuming phoneLoginUseCaseProvider is defined elsewhere and available
      // If it's in providers.dart, this import would be needed:
      // import 'package:customer_app/core/managers/providers.dart'; // Already present
      // And the provider would be: ref.read(phoneLoginUseCaseProvider);
      final phoneLoginUseCase = ref.read(
        phoneLoginUseCaseProvider,
      ); // Assuming this provider exists
      final result = await phoneLoginUseCase.sendOtp(
        phone: phone,
        role: 'customer', // Assuming 'customer' role based on context
      );
      return result.fold(
        (Failure failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
          return null;
        },
        (SendOtpResponse response) {
          state = state.copyWith(isLoading: false);
          return response;
        },
      );
    } catch (e) {
      // Catch any unexpected exceptions
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return null;
    }
  }

  Future<bool> sendVerifyOtp({
    required String phone,
    required String otp,
    required String refId,
    required String role,
    required bool isRegistered,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final phoneLoginUseCase = ref.read(phoneLoginUseCaseProvider);
      final result = await phoneLoginUseCase.sendVerifyOtp(
        // Call the use case method
        phone: phone,
        otp: otp,
        refId: refId,
        role: role,
        fullName: fullName,
      );
      return result.fold(
        (Failure failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
          return false;
        },
        (PhoneLoginResponse response) async {
          final accessToken = response.accessToken;
          final refreshToken = response.refreshToken;

          // Always save tokens so subsequent authenticated requests succeed
          await ref
              .read(tokenStorageProvider)
              .saveTokens(accessToken: accessToken, refreshToken: refreshToken);

          if (isRegistered) {
            state = state.copyWith(isLoading: false, isAuthenticated: true);
            _openSocket();
            _syncLanguage();
            await checkActiveJob(); // Keep existing behavior
          } else {
            state = state.copyWith(isLoading: false);
          }
          return true;
        },
      );
    } catch (e) {
      // Catch any unexpected exceptions
      state = state.copyWith(isLoading: false, error: _errorMessage(e));
      return false;
    }
  }

  /// Sends a login code to [email]. Returns the ref/registration info, or the
  /// reason it failed (branching on the backend `code`, never its message).
  Future<EmailOtpSendResult> sendEmailOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ref.read(emailOtpDataSourceProvider).send(email);
      state = state.copyWith(isLoading: false);
      return EmailOtpSendResult.sent(
        refId: (res['ref_id'] ?? '').toString(),
        isRegistered: res['is_registered'] == true,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final code = data is Map ? data['code']?.toString() : null;
      if (status == 503 || code == 'EMAIL_LOGIN_UNAVAILABLE') {
        return const EmailOtpSendResult.failed(EmailOtpError.unavailable);
      }
      if (status == 429) {
        return const EmailOtpSendResult.failed(EmailOtpError.rateLimited);
      }
      if (status == 403) {
        // account_suspended / account_deleted: ApiService already routes to
        // the account-blocked screen.
        return const EmailOtpSendResult.failed(EmailOtpError.accountBlocked);
      }
      if (status == 400) {
        return const EmailOtpSendResult.failed(EmailOtpError.invalidEmail);
      }
      return const EmailOtpSendResult.failed(EmailOtpError.failed);
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return const EmailOtpSendResult.failed(EmailOtpError.failed);
    }
  }

  /// Verifies an email code; on success saves the tokens and signs in (the
  /// backend creates the account if the email had none). Null = success.
  Future<EmailOtpError?> verifyEmailOtp({
    required String email,
    required String otp,
    required String refId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ref
          .read(emailOtpDataSourceProvider)
          .verify(email: email, otp: otp, refId: refId);
      await ref.read(tokenStorageProvider).saveTokens(
        accessToken: (res['access_token'] ?? '').toString(),
        refreshToken: (res['refresh_token'] ?? '').toString(),
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      _openSocket();
      _syncLanguage();
      await checkActiveJob();
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      final status = e.response?.statusCode;
      final data = e.response?.data;
      final code = data is Map ? data['code']?.toString() : null;
      if (code == 'INVALID_OTP' || status == 401) return EmailOtpError.invalidOtp;
      if (code == 'TOO_MANY_ATTEMPTS' || status == 429) {
        return EmailOtpError.tooManyAttempts;
      }
      if (code == 'OTP_EXPIRED' || status == 410) return EmailOtpError.expired;
      if (status == 403) return EmailOtpError.accountBlocked;
      return EmailOtpError.failed;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return EmailOtpError.failed;
    }
  }

  /// Sends a code to add / verify [email] on the signed-in account.
  Future<EmailOtpSendResult> sendAccountEmail(String email) => _sendAccountCode(
    () => ref.read(emailOtpDataSourceProvider).sendAccountEmail(email),
    invalid: EmailOtpError.invalidEmail,
  );

  /// Verifies the add-email code; on success email login opens this same
  /// account. Null = success.
  Future<EmailOtpError?> verifyAccountEmail({
    required String email,
    required String otp,
    required String refId,
  }) => _verifyAccountCode(
    () => ref
        .read(emailOtpDataSourceProvider)
        .verifyAccountEmail(email: email, otp: otp, refId: refId),
  );

  /// SMS code to add / change the account's [phone] (E.164).
  Future<EmailOtpSendResult> sendAccountPhone(String phone) => _sendAccountCode(
    () => ref.read(emailOtpDataSourceProvider).sendAccountPhone(phone),
    invalid: EmailOtpError.invalidPhone,
  );

  /// Verifies the add/change-phone code; the number replaces the old one and
  /// SMS login with it opens this account. Null = success.
  Future<EmailOtpError?> verifyAccountPhone({
    required String phone,
    required String otp,
    required String refId,
  }) => _verifyAccountCode(
    () => ref
        .read(emailOtpDataSourceProvider)
        .verifyAccountPhone(phone: phone, otp: otp, refId: refId),
  );

  Future<EmailOtpSendResult> _sendAccountCode(
    Future<Map<String, dynamic>> Function() send, {
    required EmailOtpError invalid,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await send();
      state = state.copyWith(isLoading: false);
      return EmailOtpSendResult.sent(
        refId: (res['ref_id'] ?? '').toString(),
        isRegistered: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      final status = e.response?.statusCode;
      final code = _errorCode(e);
      final inUse = _inUse(code, status);
      if (inUse != null) return EmailOtpSendResult.failed(inUse);
      if (status == 503 || code == 'EMAIL_LOGIN_UNAVAILABLE') {
        return const EmailOtpSendResult.failed(EmailOtpError.unavailable);
      }
      if (status == 429) {
        return const EmailOtpSendResult.failed(EmailOtpError.rateLimited);
      }
      if (status == 400) return EmailOtpSendResult.failed(invalid);
      return const EmailOtpSendResult.failed(EmailOtpError.failed);
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return const EmailOtpSendResult.failed(EmailOtpError.failed);
    }
  }

  Future<EmailOtpError?> _verifyAccountCode(
    Future<Map<String, dynamic>> Function() verify,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await verify();
      state = state.copyWith(isLoading: false);
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      final status = e.response?.statusCode;
      final code = _errorCode(e);
      final inUse = _inUse(code, status);
      if (inUse != null) return inUse;
      if (code == 'OTP_MISMATCH') return EmailOtpError.mismatch;
      if (code == 'INVALID_OTP' || status == 401) return EmailOtpError.invalidOtp;
      if (code == 'OTP_RATE_LIMITED') return EmailOtpError.rateLimited;
      if (code == 'TOO_MANY_ATTEMPTS' || status == 429) {
        return EmailOtpError.tooManyAttempts;
      }
      if (code == 'OTP_EXPIRED' || status == 410) return EmailOtpError.expired;
      if (status == 400) return EmailOtpError.mismatch;
      return EmailOtpError.failed;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return EmailOtpError.failed;
    }
  }

  /// 409: the email / phone already belongs to another account.
  EmailOtpError? _inUse(String? code, int? status) {
    if (code == 'PHONE_IN_USE') return EmailOtpError.phoneInUse;
    if (code == 'EMAIL_IN_USE' || status == 409) return EmailOtpError.emailInUse;
    return null;
  }

  String? _errorCode(DioException e) {
    final data = e.response?.data;
    return data is Map ? data['code']?.toString() : null;
  }

  /// Whether the backend offers email instead for an SMS code that may not
  /// have arrived (`email_fallback`). False on any error.
  Future<bool> smsEmailFallbackOffered(String refId) async {
    try {
      final res = await ref.read(emailOtpDataSourceProvider).smsStatus(refId);
      return res['email_fallback'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Entry point for flows that save their own tokens (e.g. registration).
  void setAuthenticated() {
    state = state.copyWith(isAuthenticated: true);
    _openSocket();
    _syncLanguage();
  }
}

/// Why an email-OTP step failed.
enum EmailOtpError {
  invalidEmail,
  rateLimited,
  unavailable,
  accountBlocked,
  invalidOtp,
  tooManyAttempts,
  expired,

  /// Add-email: the address belongs to another account (409 EMAIL_IN_USE).
  emailInUse,

  /// Add-phone: the number belongs to another account (409 PHONE_IN_USE).
  phoneInUse,

  /// Add-phone: not a valid number (400 without a code).
  invalidPhone,

  /// Add-email: the code wasn't issued for this account/email (OTP_MISMATCH).
  mismatch,
  failed,
}

/// Outcome of [AuthController.sendEmailOtp].
class EmailOtpSendResult {
  const EmailOtpSendResult.sent({required this.refId, required this.isRegistered})
    : error = null;
  const EmailOtpSendResult.failed(this.error) : refId = '', isRegistered = false;

  final String refId;
  final bool isRegistered;
  final EmailOtpError? error;

  bool get ok => error == null;
}
