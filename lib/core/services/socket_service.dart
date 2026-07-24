import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:customer_app/core/configs/app_env.dart';
import 'package:customer_app/core/data/token_storage.dart';
import 'package:customer_app/core/managers/providers.dart';
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
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  static const int maxReconnectAttempts = 5;
  // Resolved from the active flavor (env/dev.json | env/prod.json); defaults to dev.
  static const String baseUrl = Env.wsBaseUrl;

  SocketService(this._tokenStorage);

  void connect({bool isReconnect = false}) {
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
      _channel = WebSocketChannel.connect(url);

      debugPrint('SocketService: Connecting to $url');

      // Use ready future to detect connection success immediately
      final currentChannel = _channel;
      currentChannel?.ready
          .then((_) {
            if (currentChannel == _channel) {
              debugPrint('SocketService: Connected successfully (via ready).');
              _isConnected = true;
              _isConnecting = false;
              _reconnectAttempts = 0;
            }
          })
          .catchError((error) {
            debugPrint('SocketService: Connection ready error: $error');
          });

      _subscription = _channel!.stream.listen(
        (data) {
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

      // Setup Keep-Alive Heartbeat (15 seconds)
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
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

  void _handleDisconnect() {
    // If already cleaned up, do nothing to prevent double-disconnection retry storm
    if (_channel == null && !_isConnecting && !_isConnected) {
      return;
    }

    _isConnected = false;
    _isConnecting = false;
    _channel?.sink.close();
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;

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
    _pingTimer?.cancel();
    _pingTimer = null;
    _isConnected = false;
    _isConnecting = false;
    _channel?.sink.close();
    _channel = null;
    _subscription?.cancel();
    _subscription = null;
    debugPrint('SocketService: Disconnected manually.');
  }
}
