import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(name: 'room_id') String? roomId,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'sender_role') required String senderRole,
    @JsonKey(name: 'msg_type', defaultValue: 'text') required String msgType,
    required String text,
    // Image messages: the storage key, and a presigned URL that expires in
    // ~5 minutes (WebSocket frames carry only the URL).
    @JsonKey(name: 'file_key') String? fileKey,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'detected_lang') String? detectedLang,
    @JsonKey(name: 'sent_at') required DateTime sentAt,
  }) = _ChatMessage;

  const ChatMessage._();

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(_preprocessJson(json));

  bool get isImage => msgType == 'image';

  /// A line from the server, not either party (e.g. "📞 โทร 1:24 นาที"
  /// after a call).
  bool get isSystem => msgType == 'system';

  static Map<String, dynamic> _preprocessJson(Map<String, dynamic> json) {
    final Map<String, dynamic> mappedJson = Map<String, dynamic>.from(json);

    // Normalize text (WebSocket frames send it as `content`)
    if (!mappedJson.containsKey('text') && mappedJson.containsKey('message')) {
      mappedJson['text'] = mappedJson['message'];
    }
    if (mappedJson['text'] == null && mappedJson['content'] != null) {
      mappedJson['text'] = mappedJson['content'];
    }
    mappedJson['text'] ??= '';

    // Normalize sender_id
    if (!mappedJson.containsKey('sender_id') &&
        mappedJson.containsKey('senderId')) {
      mappedJson['sender_id'] = mappedJson['senderId'];
    }

    // Normalize sender_role (WebSocket frames send `sender_type`)
    if (!mappedJson.containsKey('sender_role') &&
        mappedJson.containsKey('senderRole')) {
      mappedJson['sender_role'] = mappedJson['senderRole'];
    }
    mappedJson['sender_role'] ??= mappedJson['sender_type'] ?? '';
    // An empty media_url (text frames) means none.
    if (mappedJson['media_url'] == '') mappedJson['media_url'] = null;

    // Normalize sent_at
    if (!mappedJson.containsKey('sent_at')) {
      if (mappedJson.containsKey('created_at') &&
          mappedJson['created_at'] != null) {
        mappedJson['sent_at'] = mappedJson['created_at'];
      } else if (mappedJson.containsKey('timestamp') &&
          mappedJson['timestamp'] != null) {
        final ts = mappedJson['timestamp'];
        if (ts is int) {
          mappedJson['sent_at'] = DateTime.fromMillisecondsSinceEpoch(
            ts,
          ).toIso8601String();
        } else if (ts is String) {
          mappedJson['sent_at'] = ts;
        }
      } else {
        mappedJson['sent_at'] = DateTime.now().toIso8601String();
      }
    }

    // If sender_id is not provided, default it
    if (!mappedJson.containsKey('sender_id') ||
        mappedJson['sender_id'] == null) {
      mappedJson['sender_id'] = '';
    }

    return mappedJson;
  }
}
