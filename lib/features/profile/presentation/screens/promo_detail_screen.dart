import 'package:customer_app/l10n/app_localizations.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/core/utils/promo_style.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/data/datasources/promo_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final promoDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  id,
) async {
  return ref.watch(promoRemoteDataSourceProvider).getDetail(id);
});

class PromoDetailScreen extends ConsumerWidget {
  final String promoId;

  const PromoDetailScreen({super.key, required this.promoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoAsync = ref.watch(promoDetailProvider(promoId));

    return promoAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: MassLoadingM(size: 72)),
      ),
      error: (e, s) {
        final int? status =
            e is DioException ? e.response?.statusCode : null;
        // 404 = promo closed/removed, 400 = bad id → a message + "back";
        // anything else (5xx / network) → message + "retry", never a stuck spinner.
        final bool gone = status == 404 || status == 400;
        final String msg = status == 404
            ? 'ไม่พบโปรโมชันนี้'
            : status == 400
                ? 'รหัสโปรโมชันไม่ถูกต้อง'
                : friendlyError(e);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: AppTypography.body2,
                  ),
                  const SizedBox(height: 16),
                  if (gone)
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('กลับ'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(promoDetailProvider(promoId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        'ลองใหม่',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      data: (promo) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context, promo),
            SliverToBoxAdapter(child: _buildFloatingHeader(context, promo)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDescription(promo),
                    _buildCodeSection(context, promo),
                    _buildExpiry(context, promo),
                    const SizedBox(height: 32),
                    _buildTermsSection(promo),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Short pinned bar in the promo's color; the floating card below carries
  /// the promo's headline.
  Widget _buildAppBar(BuildContext context, Map<String, dynamic> promo) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: promoColorOf(promo),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// "Floating card" header: a short color band continuing the app bar, with a
  /// white card overlapping it that sums up the promo — service scope, tag,
  /// expiry date, the discount headline and the title.
  Widget _buildFloatingHeader(BuildContext context, Map<String, dynamic> promo) {
    final barColor = promoColorOf(promo);
    final bannerUrl = (promo['banner_url'] ?? '').toString();
    final scope = promoScopeOf(promo);
    final tag = (promo['tag'] ?? '').toString().trim();
    final title = (promo['title'] ?? promo['name'] ?? '').toString();
    final expiry = _expiryDate(promo);

    return Stack(
      children: [
        SizedBox(
          height: 72,
          width: double.infinity,
          child: bannerUrl.isNotEmpty
              ? Image.network(
                  bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      ColoredBox(color: barColor),
                )
              : ColoredBox(color: barColor),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _pill(scope.label, scope.foreground, scope.background),
                    if (tag.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _pill(tag, barColor, barColor.withValues(alpha: 0.1)),
                    ],
                    const Spacer(),
                    if (expiry != null)
                      Text(
                        AppLocalizations.of(context)!.promoValidUntilShort(AppDates.of(context).date(expiry)),
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  promoHeadlineOf(promo, fallback: title),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: barColor,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AppTypography.label1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.caption5.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// The promo's description, hidden when the backend omits it.
  Widget _buildDescription(Map<String, dynamic> promo) {
    final desc = (promo['description'] ?? '').toString().trim();
    if (desc.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        desc,
        style: AppTypography.caption4.copyWith(
          color: AppColors.semanticGrayNeutralFgHigh,
        ),
      ),
    );
  }

  /// `expires_at` in Bangkok time, or null.
  DateTime? _expiryDate(Map<String, dynamic> promo) {
    final parsed = DateTime.tryParse((promo['expires_at'] ?? '').toString());
    return parsed == null ? null : AppDates.bangkok(parsed);
  }

  Widget _buildCodeSection(BuildContext context, Map<String, dynamic> promo) {
    final code = promo['code'] ?? '';
    final barColor = promoColorOf(promo);

    return Container(
      decoration: BoxDecoration(
        color: barColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: barColor.withValues(alpha: 0), width: 0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative circles for "ticket" look
            Positioned(
              left: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รหัสโปรโมชัน',
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          code,
                          style: AppTypography.heading3.copyWith(
                            letterSpacing: 1.5,
                            color: barColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 40,
                    width: 1.5,
                    color: barColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'คัดลอกรหัส $code แล้ว!',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: barColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: barColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: AppTypography.label1,
                    ),
                    child: Text(
                      'คัดลอก',
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Expiry, converted from the ISO-8601 UTC `expires_at` to Thai time
  /// (Asia/Bangkok, UTC+7) regardless of the device timezone.
  Widget _buildExpiry(BuildContext context, Map<String, dynamic> promo) {
    final bkk = _expiryDate(promo);
    if (bkk == null) return const SizedBox.shrink();
    final dates = AppDates.of(context);
    final text = AppLocalizations.of(context)!
        .promoValidUntilFull(dates.date(bkk), dates.time(bkk));
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.caption4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(Map<String, dynamic> promo) {
    final terms = promo['terms'] as List<dynamic>? ?? [];
    // Hide the whole section when the backend sends no terms, so it doesn't
    // leave a dangling header.
    if (terms.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ข้อกำหนดและเงื่อนไข', style: AppTypography.heading4),
        const SizedBox(height: 16),
        ...terms.map(
          (term) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: AppColors.textDisabled,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    term.toString(),
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
