import 'dart:typed_data';

import 'package:customer_app/features/chat/data/chat_media_repository.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_state.freezed.dart';

@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) List<ChatMessage> messages,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    String? error,
    @Default(false) bool hasReachedEnd,
    // Photos this device sent, keyed by message id (the temporary `opt-` id,
    // then the server id once the WebSocket echo arrives): shown from memory
    // instead of downloading them back, with the upload's progress / failure.
    @Default({}) Map<String, ChatImageUpload> imageUploads,
  }) = _ChatState;
}

enum ChatImageUploadStatus { uploading, sending, sent, failed }

/// A photo being sent from this device.
@immutable
class ChatImageUpload {
  const ChatImageUpload({
    required this.bytes,
    this.status = ChatImageUploadStatus.uploading,
    this.progress = 0,
    this.prepared = false,
    this.fileKey,
    this.error,
  });

  /// What the bubble shows: the picked photo, then the processed JPEG.
  final Uint8List bytes;
  final ChatImageUploadStatus status;

  /// 0..1 across processing, upload and sending.
  final double progress;

  /// [bytes] are already scaled down and stripped of EXIF.
  final bool prepared;

  /// Set once the upload is confirmed; a retry then only re-sends the message.
  final String? fileKey;
  final ChatImageError? error;

  bool get inFlight =>
      status == ChatImageUploadStatus.uploading ||
      status == ChatImageUploadStatus.sending;

  ChatImageUpload copyWith({
    Uint8List? bytes,
    ChatImageUploadStatus? status,
    double? progress,
    bool? prepared,
    String? fileKey,
    ChatImageError? error,
    bool clearError = false,
  }) => ChatImageUpload(
    bytes: bytes ?? this.bytes,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    prepared: prepared ?? this.prepared,
    fileKey: fileKey ?? this.fileKey,
    error: clearError ? null : (error ?? this.error),
  );
}
