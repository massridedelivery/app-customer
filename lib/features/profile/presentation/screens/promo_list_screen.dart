import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/data/datasources/promo_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final promoListProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(promoRemoteDataSourceProvider).getList();
});

class PromoListScreen extends ConsumerWidget {
  const PromoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promosAsync = ref.watch(promoListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('โปรโมชั่นของฉัน', style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: promosAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังโหลดโปรโมชัน...'),
            ],
          ),
        ),
        error: (e, s) {
          debugPrint('PromoList Load Error: $e');
          debugPrint('Stacktrace: $s');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text('โหลดข้อมูลไม่สำเร็จ: $e', style: AppTypography.body2),
                TextButton(
                  onPressed: () => ref.invalidate(promoListProvider),
                  child: const Text('ลองใหม่'),
                ),
              ],
            ),
          );
        },
        data: (promos) {
          debugPrint('PromoList Rendering: ${promos.length} items found');
          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่พบโปรโมชันในขณะนี้',
                    style: AppTypography.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(promoListProvider.future),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: promos.length,
              separatorBuilder: (c, i) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                try {
                  final rawPromo = promos[index];
                  final Map<String, dynamic> promoMap =
                      rawPromo is Map<String, dynamic>
                      ? rawPromo
                      : Map<String, dynamic>.from(rawPromo as Map);
                  return _PromoCard(promo: promoMap);
                } catch (e, stack) {
                  debugPrint('Card Error at index $index: $e');
                  debugPrint('Stack: $stack');
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ข้อผิดพลาดในการแสดงผล: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Map<String, dynamic> promo;

  const _PromoCard({required this.promo});

  @override
  Widget build(BuildContext context) {
    final barColor = Color(promo['color'] as int? ?? 0xFF26A69A);
    final promoId = promo['id']?.toString() ?? '';
    final expiresAt = promo['expires_at'] as String? ?? '';
    final expireDate = expiresAt.isNotEmpty ? expiresAt.substring(0, 10) : '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (promoId.isNotEmpty) {
          context.push('/promos/$promoId');
        }
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Section (Ticket style)
              _buildLeftTicketSection(
                barColor,
                promo['tag']?.toString() ?? 'ส่งฟรี*',
                promo['tag']?.toString() ?? '',
              ),

              // Middle Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promo['title']?.toString() ?? '',
                        style: AppTypography.heading4.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ขั้นต่ำ ฿${promo['min_order'] ?? 0}',
                        style: AppTypography.caption5.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.orange.shade800,
                            width: 0.8,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          promo['sub_tag']?.toString() ??
                              'ร้านโค้ดคุ้มเท่านั้น',
                          style: AppTypography.caption5.copyWith(
                            color: Colors.orange.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'ใช้ได้ถึง $expireDate',
                              style: AppTypography.caption5.copyWith(
                                color: AppColors.textDisabled,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'เงื่อนไข',
                            style: AppTypography.caption5.copyWith(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // // Right Button Section
              // Padding(
              //   padding: const EdgeInsets.only(right: 12),
              //   child: Center(
              //     child: SizedBox(
              //       height: 32,
              //       child: ElevatedButton(
              //         onPressed: () {
              //           if (isCollected) {
              //             // Navigate to service
              //             final tag =
              //                 promo['tag']?.toString().toLowerCase() ?? '';
              //             if (tag.contains('ส่งฟรี') || tag.contains('food')) {
              //               context.go('/food-delivery');
              //             } else if (tag.contains('เดินทาง') ||
              //                 tag.contains('ride')) {
              //               context.go('/ride-landing');
              //             } else {
              //               context.go('/home');
              //             }
              //           } else {
              //             // Collect action
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               SnackBar(
              //                 content: Text(
              //                   'เก็บคูปอง ${promo['code']} สำเร็จแล้ว!',
              //                 ),
              //                 backgroundColor: barColor,
              //                 behavior: SnackBarBehavior.floating,
              //               ),
              //             );
              //           }
              //         },
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: isCollected
              //               ? Colors.grey.shade200
              //               : barColor,
              //           foregroundColor: isCollected
              //               ? AppColors.textSecondary
              //               : Colors.white,
              //           elevation: 0,
              //           padding: const EdgeInsets.symmetric(horizontal: 16),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(6),
              //           ),
              //           side: isCollected
              //               ? BorderSide(color: Colors.grey.shade300)
              //               : null,
              //         ),
              //         child: Text(
              //           isCollected ? 'ใช้' : 'เก็บ',
              //           style: const TextStyle(fontWeight: FontWeight.bold),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftTicketSection(Color color, String label, String tag) {
    IconData iconData;
    final tagLower = tag.toLowerCase();
    if (tagLower.contains('เดินทาง') || tagLower.contains('ride')) {
      iconData = Icons.directions_car_rounded;
    } else if (tagLower.contains('ความปลอดภัย') || tagLower.contains('sos')) {
      iconData = Icons.security_rounded;
    } else {
      iconData = Icons.restaurant_rounded;
    }

    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
      ),
      // Clean safe layout instead of complex positioned stack
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FREE',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                  Icon(iconData, color: color, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTypography.caption5.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
