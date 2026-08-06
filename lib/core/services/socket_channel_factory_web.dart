import 'package:web_socket_channel/web_socket_channel.dart';

/// Browser channel. The browser owns the ping/pong and connect timing and
/// exposes no API for either, so both parameters are accepted and ignored —
/// they exist to keep one call signature across platforms.
WebSocketChannel connectSocketChannel(
  Uri url, {
  required Duration pingInterval,
  required Duration connectTimeout,
}) {
  return WebSocketChannel.connect(url);
}
