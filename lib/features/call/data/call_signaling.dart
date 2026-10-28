import 'dart:async';

import 'package:customer_app/core/services/socket_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final callSignalingProvider = Provider<CallSignaling>((ref) {
  return SocketCallSignaling(ref.watch(socketServiceProvider));
});

/// The call frames' path: the app's one WebSocket.
abstract class CallSignaling {
  /// Every frame from the server (the controller picks the call ones).
  Stream<Map<String, dynamic>> get frames;

  /// Sends a top-level frame such as `call_signal`. False when the socket is
  /// down.
  bool send(Map<String, dynamic> frame);

  /// Brings the socket up (even in the background, which a call needs) and
  /// waits for it, up to [timeout]. The relay keeps nothing: a frame sent to
  /// a phone whose socket is down is lost, so a call waits for it first.
  Future<bool> connect({Duration timeout = const Duration(seconds: 6)});

  /// After a call: put the socket back to sleep if the app is in the
  /// background, as the lifecycle handler would have.
  void release();
}

class SocketCallSignaling implements CallSignaling {
  SocketCallSignaling(this._socket);

  final SocketService _socket;

  @override
  Stream<Map<String, dynamic>> get frames => _socket.messages;

  @override
  bool send(Map<String, dynamic> frame) => _socket.sendFrame(frame);

  @override
  Future<bool> connect({Duration timeout = const Duration(seconds: 6)}) async {
    if (_socket.isConnected) return true;
    _socket.ensureConnected();
    final deadline = DateTime.now().add(timeout);
    while (!_socket.isConnected && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return _socket.isConnected;
  }

  @override
  void release() {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _socket.suspend();
    }
  }
}
