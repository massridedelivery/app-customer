import 'dart:async';
import 'dart:typed_data';

import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/chat/data/chat_image_processor.dart';
import 'package:customer_app/features/chat/data/chat_media_repository.dart';
import 'package:customer_app/features/chat/domain/chat_room_ids.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
import 'package:dio/dio.dart';
import 'package:customer_app/features/chat/presentation/states/chat_state.dart';
import 'package:customer_app/features/messenger/data/repositories/messenger_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_controller.g.dart';

/// Which backend chat channel a [ChatController] talks to. Rides use the
/// `jobs/{id}/chat` endpoints; food orders use `orders/{id}/chat`; messenger
/// orders use `messenger/customer/orders/{id}/chat`.
enum ChatKind { ride, food, messenger }

/// Identifies a chat room — its id plus which channel it belongs to. Used as
/// the [chatControllerProvider] family key.
typedef ChatRoom = ({String id, ChatKind kind});

@riverpod
class ChatController extends _$ChatController {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  @override
  ChatState build(ChatRoom room) {
    _initSocket();
    Future.microtask(fetchChatHistory);
    return const ChatState();
  }

  void _initSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.connect();
    _socketSubscription = socket.messages.listen((message) {
      _handleSocketMessage(message);
    });
    ref.onDispose(() {
      _socketSubscription?.cancel();
    });
  }

  void _handleSocketMessage(Map<String, dynamic> message) {
    final type = (message['type'] as String?)?.toLowerCase();
    if (type == null) return;

    if (type == 'chat_message') {
      // `{type, room_id: "job:{id}", data: {id, content, msg_type, media_url,
      // sender_type, created_at}}` — the room id carries the vertical prefix.
      final data = message['data'];
      final payload = data is Map
          ? Map<String, dynamic>.from(data)
          : Map<String, dynamic>.from(message);
      final roomId = (message['room_id'] ?? payload['room_id'])?.toString();
      if (roomId != null && bareChatRoomId(roomId) == room.id) {
        try {
          _addMessageFromSocket(ChatMessage.fromJson(payload));
        } catch (_) {
          // A frame we can't read: the next history fetch has it.
        }
      }
    } else {
      // Fallback/Legacy nested structure
      final data = message['data'] as Map<String, dynamic>?;
      if (data == null) return;

      if (type.contains('chat') || type.contains('message')) {
        // Ride rooms key on job_id; food and messenger both key on order_id.
        final isRide = room.kind == ChatKind.ride;
        final idKey = isRide ? 'job_id' : 'order_id';
        final idKeyCamel = isRide ? 'jobId' : 'orderId';
        final roomId =
            (data['room_id'] ??
                    data['roomId'] ??
                    data[idKey] ??
                    data[idKeyCamel] ??
                    message['room_id'] ??
                    message[idKey])
                ?.toString();
        if (roomId == room.id) {
          final newMessage = ChatMessage.fromJson(data);
          _addMessageFromSocket(newMessage);
        }
      }
    }
  }

  void _addMessageFromSocket(ChatMessage newMessage) {
    // Check if we already have this message by ID
    final exists = state.messages.any((m) => m.id == newMessage.id);
    if (exists) return;

    // Our own photo coming back: swap the temporary bubble for it, keeping
    // the photo in memory under the server id.
    if (newMessage.isImage &&
        (newMessage.senderRole == 'customer' || newMessage.senderId == 'me')) {
      final echoKey =
          newMessage.fileKey ?? chatFileKeyFromUrl(newMessage.mediaUrl);
      bool pendingWith(ChatMessage m, {bool byKey = true}) {
        if (!m.id.startsWith('opt-') || !m.isImage) return false;
        final up = state.imageUploads[m.id];
        if (up == null || up.status == ChatImageUploadStatus.failed) {
          return false;
        }
        return byKey ? up.fileKey != null && up.fileKey == echoKey : true;
      }

      var optIndex = state.messages.indexWhere((m) => pendingWith(m));
      if (optIndex == -1) {
        optIndex = state.messages.indexWhere(
          (m) => pendingWith(m, byKey: false) && m.text == newMessage.text,
        );
      }
      if (optIndex != -1) {
        final tempId = state.messages[optIndex].id;
        final updatedList = List<ChatMessage>.from(state.messages);
        updatedList[optIndex] = newMessage;
        final uploads = Map<String, ChatImageUpload>.from(state.imageUploads);
        final upload = uploads.remove(tempId);
        if (upload != null) {
          uploads[newMessage.id] = upload.copyWith(
            status: ChatImageUploadStatus.sent,
            progress: 1,
          );
        }
        state = state.copyWith(messages: updatedList, imageUploads: uploads);
        return;
      }
    }

    // Check if it matches an optimistic message by text
    if (!newMessage.isImage &&
        (newMessage.senderRole == 'customer' || newMessage.senderId == 'me')) {
      final optIndex = state.messages.indexWhere(
        (m) =>
            m.id.startsWith('opt-') && !m.isImage && m.text == newMessage.text,
      );
      if (optIndex != -1) {
        final updatedList = List<ChatMessage>.from(state.messages);
        updatedList[optIndex] = newMessage;
        state = state.copyWith(messages: updatedList);
        return;
      }
    }

    state = state.copyWith(messages: [...state.messages, newMessage]);
  }

  Future<List<dynamic>> _fetchChat({String? before}) {
    switch (room.kind) {
      case ChatKind.ride:
        return ref
            .read(apiRepositoryProvider)
            .getJobChat(room.id, limit: 50, before: before);
      case ChatKind.food:
        return ref
            .read(apiRepositoryProvider)
            .getOrderChat(room.id, limit: 50, before: before);
      case ChatKind.messenger:
        return ref
            .read(messengerRepositoryProvider)
            .getChat(room.id, limit: 50, before: before);
    }
  }

  Future<void> fetchChatHistory() async {
    state = state.copyWith(isLoading: true, error: null, hasReachedEnd: false);
    try {
      final list = await _fetchChat();
      final messages = list
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();
      // A reload (e.g. to re-sign expired photo links) keeps photos still
      // being sent from here, which the server doesn't have yet.
      final unsent = state.messages.where(
        (m) => m.id.startsWith('opt-') && state.imageUploads.containsKey(m.id),
      );
      state = state.copyWith(
        isLoading: false,
        messages: [...messages, ...unsent],
        hasReachedEnd: list.length < 50,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMoreMessages() async {
    if (state.isLoadingMore || state.hasReachedEnd || state.messages.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final oldestMessageId = state.messages.first.id;
      final list = await _fetchChat(before: oldestMessageId);
      if (list.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasReachedEnd: true);
        return;
      }

      final olderMessages = list
          .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
          .toList()
          .reversed
          .toList();

      state = state.copyWith(
        isLoadingMore: false,
        messages: [...olderMessages, ...state.messages],
        hasReachedEnd: list.length < 50,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final tempId =
        'opt-${DateTime.now().millisecondsSinceEpoch}-${text.hashCode}';
    final optimisticMsg = ChatMessage(
      id: tempId,
      roomId: room.id,
      senderId: 'me',
      senderRole: 'customer',
      msgType: 'text',
      text: text,
      sentAt: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, optimisticMsg]);

    try {
      switch (room.kind) {
        case ChatKind.ride:
          await ref
              .read(apiRepositoryProvider)
              .sendJobChatMessage(room.id, text: text, msgType: 'text');
        case ChatKind.food:
          await ref
              .read(apiRepositoryProvider)
              .sendOrderChatMessage(room.id, text: text, msgType: 'text');
        case ChatKind.messenger:
          await ref
              .read(messengerRepositoryProvider)
              .sendChatMessage(room.id, text: text, msgType: 'text');
      }
    } catch (e) {
      // Remove optimistic message and set error
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != tempId).toList(),
        error: e.toString(),
      );
    }
  }

  /// Sends a photo: shows it at once with a progress ring, then scales it
  /// down / strips EXIF, uploads it, confirms it and posts an `image`
  /// message with the optional [caption]. A failure leaves the bubble with a
  /// retry ([retryImage]).
  Future<void> sendImage(Uint8List bytes, {String caption = ''}) async {
    final tempId = 'opt-img-${DateTime.now().microsecondsSinceEpoch}';
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          id: tempId,
          roomId: room.id,
          senderId: 'me',
          senderRole: 'customer',
          msgType: 'image',
          text: caption.trim(),
          sentAt: DateTime.now(),
        ),
      ],
      imageUploads: {
        ...state.imageUploads,
        tempId: ChatImageUpload(bytes: bytes),
      },
    );
    await _deliverImage(tempId);
  }

  /// Sends a failed photo again: only the message when the upload already
  /// went through, otherwise the whole upload (its link may have expired).
  Future<void> retryImage(String tempId) async {
    final upload = state.imageUploads[tempId];
    if (upload == null || upload.inFlight) return;
    _updateUpload(
      tempId,
      (u) => u.copyWith(
        status: u.fileKey == null
            ? ChatImageUploadStatus.uploading
            : ChatImageUploadStatus.sending,
        clearError: true,
      ),
    );
    await _deliverImage(tempId);
  }

  /// Drops a photo that failed to send.
  void discardImage(String tempId) {
    final uploads = Map<String, ChatImageUpload>.from(state.imageUploads)
      ..remove(tempId);
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != tempId).toList(),
      imageUploads: uploads,
    );
  }

  void _updateUpload(
    String id,
    ChatImageUpload Function(ChatImageUpload) update,
  ) {
    final current = state.imageUploads[id];
    if (current == null) return;
    state = state.copyWith(
      imageUploads: {...state.imageUploads, id: update(current)},
    );
  }

  Future<void> _deliverImage(String tempId) async {
    try {
      var upload = state.imageUploads[tempId];
      if (upload == null) return;
      var fileKey = upload.fileKey;
      if (fileKey == null) {
        if (!upload.prepared) {
          final Uint8List prepared;
          try {
            prepared = await prepareChatImageInBackground(upload.bytes);
          } on FormatException catch (e) {
            throw ChatImageException(ChatImageError.invalid, e);
          }
          _updateUpload(
            tempId,
            (u) => u.copyWith(bytes: prepared, prepared: true, progress: 0.1),
          );
          upload = state.imageUploads[tempId]!;
        }
        fileKey = await ref
            .read(chatMediaRepositoryProvider)
            .uploadChatImage(
              upload.bytes,
              roomId: room.id,
              onProgress: (p) => _updateUpload(
                tempId,
                (u) => u.copyWith(progress: 0.1 + p * 0.8),
              ),
            );
        _updateUpload(
          tempId,
          (u) => u.copyWith(
            fileKey: fileKey,
            status: ChatImageUploadStatus.sending,
            progress: 0.9,
          ),
        );
      }

      final caption = state.messages
          .firstWhere(
            (m) => m.id == tempId,
            orElse: () => ChatMessage(
              id: tempId,
              senderId: 'me',
              senderRole: 'customer',
              msgType: 'image',
              text: '',
              sentAt: DateTime.now(),
            ),
          )
          .text;
      try {
        await _postMessage(text: caption, msgType: 'image', fileKey: fileKey);
      } on DioException catch (e) {
        throw ChatImageException.fromDio(e);
      }
      // Sent; the WebSocket echo (deduped on its id) replaces the bubble.
      _updateUpload(
        tempId,
        (u) => u.copyWith(status: ChatImageUploadStatus.sent, progress: 1),
      );
    } on ChatImageException catch (e) {
      _updateUpload(
        tempId,
        (u) => u.copyWith(status: ChatImageUploadStatus.failed, error: e.error),
      );
    } catch (_) {
      _updateUpload(
        tempId,
        (u) => u.copyWith(
          status: ChatImageUploadStatus.failed,
          error: ChatImageError.failed,
        ),
      );
    }
  }

  Future<void> _postMessage({
    required String text,
    required String msgType,
    String? fileKey,
  }) async {
    switch (room.kind) {
      case ChatKind.ride:
        await ref
            .read(apiRepositoryProvider)
            .sendJobChatMessage(
              room.id,
              text: text,
              msgType: msgType,
              fileKey: fileKey,
            );
      case ChatKind.food:
        await ref
            .read(apiRepositoryProvider)
            .sendOrderChatMessage(
              room.id,
              text: text,
              msgType: msgType,
              fileKey: fileKey,
            );
      case ChatKind.messenger:
        await ref
            .read(messengerRepositoryProvider)
            .sendChatMessage(
              room.id,
              text: text,
              msgType: msgType,
              fileKey: fileKey,
            );
    }
  }
}
