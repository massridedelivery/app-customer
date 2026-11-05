import 'package:app_settings/app_settings.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/services/idempotency.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/features/chat/data/chat_image_processor.dart';
import 'package:customer_app/features/support/data/support_repository.dart';
import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:customer_app/features/support/presentation/controllers/support_tickets_controller.dart';
import 'package:customer_app/features/support/presentation/support_chat_launcher.dart';
import 'package:customer_app/features/support/presentation/support_l10n.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Shortest description the form accepts.
const int kSupportMinDetail = 10;

/// Longest description the form accepts.
const int kSupportMaxDetail = 1000;

/// Most photos one report carries.
const int kSupportMaxPhotos = 5;

/// "แจ้งปัญหา": pick a topic, describe it, optionally attach photos, send.
///
/// Opened from an order (`service` + `refId`, shown as "เรียกรถ · #ABC123") or
/// on its own from Profile. Sending opens the new report.
class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({
    super.key,
    this.service,
    this.refId,
    this.orderNo,
    this.source = SupportSource.profile,
    this.initialCategory,
  });

  final SupportService? service;
  final String? refId;

  /// Short order number to show; defaults to the start of [refId].
  final String? orderNo;
  final SupportSource source;
  final SupportCategory? initialCategory;

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _Photo {
  _Photo(this.bytes);

  final Uint8List bytes;

  /// Set once uploaded, so a retry doesn't upload it again.
  String? fileKey;
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _detail = TextEditingController();
  final _photos = <_Photo>[];
  SupportCategory? _category;
  bool _sending = false;
  bool _triedSend = false;

  /// One key per report: a retry after a lost response returns the same one.
  /// A definite refusal (4xx) gets a new one, since the customer changes the
  /// report before sending again.
  String _idempotencyKey = generateIdempotencyKey();

  AppLocalizations get _l10n => AppLocalizations.of(context)!;

  List<SupportCategory> get _topics =>
      SupportCategory.forService(widget.service);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory;
    if (initial != null && _topics.contains(initial)) _category = initial;
    _detail.addListener(() {
      if (_triedSend) setState(() {});
    });
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  String? get _detailError {
    if (!_triedSend) return null;
    return _detail.text.trim().length < kSupportMinDetail
        ? _l10n.supportDetailTooShort('$kSupportMinDetail')
        : null;
  }

  Future<void> _addPhoto(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = _l10n;
    XFile? file;
    try {
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
    if (file == null) return;
    try {
      // Strips EXIF (phone photos carry GPS) and fits the 2MB cap.
      final jpeg = await prepareChatImageInBackground(await file.readAsBytes());
      if (!mounted) return;
      setState(() => _photos.add(_Photo(jpeg)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportPhotoFailed)));
    }
  }

  void _choosePhotoSource() {
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
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(_l10n.chatTakePhoto),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _addPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(_l10n.chatChooseFromGallery),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _addPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _triedSend = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = _l10n;
    final category = _category;
    if (category == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportPickTopic)));
      return;
    }
    if (_detailError != null) return;

    setState(() => _sending = true);
    final repo = ref.read(supportRepositoryProvider);
    try {
      for (final p in _photos) {
        p.fileKey ??= await repo.uploadPhoto(p.bytes);
      }
      final ticket = await repo.create(
        NewSupportTicket(
          category: category,
          description: _detail.text.trim(),
          source: widget.source,
          service: widget.service,
          refId: widget.refId,
          attachments: [for (final p in _photos) p.fileKey!],
        ),
        idempotencyKey: _idempotencyKey,
      );
      ref.invalidate(supportTicketsProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportSubmitted)));
      context.pushReplacement('/support/tickets/${ticket.id}');
    } on ApiError catch (e) {
      if (!mounted) return;
      // One open report per order and topic: open the one already filed.
      final existing = e.extra['ticket_id']?.toString();
      if (e.code == 'TICKET_ALREADY_OPEN' &&
          existing != null &&
          existing.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.supportAlreadyOpen)),
        );
        context.pushReplacement('/support/tickets/$existing');
        return;
      }
      handleSupportDisabled(ref, e);
      final status = e.statusCode ?? 0;
      if (status >= 400 && status < 500) {
        _idempotencyKey = generateIdempotencyKey();
      }
      // A photo the backend won't take: upload them all again next time.
      if (e.code == 'TICKET_ATTACHMENT_INVALID') {
        for (final p in _photos) {
          p.fileKey = null;
        }
      }
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final service = widget.service;
    final ref0 = widget.refId;
    final orderNo = widget.orderNo?.isNotEmpty == true
        ? widget.orderNo!
        : (ref0 == null
              ? null
              : (ref0.length > 8 ? ref0.substring(0, 8) : ref0).toUpperCase());

    return Scaffold(
      backgroundColor: AppColors.foundationGrayscale100,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(l10n.supportReportTitle, style: AppTypography.heading4),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (service != null && orderNo != null) ...[
              _Card(
                child: Row(
                  children: [
                    Icon(service.icon, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.supportOrderLabel(service.label(l10n), orderNo),
                        key: const Key('supportOrderLabel'),
                        style: AppTypography.heading6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(l10n.supportTopicLabel, style: AppTypography.heading6),
            const SizedBox(height: 8),
            _Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final c in _topics)
                    ListTile(
                      key: Key('supportTopic_${c.api}'),
                      selected: c == _category,
                      onTap: _sending
                          ? null
                          : () => setState(() => _category = c),
                      leading: Icon(
                        c.icon,
                        color: c == SupportCategory.safety
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                      title: Text(c.label(l10n), style: AppTypography.body3),
                      trailing: Icon(
                        c == _category
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: c == _category
                            ? AppColors.primary
                            : AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                    ),
                ],
              ),
            ),
            if (_category == SupportCategory.safety) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('supportSafetyNote'),
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                decoration: BoxDecoration(
                  color: AppColors.semanticSupportRedBgLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.semanticSupportRedBorderOnGray,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sos_rounded, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.supportSafetyNote,
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.semanticSupportRedFgOnLow,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/sos'),
                      child: Text(
                        l10n.supportOpenSos,
                        style: AppTypography.label2.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(l10n.supportDetailLabel, style: AppTypography.heading6),
            const SizedBox(height: 8),
            TextField(
              key: const Key('supportDetail'),
              controller: _detail,
              enabled: !_sending,
              minLines: 4,
              maxLines: 8,
              maxLength: kSupportMaxDetail,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: l10n.supportDetailHint,
                hintStyle: AppTypography.body3.copyWith(
                  color: AppColors.semanticGrayNeutralFgLowOnWhite,
                ),
                errorText: _detailError,
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.semanticSupportGrayBorderOnWhite,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.semanticSupportGrayBorderOnWhite,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.supportPhotosLabel('$kSupportMaxPhotos'),
              style: AppTypography.heading6,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, p) in _photos.indexed)
                  _Thumb(
                    bytes: p.bytes,
                    onRemove: _sending
                        ? null
                        : () => setState(() => _photos.removeAt(i)),
                  ),
                if (_photos.length < kSupportMaxPhotos)
                  InkWell(
                    key: const Key('supportAddPhoto'),
                    onTap: _sending ? null : _choosePhotoSource,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.semanticSupportGrayBorderOnGray,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              key: const Key('supportSend'),
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      l10n.supportSubmit,
                      style: AppTypography.heading6.copyWith(
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.bytes, this.onRemove});

  final Uint8List bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 76,
    height: 76,
    child: Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    ),
  );
}
