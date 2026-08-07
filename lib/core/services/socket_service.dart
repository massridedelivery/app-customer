import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:customer_app/core/configs/app_env.dart';
import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/socket_channel_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'socket_service.g.dart';

@Riverpod(keepAlive: true)
SocketService socketService(Ref ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  final service = SocketService(tokenStorage);
  ref.onDispose(() => service.disconnect());
  return service;
}

class SocketService {
  final TokenStorage _tokenStorage;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // Expose a broadcast stream for UI/Controllers to listen to events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool _isConnected = false;
  bool _isConnecting = false;

  /// Set while the app is backgrounded — see [suspend]. Blocks both new
  /// connects and reconnect scheduling until [ensureConnected] clears it.
  bool _isSuspended = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  /// When the last frame arrived from the server (or the handshake completed).
  /// Used by [ensureConnected] to spot a connection that survived on paper but
  /// has gone silent — see [_staleAfter].
  DateTime? _lastInboundAt;

  static const int maxReconnectAttempts = 5;

  /// How often to ping. Applies at two levels: RFC 6455 ping frames, which
  /// `dart:io` answers-checks itself and which close the socket on a missing
  /// pong, and the app-level `{"type":"ping"}` message the backend guide asks
  /// for (it keeps the server's idle timer fed; the protocol frames do the
  /// dead-connection detection).
  static const Duration pingInterval = Duration(seconds: 15);

  /// Handshake budget. Bounds a connect that never resolves — without it the
  /// service can sit in `_isConnecting` forever and refuse every later attempt.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Silence beyond this is treated as a dead connection *when the app comes
  /// back to the foreground* ([ensureConnected]). Deliberately not a background
  /// timer: an idle session legitimately receives nothing for minutes, so this
  /// only decides whether a resume reuses the socket or reopens it — a cheap
  /// call to get wrong in either direction, unlike killing a live socket.
  static const Duration _staleAfter = Duration(seconds: 45);

  // Resolved from the active flavor (env/dev.json | env/prod.json); defaults to dev.
  static const String baseUrl = Env.wsBaseUrl;

  SocketService(this._tokenStorage);

  /// Makes sure a connection exists, with a **fresh** reconnect budget.
  ///
  /// Call this whenever the app gains a new reason to believe a socket should
  /// be up — the user just authenticated, or the app returned to the
  /// foreground. Unlike [connect] this resets [_reconnectAttempts], so a socket
  /// that already burnt through [maxReconnectAttempts] (and would otherwise
  /// stay dead for the rest of the session) gets another chance. Safe to call
  /// repeatedly: it's a no-op while the connection is live or in flight.
  void ensureConnected() {
    _isSuspended = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    // A socket that has been silent past [_staleAfter] is presumed dead: while
    // the app was backgrounded every timer was frozen, so nothing — not the
    // ping frames, not the stream's own error handling — was in a position to
    // notice. Reopen rather than trust it.
    if (_isConnected && _isStale) {
      debugPrint('SocketService: Connection went stale, reconnecting.');
      _teardown();
      connect();
      return;
    }

    if (_isConnected || _isConnecting) return;

    // Drop anything left behind by a connection that never came up, otherwise
    // the `_channel != null` guard in [connect] silently blocks the retry.
    _teardown();
    connect();
  }

  /// Puts the socket to sleep while the app is backgrounded.
  ///
  /// Measured on a device: Android revokes network access from backgrounded
  /// apps outright — every retry failed at DNS resolution ("Failed host lookup
  /// … errno = 7") yet still consumed the [maxReconnectAttempts] budget, so
  /// ~80s in the background was enough to spend it all on attempts that could
  /// not possibly succeed. Closing now and standing down keeps the budget (and
  /// the radio) intact until [ensureConnected] revives things on resume.
  void suspend() {
    if (_isSuspended) return;
    debugPrint('SocketService: Suspended (app backgrounded).');
    _isSuspended = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _teardown();
  }

  void connect({bool isReconnect = false}) {
    if (_isSuspended) return;
    if (_isConnected || _isConnecting || _channel != null) return;

    if (!isReconnect) {
      _reconnectAttempts = 0;
    }

    final token = _tokenStorage.getAccessToken();
    if (token == null) {
      debugPrint('SocketService: No access token available, cannot connect.');
      return;
    }

    final url = Uri.parse('$baseUrl?token=$token');
    try {
      _isConnecting = true;
      _channel = connectSocketChannel(
        url,
        pingInterval: pingInterval,
        connectTimeout: connectTimeout,
      );

      // Log the endpoint only — `url` carries the access token in its query
      // string, and debugPrint is not compiled out of release builds.
      debugPrint('SocketService: Connecting to $baseUrl');

      // Use ready future to detect connection success immediately
      final currentChannel = _channel;
      currentChannel?.ready
          .then((_) {
            if (currentChannel == _channel) {
              debugPrint('SocketService: Connected successfully (via ready).');
              _isConnected = true;
              _isConnecting = false;
              _reconnectAttempts = 0;
              _lastInboundAt = DateTime.now();
            }
          })
          .catchError((error) {
            debugPrint('SocketService: Connection ready error: $error');
          });

      _subscription = _channel!.stream.listen(
        (data) {
          _lastInboundAt = DateTime.now();
          if (!_isConnected) {
            debugPrint('SocketService: Connected successfully.');
            _isConnected = true;
            _isConnecting = false;
            _reconnectAttempts = 0;
          }
          try {
            final decoded = jsonDecode(data as String);
            debugPrint('SocketService: Received message: $decoded');
            _messageController.add(decoded);
          } catch (e) {
            debugPrint('SocketService: Failed to parse message $e');
          }
        },
        onDone: () {
          debugPrint('SocketService: Connection closed.');
          _handleDisconnect();
        },
        onError: (error) {
          debugPrint('SocketService: Connection error: $error');
          _handleDisconnect();
        },
      );

      // App-level keep-alive, on top of the protocol ping frames the channel
      // itself sends (see [pingInterval]).
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(pingInterval, (timer) {
        if (_isConnected) {
          sendMessage('ping', {});
        }
      });
    } catch (e) {
      debugPrint('SocketService: Connection failed $e');
      _isConnecting = false;
      _handleDisconnect();
    }
  }

  void sendMessage(String type, Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      final payload = jsonEncode({'type': type, 'data': data});
      _channel!.sink.add(payload);
    } else {
      debugPrint('SocketService: Cannot send message, not connected.');
    }
  }

  /// Whether nothing has arrived from the server for longer than [_staleAfter].
  bool get _isStale {
    final last = _lastInboundAt;
    if (last == null) return true;
    return DateTime.now().difference(last) > _staleAfter;
  }

  /// Closes the channel and stops the heartbeat, without scheduling a retry.
  void _teardown() {
    _isConnected = false;
    _isConnecting = false;
    _lastInboundAt = null;
    _channel?.sink.close();
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _handleDisconnect() {
    // If already cleaned up, do nothing to prevent double-disconnection retry storm
    if (_channel == null && !_isConnecting && !_isConnected) {
      return;
    }

    _teardown();

    // Backgrounded: the OS closed this socket and will refuse the next one.
    // Stand down and let the resume path reconnect instead of burning retries.
    if (_isSuspended) {
      debugPrint('SocketService: Suspended, skipping reconnect.');
      return;
    }

    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      // Exponential backoff: 2^attempts * 1000 ms -> 2s, 4s, 8s...
      final delay = Duration(
        milliseconds: 1000 * pow(2, _reconnectAttempts).toInt(),
      );
      debugPrint(
        'SocketService: Reconnecting in ${delay.inSeconds} seconds (Attempt $_reconnectAttempts)...',
      );

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        connect(isReconnect: true);
      });
    } else {
      debugPrint('SocketService: Max reconnect attempts reached.');
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    // A manual disconnect ends the session's retry history — the next
    // [ensureConnected] (e.g. after the next login) starts from a clean slate.
    _reconnectAttempts = 0;
    _teardown();
    debugPrint('SocketService: Disconnected manually.');
  }
}
