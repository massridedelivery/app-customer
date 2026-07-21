import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/config/app_env.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:customer_app/core/data/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';

class ApiService {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Ref _ref;

  // Resolved from the active flavor (env/dev.json | env/prod.json) via
  // --dart-define-from-file; defaults to dev.
  static const String baseUrl = Env.apiBaseUrl;

  // Marks a request that has already been replayed after a token refresh, so a
  // subsequent 401 logs out instead of triggering another refresh (loop guard).
  static const String _retriedFlag = 'retried_after_refresh';

  Completer<bool>? _refreshCompleter;

  ApiService(this._tokenStorage, this._ref)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          contentType: 'application/json',
        ),
      ) {
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    // Only log request/response headers in debug builds — headers carry the
    // `Authorization: Bearer <token>`, which must never be logged in release.
    if (!kReleaseMode) {
      _dio.interceptors.add(
        TalkerDioLogger(
          settings: const TalkerDioLoggerSettings(
            printRequestHeaders: true,
            printResponseHeaders: true,
          ),
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _tokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Only 401s go through the refresh flow; everything else surfaces.
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          // A request that already carried a freshly refreshed token and STILL
          // got 401 means the new token is genuinely rejected. Don't refresh
          // again (which would loop) — log out once and surface the error.
          if (error.requestOptions.extra[_retriedFlag] == true) {
            _handleLogout();
            return handler.next(error);
          }

          if (!_tokenStorage.hasToken) {
            // No token in storage, but got 401? Force logout for safety.
            _handleLogout();
            return handler.next(error);
          }

          // Coalesce concurrent 401s onto a single in-flight refresh.
          if (_refreshCompleter != null) {
            final isRefreshed = await _refreshCompleter!.future;
            if (isRefreshed) {
              return _retry(error, handler);
            }
            // The shared refresh failed; the initiator already logged out, so
            // just surface the error instead of starting another refresh.
            return handler.next(error);
          }

          _refreshCompleter = Completer<bool>();
          final isRefreshed = await _refreshToken();
          _refreshCompleter!.complete(isRefreshed);
          _refreshCompleter = null;

          if (isRefreshed) {
            return _retry(error, handler);
          } else {
            _handleLogout();
            return handler.next(error);
          }
        },
      ),
    );
  }

  Future<void> _retry(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final opts = Options(
      method: error.requestOptions.method,
      headers: Map<String, dynamic>.from(error.requestOptions.headers),
      // Tag the replay so a second 401 logs out instead of looping (see
      // onError). The tag rides on requestOptions.extra of the cloned request.
      extra: {...error.requestOptions.extra, _retriedFlag: true},
    );
    opts.headers!['Authorization'] =
        'Bearer ${_tokenStorage.getAccessToken()}';

    try {
      final cloneReq = await _dio.request(
        error.requestOptions.path,
        options: opts,
        data: error.requestOptions.data,
        queryParameters: error.requestOptions.queryParameters,
      );
      return handler.resolve(cloneReq);
    } catch (e) {
      // Do NOT log out here: a genuine auth failure on the replay is a 401,
      // which the interceptor's onError already handled via the retried flag.
      // Reaching this catch means a transport/5xx/timeout error — the session
      // is still valid, so surface the failure without dropping it.
      return handler.next(error);
    }
  }

  void _handleLogout() {
    _tokenStorage.clearTokens();
    // Reset auth state on a microtask. Calling AuthController.logout() straight
    // from this interceptor re-enters ApiService's own provider (logout reads
    // providers that transitively depend on ApiService) and throws
    // CircularDependencyError; deferring runs it after the current chain unwinds
    // so the router redirect still fires.
    Future.microtask(() {
      try {
        _ref.read(authControllerProvider.notifier).logout();
      } catch (_) {
        // Tokens are already cleared above, so the router redirect still lands
        // the user on login even if the controller can't be reached here.
      }
    });
  }

  Future<bool> _refreshToken() async {
    final refreshToken = _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final noAuthDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          contentType: 'application/json',
          connectTimeout: const Duration(seconds: 15),
        ),
      );

      // Add logger to see the refresh request in console (debug only — the
      // response body contains the new access/refresh tokens).
      if (!kReleaseMode) {
        noAuthDio.interceptors.add(
          TalkerDioLogger(
            settings: const TalkerDioLoggerSettings(
              printRequestHeaders: true,
              printResponseHeaders: true,
              printResponseMessage: true,
            ),
          ),
        );
      }

      final response = await noAuthDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        if (newAccessToken != null && newRefreshToken != null) {
          await _tokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
