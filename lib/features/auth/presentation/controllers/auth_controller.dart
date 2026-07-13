import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/push_notification_service.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
import 'package:customer_app/features/auth/domain/entities/phone_login_response.dart';
import 'package:customer_app/features/auth/domain/usecases/phone_login_usecase_impl.dart';
import 'package:customer_app/features/auth/presentation/states/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Added imports for PhoneLoginUseCase and Failure
import 'package:customer_app/core/error/failures.dart';

// Added imports for LiveRideController
import 'package:customer_app/features/active_orders/data/repositories/active_orders_repository_impl.dart';
import 'package:customer_app/features/live_ride/presentation/controllers/live_ride_controller.dart';
import 'package:customer_app/features/profile/data/repositories/profile_repository_impl.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    // Listen to LiveRideController for job status changes
    ref.listen(liveRideControllerProvider, (previous, next) {
      if (previous?.jobStatus != next.jobStatus) {
        if (next.jobStatus == 'CANCELLED' || next.jobStatus == 'COMPLETED') {
          clearActiveJob();
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
      return const AuthState(isAuthenticated: true);
    }
    return const AuthState(isAuthenticated: false);
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
        data: {'email': email, 'password': password},
      );

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      if (accessToken != null && refreshToken != null) {
        await ref
            .read(tokenStorageProvider)
            .saveTokens(accessToken: accessToken, refreshToken: refreshToken);
        state = state.copyWith(isLoading: false, isAuthenticated: true);

        // Check for active job after login
        await checkActiveJob();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid response from server',
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['error'] ?? 'Invalid credentials',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    // Drop this device's push token while the session token is still valid.
    await ref.read(pushNotificationServiceProvider).unregisterOnLogout();
    try {
      final hasToken = ref.read(tokenStorageProvider).hasToken;
      if (hasToken) {
        await ref.read(profileRepositoryProvider).logout();
      }
    } catch (e) {
      // Suppress exception so local logout still completes
    } finally {
      // Disconnect socket connection on logout
      ref.read(socketServiceProvider).disconnect();
      await ref.read(tokenStorageProvider).clearTokens();
      state = const AuthState(isAuthenticated: false, activeJobId: null);
    }
  }

  void clearActiveJob() {
    state = state.copyWith(activeJobId: null);
  }

  // ─── OTP FLOW (Real API) ──────────────────────────────────────────────────

  /// Calls POST /auth/otp/send and returns the ref_id to use in [verifyOtp].
  Future<String?> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.dio.post(
        '/auth/otp/send',
        data: {'phone': phone},
      );
      state = state.copyWith(isLoading: false);
      return response.data['ref_id'] as String?;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'ส่ง OTP ไม่สำเร็จ',
      );
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Calls POST /auth/otp/verify. Saves tokens on success.
  Future<void> verifyOtp({
    required String phone,
    required String otp,
    required String refId,
    required String role,
    String? fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.dio.post(
        '/auth/otp/verify',
        data: {
          'phone': phone,
          'otp': otp,
          'ref_id': refId,
          'role': role,
          'full_name': ?fullName,
        },
      );

      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      if (accessToken != null && refreshToken != null) {
        await ref
            .read(tokenStorageProvider)
            .saveTokens(accessToken: accessToken, refreshToken: refreshToken);
        state = state.copyWith(isLoading: false, isAuthenticated: true);
        await checkActiveJob();
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid OTP response');
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'OTP ไม่ถูกต้อง',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.toString());
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
            await checkActiveJob(); // Keep existing behavior
          } else {
            state = state.copyWith(isLoading: false);
          }
          return true;
        },
      );
    } catch (e) {
      // Catch any unexpected exceptions
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void setAuthenticated() {
    state = state.copyWith(isAuthenticated: true);
  }
}
