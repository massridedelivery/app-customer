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

  /// Fires once each time the socket comes back up *after* a mid-session drop
  /// (not the first connect, and not the reconnect that follows a resume — the
  /// app-lifecycle resync covers that). Frames pushed during the gap are lost
  /// (no server replay), so controllers listen here to immediately re-fetch the
  /// authoritative state instead of waiting for their next poll tick.
  final _reconnectedController = StreamController<void>.broadcast();

  Stream<void> get reconnected => _reconnectedController.stream;

  /// Whether we have already had a live connection in the current foreground
  /// session. Distinguishes a genuine reconnect (fire [reconnected]) from the
  /// first connect / the post-resume connect (don't). Cleared on [suspend].
  bool _hasConnectedOnce = false;

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

  /// The exponential backoff grows to this many attempts, then holds — the
  /// delay ceiling is `2^_backoffCeilingExponent` seconds ([_maxReconnectDelay]).
  /// Reconnection itself does **not** stop there: while the app is foregrounded
  /// we keep retrying at that ceiling forever, so a socket that drops mid-ride
  /// always recovers instead of dying for the rest of the trip.
  static const int _backoffCeilingExponent = 5; // 2^5 = 32s ceiling
  static const Duration _maxReconnectDelay = Duration(seconds: 32);

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
  /// foreground. Unlike [connect] this resets [_reconnectAttempts] so the
  /// backoff starts from the bottom again, and clears [_isSuspended] so a socket
  /// stood down for the background regains its retry loop. Safe to call
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
  /// … errno = 7") and, now that the foreground loop retries forever, would
  /// otherwise spin every 32s for the whole time backgrounded. Closing now and
  /// standing down (via [_isSuspended]) keeps the radio idle until
  /// [ensureConnected] revives things on resume.
  void suspend() {
    if (_isSuspended) return;
    debugPrint('SocketService: Suspended (app backgrounded).');
    _isSuspended = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    // The post-resume connect should count as a fresh first connect: the
    // app-lifecycle resync already refetches on resume, so we don't also want to
    // fire [reconnected] for it.
    _hasConnectedOnce = false;
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
              _onConnectionEstablished('via ready');
            }
          })
          .catchError((error) {
            debugPrint('SocketService: Connection ready error: $error');
          });

      _subscription = _channel!.stream.listen(
        (data) {
          _lastInboundAt = DateTime.now();
          if (!_isConnected) {
            _onConnectionEstablished('first frame');
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

  /// Marks the connection live (idempotent per channel) and, when this is a
  /// reconnect after a mid-session drop, notifies listeners to resync.
  void _onConnectionEstablished(String via) {
    if (_isConnected) return;
    debugPrint('SocketService: Connected successfully ($via).');
    _isConnected = true;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _lastInboundAt = DateTime.now();

    if (_hasConnectedOnce) {
      debugPrint('SocketService: Reconnected — signalling resync.');
      _reconnectedController.add(null);
    }
    _hasConnectedOnce = true;
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

    _reconnectAttempts++;
    // Exponential backoff (2s, 4s, 8s, 16s, 32s) that then HOLDS at the 32s
    // ceiling and keeps retrying indefinitely while foregrounded. Never give up
    // on our own: a mid-ride socket drop must always recover, and [suspend]
    // already stands the retries down while backgrounded so this can't burn the
    // radio. `min` on the exponent keeps `pow` from overflowing on a long
    // outage.
    final exponent =
        _reconnectAttempts < _backoffCeilingExponent
        ? _reconnectAttempts
        : _backoffCeilingExponent;
    final expoMs = 1000 * pow(2, exponent).toInt();
    final delay = Duration(
      milliseconds:
          expoMs < _maxReconnectDelay.inMilliseconds
          ? expoMs
          : _maxReconnectDelay.inMilliseconds,
    );
    debugPrint(
      'SocketService: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)...',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect(isReconnect: true);
    });
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
