import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/data/datasources/promo_remote_data_source.dart';
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
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (promo) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context, promo),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(promo),
                    const SizedBox(height: 24),
                    _buildCodeSection(context, promo),
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

  Widget _buildAppBar(BuildContext context, Map<String, dynamic> promo) {
    final bannerUrl = promo['banner_url'];
    final barColor = Color(promo['color'] as int? ?? 0xFF00236F);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: barColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: bannerUrl != null
            ? Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: barColor),
              )
            : Container(color: barColor),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> promo) {
    final barColor = Color(promo['color'] as int? ?? 0xFF00236F);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: barColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            promo['tag'] ?? '',
            style: AppTypography.caption4.copyWith(
              color: barColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(promo['title'] ?? '', style: AppTypography.heading4),
        const SizedBox(height: 8),
        Text(
          promo['description'] ?? '',
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeSection(BuildContext context, Map<String, dynamic> promo) {
    final code = promo['code'] ?? '';
    final barColor = Color(promo['color'] as int? ?? 0xFF00236F);

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

  Widget _buildTermsSection(Map<String, dynamic> promo) {
    final terms = promo['terms'] as List<dynamic>? ?? [];
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
