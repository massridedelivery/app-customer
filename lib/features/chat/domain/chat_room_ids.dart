/// The backend keys chat rooms on a vertical-prefixed id — `job:{id}` (ride),
/// `order:{id}` (food), `messenger:{id}` — in WebSocket frames and pushes,
/// while the app's chat screens take the bare id.
const _prefixes = ['job:', 'order:', 'messenger:'];

/// [roomId] without its `job:` / `order:` / `messenger:` prefix.
String bareChatRoomId(String roomId) {
  for (final p in _prefixes) {
    if (roomId.startsWith(p)) return roomId.substring(p.length);
  }
  return roomId;
}

/// The app route that opens the chat for a backend [roomId]: rides at
/// `/chat/{id}`, food at `/food-order/chat/{id}`, messenger at
/// `/messenger/chat/{id}`. A bare id is taken as a ride.
String chatRouteForRoom(String roomId) {
  final id = bareChatRoomId(roomId);
  if (roomId.startsWith('order:')) return '/food-order/chat/$id';
  if (roomId.startsWith('messenger:')) return '/messenger/chat/$id';
  return '/chat/$id';
}

/// The storage key of a chat photo from its presigned `media_url`
/// (`…/chat/{room}/{uuid}.jpg?X-Amz-…`), for messages that only carry the URL
/// (WebSocket frames). Null when the URL doesn't look like one.
String? chatFileKeyFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final path = Uri.tryParse(url)?.path;
  if (path == null) return null;
  final i = path.indexOf('chat/');
  return i < 0 ? null : Uri.decodeComponent(path.substring(i));
}
