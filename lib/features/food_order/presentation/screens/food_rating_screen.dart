import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/constants/feature_flags.dart';
import 'package:customer_app/features/food_order/presentation/controllers/food_rating_controller.dart';
import 'package:customer_app/features/food_order/presentation/states/food_rating_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FoodRatingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const FoodRatingScreen({super.key, required this.orderId});

  @override
  ConsumerState<FoodRatingScreen> createState() => _FoodRatingScreenState();
}

class _FoodRatingScreenState extends ConsumerState<FoodRatingScreen> {
  int _riderStars = 0;
  int _restaurantStars = 0;
  final Set<String> _selectedTags = {};
  int? _selectedTip;
  bool _isAnonymous = false;
  final _commentController = TextEditingController();
  final Map<String, int> _itemRatings = {};

  static const _riderTags = [
    'บริการดี',
    'ส่งไว',
    'สุภาพ',
    'แพคเกจดี',
    'ตรงเวลา',
  ];
  static const _tipOptions = [10, 20, 50];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(FoodRatingState stateInfo) async {
    if (_restaurantStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาให้คะแนนร้านอาหารก่อนส่งนะครับ')),
      );
      return;
    }

    final itemReviewsList = <Map<String, dynamic>>[];
    if (stateInfo.order != null) {
      for (final item in stateInfo.order!.items) {
        final itemRating = _itemRatings[item.id] ?? 5; // Default to 5 if not selected
        itemReviewsList.add({
          'order_item_id': item.id,
          'rating': itemRating,
          'comment': '',
        });
      }
    }

    final success = await ref
        .read(foodRatingControllerProvider(widget.orderId).notifier)
        .submitReview(
          rating: _restaurantStars,
          comment: _commentController.text,
          isAnonymous: _isAnonymous,
          itemReviews: itemReviewsList,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งรีวิวสำเร็จ ขอบคุณสำหรับความคิดเห็นครับ')),
      );
      context.go('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratingState = ref.watch(foodRatingControllerProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/main'),
        ),
        title: Text('รีวิวออเดอร์ของคุณ', style: AppTypography.heading4),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.go('/main'),
            child: Text(
              'ข้าม',
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticGrayNeutralFgLowOnWhite,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(context, ratingState),
    );
  }

  Widget _buildBody(BuildContext context, FoodRatingState stateInfo) {
    if (stateInfo.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stateInfo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${stateInfo.error}',
                textAlign: TextAlign.center,
                style: AppTypography.body1,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref
                    .read(foodRatingControllerProvider(widget.orderId).notifier)
                    .loadOrderDetails(widget.orderId),
                child: const Text('ลองอีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    final driverName = stateInfo.order?.driverName ?? 'คนขับของคุณ';
    final vehiclePlate = stateInfo.order?.vehiclePlate ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Driver rating + tip are never submitted — the review API accepts
          // only rating + comment (SCRUM-44). Hidden behind a flag.
          if (FeatureFlags.foodReviewDriverExtras) ...[
          // Rider Rating Card
          _buildSection(
            child: Column(
              children: [
                Row(
                  children: [
                    // Rider avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://randomuser.me/api/portraits/men/32.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName, style: AppTypography.label2),
                        Text(
                          '$vehiclePlate  •  คนขับของคุณ',
                          style: AppTypography.caption5.copyWith(
                            color: AppColors.semanticGrayNeutralFgLowOnWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'ให้คะแนนคนขับ',
                  style: AppTypography.label2.copyWith(
                    color: AppColors.semanticGrayNeutralFgHigh,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStarRow(
                  _riderStars,
                  (v) => setState(() => _riderStars = v),
                ),
                const SizedBox(height: 16),
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _riderTags.map((tag) {
                    final selected = _selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          v
                              ? _selectedTags.add(tag)
                              : _selectedTags.remove(tag);
                        });
                      },
                      selectedColor: AppColors.foundationGreen100,
                      checkmarkColor: AppColors.foundationGreen600,
                      labelStyle: AppTypography.caption4.copyWith(
                        color: selected
                            ? AppColors.foundationGreen600
                            : AppColors.semanticGrayNeutralFgHigh,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.foundationGreen500
                            : AppColors.grey300,
                      ),
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      showCheckmark: true,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tip Card
          _buildSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.volunteer_activism,
                      color: AppColors.foundationGreen500,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ให้ทิปคนขับ (ไม่บังคับ)',
                      style: AppTypography.label2,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ทิปจะถูกหักจากช่องทางชำระเงินที่คุณเลือก',
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.semanticGrayNeutralFgLowOnWhite,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: _tipOptions.map((tip) {
                    final selected = _selectedTip == tip;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedTip = selected ? null : tip;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.foundationGreen500
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.foundationGreen500
                                    : AppColors.grey300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '+฿$tip',
                                style: AppTypography.label2.copyWith(
                                  color: selected
                                      ? AppColors.white
                                      : AppColors.semanticGrayNeutralFgHigh,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          ],

          // Restaurant Rating Card
          _buildSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(
                            stateInfo.restaurant?.imageUrl ??
                                'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stateInfo.restaurant?.restaurantName ?? 'ร้านค้า',
                            style: AppTypography.label2,
                          ),
                          Text(
                            'ให้คะแนนร้านอาหาร',
                            style: AppTypography.caption5.copyWith(
                              color:
                                  AppColors.semanticGrayNeutralFgLowOnWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStarRow(
                  _restaurantStars,
                  (v) => setState(() => _restaurantStars = v),
                ),
              ],
            ),
          ),

          // Item Ratings Card
          if (stateInfo.order != null && stateInfo.order!.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ให้คะแนนเมนูอาหาร', style: AppTypography.label2),
                  const SizedBox(height: 16),
                  ...stateInfo.order!.items.map((item) {
                    final rating = _itemRatings[item.id] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: AppTypography.label3),
                                if (item.selectedModifiers.isNotEmpty)
                                  Text(
                                    item.selectedModifiers.map((e) => e.name).join(', '),
                                    style: AppTypography.caption5.copyWith(
                                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _buildSmallStarRow(
                            rating,
                            (v) => setState(() => _itemRatings[item.id] = v),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Comment card
          _buildSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ความคิดเห็นเพิ่มเติม', style: AppTypography.label2),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'บอกเราว่าคุณชอบหรือไม่ชอบอะไร...',
                      hintStyle: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgLowOnWhite,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _isAnonymous,
                      onChanged: (v) => setState(() => _isAnonymous = v ?? false),
                      activeColor: AppColors.foundationGreen500,
                    ),
                    Text(
                      'แสดงความคิดเห็นแบบไม่เปิดเผยตัวตน',
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.semanticGrayNeutralFgHigh,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: stateInfo.isSubmitting ? null : () => _submit(stateInfo),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.foundationGreen500,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: stateInfo.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'ส่งรีวิว',
                      style: AppTypography.label1.copyWith(
                        color: AppColors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Skip button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.go('/main'),
              child: Text(
                'ข้ามไปก่อน',
                style: AppTypography.label2.copyWith(
                  color: AppColors.semanticGrayNeutralFgLowOnWhite,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStarRow(int current, ValueChanged<int> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              i < current ? Icons.star_rate_sharp : Icons.star_outline,
              size: 42,
              color: i < current ? AppColors.amber : AppColors.grey300,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSmallStarRow(int current, ValueChanged<int> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < current ? Icons.star_rate_sharp : Icons.star_outline,
              size: 28,
              color: i < current ? AppColors.amber : AppColors.grey300,
            ),
          ),
        );
      }),
    );
  }
}
