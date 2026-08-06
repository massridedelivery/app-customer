import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Mobile/desktop channel with RFC 6455 ping frames enabled.
///
/// `dart:io` sends a ping every [pingInterval] and closes the socket when the
/// peer doesn't pong within the same window — the only reliable way to notice a
/// half-open connection (WiFi ↔ mobile data handover, sleeping radio), where
/// the stream stays open forever and neither `onDone` nor `onError` ever fires.
/// The pongs are answered by the server's WebSocket layer, so this needs no
/// backend support.
///
/// [connectTimeout] bounds the handshake so a black-holed connect surfaces as a
/// stream error instead of pinning the service in its "connecting" state.
WebSocketChannel connectSocketChannel(
  Uri url, {
  required Duration pingInterval,
  required Duration connectTimeout,
}) {
  return IOWebSocketChannel.connect(
    url,
    pingInterval: pingInterval,
    connectTimeout: connectTimeout,
  );
}
