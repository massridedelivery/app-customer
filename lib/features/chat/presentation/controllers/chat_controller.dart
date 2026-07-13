import 'dart:async';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
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
      final roomId = message['room_id']?.toString();
      if (roomId == room.id) {
        final newMessage = ChatMessage.fromJson(message);
        _addMessageFromSocket(newMessage);
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

    // Check if it matches an optimistic message by text
    if (newMessage.senderRole == 'customer' || newMessage.senderId == 'me') {
      final optIndex = state.messages.indexWhere(
        (m) => m.id.startsWith('opt-') && m.text == newMessage.text,
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
      state = state.copyWith(
        isLoading: false,
        messages: messages,
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
}
