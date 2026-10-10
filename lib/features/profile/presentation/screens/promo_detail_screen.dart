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
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PromoDetailHeader(promo: promo),
                    const SizedBox(height: 20),
                    _buildDescription(promo),
                    _buildCodeSection(context, promo),
                    _buildExpiry(promo),
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

  // Slim bar — the promo hero now lives in the body, so the app bar is just a
  // back button over the page background (no empty coloured block).
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  // The promo title + tag moved into [_PromoDetailHeader]; the body keeps only
  // the longer description, hidden entirely when the backend sends none.
  Widget _buildDescription(Map<String, dynamic> promo) {
    final String desc = (promo['description'] ?? '').toString().trim();
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
  Widget _buildExpiry(Map<String, dynamic> promo) {
    final raw = (promo['expires_at'] ?? '').toString();
    if (raw.isEmpty) return const SizedBox.shrink();
    final DateTime? parsed = DateTime.tryParse(raw);
    if (parsed == null) return const SizedBox.shrink();
    final bkk = parsed.toUtc().add(const Duration(hours: 7));
    String two(int n) => n.toString().padLeft(2, '0');
    final text =
        'ใช้ได้ถึง ${two(bkk.day)}/${two(bkk.month)}/${bkk.year} ${two(bkk.hour)}:${two(bkk.minute)} น.';
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

/// Coupon-ticket hero for the promo detail page. Colour and glyph follow the
/// promo type (fixed → red "฿", percentage → orange "%", free shipping →
/// green truck), the headline reuses [promoHeadlineOf], and the bottom edge
/// has a dashed perforation with two notches so it reads as a tear-off ticket.
class _PromoDetailHeader extends StatelessWidget {
  final Map<String, dynamic> promo;
  const _PromoDetailHeader({required this.promo});

  @override
  Widget build(BuildContext context) {
    final Color base = promoColorOf(promo);
    final Color dark = Color.lerp(base, Colors.black, 0.28)!;
    final String title = (promo['title'] ?? '').toString().trim();
    final String headline = promoHeadlineOf(promo, fallback: title);
    final String tag = (promo['tag'] ?? '').toString().trim();
    final String type = (promo['promo_type'] ?? promo['discount_type'] ?? '')
        .toString()
        .toLowerCase();
    final String banner = (promo['banner_url'] ?? '').toString().trim();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            // Brand gradient, with the admin banner faded over it when present.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [base, dark],
                  ),
                ),
              ),
            ),
            if (banner.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.22,
                  child: Image.network(
                    banner,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            // Oversized type glyph watermark.
            Positioned(right: -16, top: -26, child: _HeaderGlyph(type: type)),
            // Tag · headline · title, anchored bottom-left.
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (tag.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.caption5.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    headline,
                    style: AppTypography.heading3.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 36,
                      height: 1.05,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTypography.label1.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Dashed perforation along the bottom edge.
            Positioned(
              left: 14,
              right: 14,
              bottom: 13,
              child: CustomPaint(
                size: const Size(double.infinity, 1.5),
                painter: _DashedLinePainter(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Half-circle notches biting into the two edges.
            const Positioned(left: -9, bottom: 5, child: _Notch()),
            const Positioned(right: -9, bottom: 5, child: _Notch()),
          ],
        ),
      ),
    );
  }
}

/// The faint oversized glyph behind the headline, chosen by promo type.
class _HeaderGlyph extends StatelessWidget {
  final String type;
  const _HeaderGlyph({required this.type});

  @override
  Widget build(BuildContext context) {
    final Color c = Colors.white.withValues(alpha: 0.16);
    if (type == 'free_shipping') {
      return Icon(Icons.local_shipping_rounded, size: 150, color: c);
    }
    return Text(
      type == 'percentage' ? '%' : '฿',
      style: TextStyle(
        fontSize: 160,
        fontWeight: FontWeight.w900,
        height: 1,
        color: c,
      ),
    );
  }
}

/// A background-coloured circle that reads as a punched-out ticket notch.
class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: AppColors.background,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dash = 5, gap = 4;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}
