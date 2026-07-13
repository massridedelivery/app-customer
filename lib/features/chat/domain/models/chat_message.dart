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
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'detected_lang') String? detectedLang,
    @JsonKey(name: 'sent_at') required DateTime sentAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(_preprocessJson(json));

  static Map<String, dynamic> _preprocessJson(Map<String, dynamic> json) {
    final Map<String, dynamic> mappedJson = Map<String, dynamic>.from(json);

    // Normalize text
    if (!mappedJson.containsKey('text') && mappedJson.containsKey('message')) {
      mappedJson['text'] = mappedJson['message'];
    }

    // Normalize sender_id
    if (!mappedJson.containsKey('sender_id') &&
        mappedJson.containsKey('senderId')) {
      mappedJson['sender_id'] = mappedJson['senderId'];
    }

    // Normalize sender_role
    if (!mappedJson.containsKey('sender_role') &&
        mappedJson.containsKey('senderRole')) {
      mappedJson['sender_role'] = mappedJson['senderRole'];
    }

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
