import 'package:app_settings/app_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/chat/data/chat_media_repository.dart';
import 'package:customer_app/features/chat/domain/chat_room_ids.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
import 'package:customer_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:customer_app/features/chat/presentation/states/chat_state.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// The "แนบรูป" button left of the chat input: take a photo or pick one,
/// preview it with an optional caption, then hand it to [onSend].
class ChatAttachButton extends StatelessWidget {
  const ChatAttachButton({super.key, required this.onSend, this.color});

  final void Function(Uint8List bytes, String caption) onSend;
  final Color? color;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    XFile? file;
    try {
      // Scaled natively first (HEIC → JPEG, fast); prepareChatImage then
      // strips EXIF and enforces the size before upload.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
        requestFullMetadata: false,
      );
    } on PlatformException {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.chatPhotoPermissionDenied),
          action: SnackBarAction(
            label: l10n.chatOpenSettings,
            onPressed: AppSettings.openAppSettings,
          ),
        ),
      );
      return;
    }
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;
    final caption = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChatImagePreviewSheet(bytes: bytes),
    );
    if (caption != null) onSend(bytes, caption);
  }

  void _chooseSource(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                key: const Key('chatTakePhoto'),
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(l10n.chatTakePhoto),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _pick(context, ImageSource.camera);
                },
              ),
              ListTile(
                key: const Key('chatPickPhoto'),
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.chatChooseFromGallery),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _pick(context, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('chatAttachImage'),
      tooltip: AppLocalizations.of(context)!.chatAttachImage,
      onPressed: () => _chooseSource(context),
      icon: Icon(
        Icons.add_photo_alternate_outlined,
        color: color ?? AppColors.aberGreen,
        size: 26,
      ),
    );
  }
}

/// The picked photo with a caption field; pops the caption ('' for none) on
/// ส่ง, null on close.
class _ChatImagePreviewSheet extends StatefulWidget {
  const _ChatImagePreviewSheet({required this.bytes});

  final Uint8List bytes;

  @override
  State<_ChatImagePreviewSheet> createState() => _ChatImagePreviewSheetState();
}

class _ChatImagePreviewSheetState extends State<_ChatImagePreviewSheet> {
  final _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(widget.bytes, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      key: const Key('chatImageCaption'),
                      controller: _caption,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: l10n.chatImageCaptionHint,
                        hintStyle: AppTypography.caption4.copyWith(
                          color: AppColors.semanticGrayNeutralFgLowOnWhite,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('chatImageSend'),
                  tooltip: l10n.chatSendImage,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.aberGreen,
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(_caption.text.trim()),
                  icon: const Icon(Icons.send, color: AppColors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A photo message: the image (tap for full screen), its caption, and for a
/// photo sent from here the progress ring or the failure with ส่งใหม่.
class ChatImageBubble extends StatelessWidget {
  const ChatImageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.myColor = AppColors.aberGreen,
    this.upload,
    this.onRetry,
    this.onDiscard,
    this.onReload,
  });

  final ChatMessage message;
  final bool isMe;

  /// Bubble colour for the customer's own messages (each chat has its own).
  final Color myColor;
  final ChatImageUpload? upload;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  /// Re-fetches the chat for fresh photo links once both ways of loading
  /// this one failed.
  final VoidCallback? onReload;

  static const double _width = 220;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final up = upload;
    final failed = up?.status == ChatImageUploadStatus.failed;
    final caption = message.text.trim();
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isMe ? 18 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 18),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            key: Key('chatImage-${message.id}'),
            width: _width,
            decoration: BoxDecoration(
              color: isMe ? myColor : AppColors.grey100,
              borderRadius: radius,
            ),
            padding: const EdgeInsets.all(3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: radius.subtract(
                    const BorderRadius.all(Radius.circular(3)),
                  ),
                  child: SizedBox(
                    width: _width,
                    height: _width,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _ChatPhoto(
                          message: message,
                          bytes: up?.bytes,
                          onReload: onReload,
                        ),
                        if (up != null && up.inFlight)
                          ColoredBox(
                            color: Colors.black26,
                            child: Center(
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  key: const Key('chatImageProgress'),
                                  value: up.progress <= 0 ? null : up.progress,
                                  strokeWidth: 3,
                                  color: AppColors.white,
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                            ),
                          ),
                        if (failed)
                          ColoredBox(
                            color: Colors.black38,
                            child: Center(
                              child: up!.error == ChatImageError.blocked
                                  ? const Icon(
                                      Icons.block,
                                      color: AppColors.white,
                                      size: 40,
                                    )
                                  : IconButton.filled(
                                      key: const Key('chatImageRetry'),
                                      tooltip: l10n.chatImageRetry,
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.white,
                                      ),
                                      onPressed: onRetry,
                                      icon: const Icon(
                                        Icons.refresh,
                                        color: AppColors.aberGreen,
                                      ),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Text(
                      caption,
                      style: AppTypography.caption4.copyWith(
                        color: isMe
                            ? AppColors.white
                            : AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      switch (up!.error) {
                        ChatImageError.blocked => l10n.chatImageBlocked,
                        ChatImageError.invalid => l10n.chatImageInvalid,
                        _ => l10n.chatImageFailed,
                      },
                      key: const Key('chatImageError'),
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  if (onDiscard != null)
                    TextButton(
                      key: const Key('chatImageDiscard'),
                      onPressed: onDiscard,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor:
                            AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                      child: Text(l10n.chatImageDiscard),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// [ChatImageBubble] for a message of [room], wired to its controller: the
/// upload state, ส่งใหม่ / ลบ, and a chat reload for expired photo links.
class ChatRoomImageBubble extends ConsumerWidget {
  const ChatRoomImageBubble({
    super.key,
    required this.room,
    required this.message,
    required this.isMe,
    this.myColor = AppColors.aberGreen,
  });

  final ChatRoom room;
  final ChatMessage message;
  final bool isMe;
  final Color myColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upload = ref.watch(
      chatControllerProvider(room).select((s) => s.imageUploads[message.id]),
    );
    final notifier = ref.read(chatControllerProvider(room).notifier);
    return ChatImageBubble(
      message: message,
      isMe: isMe,
      myColor: myColor,
      upload: upload,
      onRetry: () => notifier.retryImage(message.id),
      onDiscard: () => notifier.discardImage(message.id),
      onReload: notifier.fetchChatHistory,
    );
  }
}

/// The photo itself: from memory when this device sent it, otherwise
/// `media_url`, then — once that presigned link has expired — the
/// authenticated `/api/media/files/{file_key}`, both cached on disk under the
/// file key; when both fail, a tap re-fetches the chat ([onReload]).
class _ChatPhoto extends ConsumerStatefulWidget {
  const _ChatPhoto({required this.message, this.bytes, this.onReload});

  final ChatMessage message;
  final Uint8List? bytes;
  final VoidCallback? onReload;

  @override
  ConsumerState<_ChatPhoto> createState() => _ChatPhotoState();
}

class _ChatPhotoState extends ConsumerState<_ChatPhoto> {
  // 0: media_url, 1: the authenticated proxy, 2: both failed.
  int _attempt = 0;

  String? get _fileKey =>
      widget.message.fileKey ?? chatFileKeyFromUrl(widget.message.mediaUrl);

  @override
  void didUpdateWidget(covariant _ChatPhoto old) {
    super.didUpdateWidget(old);
    // A reload brought a freshly signed link: try it again.
    if (old.message.mediaUrl != widget.message.mediaUrl) _attempt = 0;
  }

  ImageProvider? _provider() {
    final bytes = widget.bytes;
    if (bytes != null) return MemoryImage(bytes);
    final key = _fileKey;
    final url = widget.message.mediaUrl;
    final cacheKey = 'chat:${key ?? widget.message.id}';
    if (_attempt == 0 && url != null && url.isNotEmpty) {
      return CachedNetworkImageProvider(url, cacheKey: cacheKey);
    }
    if (_attempt <= 1 && key != null) {
      final token = ref.read(tokenStorageProvider).getAccessToken();
      return CachedNetworkImageProvider(
        '${ApiService.baseUrl}/api/media/files/$key',
        cacheKey: cacheKey,
        headers: {'Authorization': ?(token == null ? null : 'Bearer $token')},
      );
    }
    return null;
  }

  void _failed() {
    if (!mounted) return;
    setState(() => _attempt = (_attempt == 0 && _fileKey != null) ? 1 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider();
    if (provider == null) {
      return _LoadFailed(
        onTap: () {
          setState(() => _attempt = 0);
          widget.onReload?.call();
        },
      );
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => ChatImageViewer(image: provider),
        ),
      ),
      child: Image(
        key: ValueKey('${widget.message.id}-$_attempt'),
        image: provider,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : ColoredBox(
                color: AppColors.grey100,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
        errorBuilder: (context, error, stack) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _failed());
          return ColoredBox(color: AppColors.grey100);
        },
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('chatImageReload'),
      onTap: onTap,
      child: ColoredBox(
        color: AppColors.grey100,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: AppColors.semanticGrayNeutralFgLowOnWhite,
                size: 32,
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.chatImageLoadFailed,
                textAlign: TextAlign.center,
                style: AppTypography.caption5.copyWith(
                  color: AppColors.semanticGrayNeutralFgLowOnWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen photo: pinch to zoom, drag to pan, close to go back.
class ChatImageViewer extends StatelessWidget {
  const ChatImageViewer({super.key, required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('chatImageViewer'),
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: Image(image: image, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
