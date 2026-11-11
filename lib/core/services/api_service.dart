import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:customer_app/core/auth/account_block.dart';
import 'package:customer_app/core/configs/app_env.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/services/retry_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/core/localization/locale_controller.dart';

/// How a `POST /auth/refresh` ended.
enum RefreshOutcome {
  /// New pair stored.
  refreshed,

  /// 401: the refresh token is no longer valid — the only case that logs out.
  unauthorized,

  /// Suspended / deleted account; already handled (account-blocked screen).
  blocked,

  /// Timeout, no connection, 5xx, or an unusable answer, still failing after
  /// the retries. The session is kept; the next 401 tries again.
  failed,
}

class ApiService {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Ref _ref;

  /// Client for `POST /auth/refresh` (no auth header, no logging: the body is
  /// the token pair). Injectable for tests.
  final Dio _refreshDio;

  /// Pause before refresh retry [attempt] (1-based). Injectable for tests.
  final Duration Function(int attempt) _refreshBackoff;

  /// Refresh retries stay inside this window: the backend hands back the same
  /// pair for a reused refresh token for 60 s, so a retry after a lost answer
  /// still succeeds.
  static const Duration _refreshWindow = Duration(seconds: 50);

  // Resolved from the active flavor (env/dev.json | env/prod.json) via
  // --dart-define-from-file; defaults to dev.
  static const String baseUrl = Env.apiBaseUrl;

  // Marks a request that has already been replayed after a token refresh, so a
  // subsequent 401 logs out instead of triggering another refresh (loop guard).
  static const String _retriedFlag = 'retried_after_refresh';

  Completer<RefreshOutcome>? _refreshCompleter;

  ApiService(
    this._tokenStorage,
    this._ref, {
    Dio? dio,
    Dio? refreshDio,
    Duration Function(int attempt)? refreshBackoff,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 15),
               contentType: 'application/json',
             ),
           ),
       _refreshDio =
           refreshDio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               contentType: 'application/json',
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
             ),
           ),
       _refreshBackoff =
           refreshBackoff ??
           ((attempt) => Duration(seconds: 1 << (attempt - 1).clamp(0, 3))) {
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    // Debug builds only, and never a token: request headers carry
    // `Authorization: Bearer <token>`, and the /auth/* answers carry the
    // token pair, so neither is printed.
    if (!kReleaseMode) {
      _dio.interceptors.add(
        TalkerDioLogger(
          settings: TalkerDioLoggerSettings(
            printRequestHeaders: false,
            // register-device / unregister-device bodies carry the FCM token.
            requestFilter: (o) => !o.path.startsWith('/api/notifications/'),
            printResponseHeaders: true,
            // The PDPA export is the customer's personal data: never in a log,
            // not even a debug one.
            responseFilter: (r) =>
                !r.requestOptions.path.startsWith('/api/customer/export') &&
                !r.requestOptions.path.startsWith('/auth/'),
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
          // Localize backend error messages (th|en) to the user's chosen
          // language; omitting it defaults to English server-side.
          options.headers['X-Lang'] = _ref
              .read(localeControllerProvider)
              .languageCode;
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Suspended / deleted account: no refresh, no retry — drop the
          // session and let the router show the account-blocked screen.
          final block = accountBlockOf(error.response);
          if (block != null) {
            _handleAccountBlocked(block);
            return handler.next(error);
          }

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
            // Guest (no token): a 401 just means this endpoint needs an account,
            // e.g. a token-scoped call reached while browsing. Surface it so the
            // caller can handle it — do NOT force logout, which would reset a
            // browsing guest (App Store 5.1.1 guest mode). There is nothing to
            // refresh without a token anyway.
            return handler.next(error);
          }

          // Sent with a token that has since been replaced (its answer came
          // back after a refresh finished): replay with the new one instead
          // of refreshing again.
          final sentWith = error.requestOptions.headers['Authorization'];
          final current = _tokenStorage.getAccessToken();
          if (_refreshCompleter == null &&
              current != null &&
              sentWith != null &&
              sentWith != 'Bearer $current') {
            return _retry(error, handler);
          }

          // One refresh at a time: concurrent 401s wait for it.
          if (_refreshCompleter != null) {
            final outcome = await _refreshCompleter!.future;
            if (outcome == RefreshOutcome.refreshed) {
              return _retry(error, handler);
            }
            // The initiator already acted on the outcome (logout only on 401).
            return handler.next(error);
          }

          final completer = _refreshCompleter = Completer<RefreshOutcome>();
          final outcome = await _refreshToken();
          completer.complete(outcome);
          _refreshCompleter = null;

          switch (outcome) {
            case RefreshOutcome.refreshed:
              return _retry(error, handler);
            case RefreshOutcome.unauthorized:
              _handleLogout();
              return handler.next(error);
            case RefreshOutcome.blocked:
            case RefreshOutcome.failed:
              // Blocked is already handled; a failed refresh keeps the session.
              return handler.next(error);
          }
        },
      ),
    );

    // Transient-failure retry layer (SCRUM-50). Added AFTER the auth
    // interceptor so a 401 is refreshed first; this only ever sees the
    // 503/500/429/timeout errors the auth interceptor passes through.
    _dio.interceptors.add(RetryInterceptor(_dio));
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
    opts.headers!['Authorization'] = 'Bearer ${_tokenStorage.getAccessToken()}';

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

  void _handleAccountBlocked(AccountBlock reason) {
    // Several in-flight calls can come back blocked at once; act on the first.
    if (_ref.read(accountBlockProvider) != null) return;
    _tokenStorage.clearTokens();
    // Deferred for the same re-entrancy reason as [_handleLogout].
    Future.microtask(() {
      _ref.read(accountBlockProvider.notifier).block(reason);
      try {
        _ref.read(authControllerProvider.notifier).logout();
      } catch (_) {}
    });
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

  /// `POST /auth/refresh {refresh_token}` → `{access_token, refresh_token}`.
  ///
  /// The new pair is stored the moment it arrives. A timeout, lost
  /// connection, 5xx, 408/429 or an answer without tokens is retried with the
  /// SAME refresh token (the backend returns the same pair again within 60 s)
  /// until [_refreshWindow] runs out. Only a 401 means the session is over.
  /// Callers serialise it via [_refreshCompleter].
  Future<RefreshOutcome> _refreshToken() async {
    final refreshToken = _tokenStorage.getRefreshToken();
    if (refreshToken == null) return RefreshOutcome.unauthorized;

    final started = DateTime.now();
    for (var attempt = 1; ; attempt++) {
      try {
        final response = await _refreshDio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        final data = response.data;
        final access = data is Map ? data['access_token'] : null;
        final refresh = data is Map ? data['refresh_token'] : null;
        if (access is String &&
            access.isNotEmpty &&
            refresh is String &&
            refresh.isNotEmpty) {
          await _tokenStorage.saveTokens(
            accessToken: access,
            refreshToken: refresh,
          );
          return RefreshOutcome.refreshed;
        }
        // 2xx without a pair: treat like a server error and try again.
      } on DioException catch (e) {
        // The refresh itself can be refused for a suspended/deleted account.
        final block = accountBlockOf(e.response);
        if (block != null) {
          _handleAccountBlocked(block);
          return RefreshOutcome.blocked;
        }
        final status = e.response?.statusCode;
        if (status == 401) return RefreshOutcome.unauthorized;
        final retryable =
            status == null || status >= 500 || status == 408 || status == 429;
        // Any other 4xx won't change on a retry, but isn't a 401 either:
        // keep the session.
        if (!retryable) return RefreshOutcome.failed;
      } catch (_) {
        // Unexpected (e.g. a malformed body): retry like a server error.
      }

      final wait = _refreshBackoff(attempt);
      if (DateTime.now().add(wait).difference(started) > _refreshWindow ||
          attempt >= 6) {
        return RefreshOutcome.failed;
      }
      await Future<void>.delayed(wait);
    }
  }
}
