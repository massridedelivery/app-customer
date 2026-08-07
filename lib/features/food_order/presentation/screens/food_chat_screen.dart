import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/food_order/presentation/controllers/live_food_tracking_controller.dart';
import 'package:customer_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FoodChatScreen extends ConsumerStatefulWidget {
  final String orderId;

  const FoodChatScreen({super.key, required this.orderId});

  @override
  ConsumerState<FoodChatScreen> createState() => _FoodChatScreenState();
}

class _FoodChatScreenState extends ConsumerState<FoodChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after frame rendering
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToBottom(animated: false),
    );
    _scrollController.addListener(() {
      if (_scrollController.position.pixels <= 100) {
        ref
            .read(chatControllerProvider((id: widget.orderId, kind: ChatKind.food)).notifier)
            .fetchMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (animated) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref
        .read(chatControllerProvider((id: widget.orderId, kind: ChatKind.food)).notifier)
        .sendMessage(text);
    _controller.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider((id: widget.orderId, kind: ChatKind.food)));
    // Only the two fields the header needs — a whole-state watch rebuilt the
    // entire chat on every food-tracking location update.
    final (trackOrderId, trackDriverName) = ref.watch(
      liveFoodTrackingControllerProvider.select(
        (s) => (s.orderId, s.driverName),
      ),
    );

    final riderName = (trackOrderId == widget.orderId)
        ? (trackDriverName ?? 'คนขับของคุณ')
        : 'คนขับของคุณ';

    // Automatically scroll to bottom when new messages arrive
    ref.listen(chatControllerProvider((id: widget.orderId, kind: ChatKind.food)), (previous, next) {
      if (previous != null && previous.messages.length < next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.foundationGreen500,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            // Rider avatar — no avatar in the API; neutral icon.
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.sports_motorsports,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    riderName,
                    style: AppTypography.label2.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    'คนขับของคุณ',
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // Loading Indicator or Error Alert
          if (chatState.isLoading && chatState.messages.isEmpty)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.foundationGreen500,
                ),
              ),
            )
          else if (chatState.error != null && chatState.messages.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'โหลดข้อความไม่สำเร็จ',
                      style: AppTypography.label2.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.foundationGreen500,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () {
                        ref
                            .read(
                              chatControllerProvider(
                                (id: widget.orderId, kind: ChatKind.food),
                              ).notifier,
                            )
                            .fetchChatHistory();
                      },
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount:
                    chatState.messages.length +
                    (chatState.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (chatState.isLoadingMore && index == 0) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  final actualIndex = chatState.isLoadingMore
                      ? index - 1
                      : index;
                  final message = chatState.messages[actualIndex];
                  final isMe =
                      message.senderId == 'me' ||
                      message.senderRole == 'customer';
                  return _buildBubble(message.text, isMe: isMe);
                },
              ),
            ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
                        hintStyle: AppTypography.caption4.copyWith(
                          color: AppColors.semanticGrayNeutralFgLowOnWhite,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.foundationGreen500,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, {required bool isMe}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.foundationGreen100,
              child: const Icon(
                Icons.sports_motorsports,
                color: AppColors.foundationGreen600,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.foundationGreen500 : AppColors.grey100,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              text,
              style: AppTypography.body1.copyWith(
                color: isMe
                    ? AppColors.white
                    : AppColors.semanticGrayNeutralFgHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
