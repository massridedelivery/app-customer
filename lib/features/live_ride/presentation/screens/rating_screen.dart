import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/app_filter_chip.dart';
import 'package:customer_app/features/live_ride/domain/models/driver_profile_model.dart';
import 'package:customer_app/features/live_ride/presentation/controllers/rating_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String jobId;
  final DriverProfileModel? driverProfile;

  /// Tip chosen on the payment-summary screen (shown before this one). Carried
  /// through and submitted with the rating.
  final int? tip;

  const RatingScreen({
    super.key,
    required this.jobId,
    this.driverProfile,
    this.tip,
  });

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  int _rating = 0;
  final Set<String> _selectedTags = {};
  final _commentController = TextEditingController();

  static const _feedbackTags = [
    'ขับรถดี',
    'สุภาพ',
    'รถสะอาด',
    'ตรงเวลา',
    'ขับขี่ปลอดภัย',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitRating() {
    ref
        .read(ratingControllerProvider.notifier)
        .submitRating(
          jobId: widget.jobId,
          rating: _rating,
          tags: _selectedTags.toList(),
          tip: widget.tip,
          comment: _commentController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(ratingControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          final message = error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : error.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: AppTypography.caption4.copyWith(color: AppColors.white),
              ),
              backgroundColor: message.contains('กรุณา')
                  ? AppColors.grey800
                  : AppColors.error,
            ),
          );
        },
        data: (_) {
          context.go('/main');
        },
      );
    });

    final ratingState = ref.watch(ratingControllerProvider);
    final isSubmitting = ratingState.isLoading;
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'รีวิวการเดินทางของคุณ',
          style: AppTypography.heading4.copyWith(color: AppColors.black),
        ),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Rider Section
            _buildSection(
              child: Column(
                children: [
                  Row(
                    children: [
                      (widget.driverProfile?.driverInfo.avatarUrl != null &&
                              widget
                                  .driverProfile!
                                  .driverInfo
                                  .avatarUrl
                                  .isNotEmpty)
                          ? Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(
                                    widget.driverProfile!.driverInfo.avatarUrl,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: AppColors.semanticGrayNeutralFgHigh,
                              size: 32,
                            ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driverProfile?.driverInfo.fullName ??
                                'ไม่ระบุชื่อคนขับ',
                            style: AppTypography.label2,
                          ),
                          Text(
                            () {
                              final info = widget.driverProfile?.driverInfo;
                              if (info == null) return 'คนขับของคุณ';
                              final parts = <String>[];
                              if (info.vehiclePlate.isNotEmpty) {
                                parts.add(info.vehiclePlate);
                              }
                              final vehicleDesc = [
                                if (info.vehicleColor.isNotEmpty)
                                  info.vehicleColor,
                                if (info.vehicleModel.isNotEmpty)
                                  info.vehicleModel,
                              ].join(' ');
                              if (vehicleDesc.isNotEmpty) {
                                parts.add(vehicleDesc);
                              }
                              parts.add('คนขับของคุณ');
                              return parts.join('  •  ');
                            }(),
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
                  _buildStarRow(_rating, (v) => setState(() => _rating = v)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _feedbackTags.map((tag) {
                      final selected = _selectedTags.contains(tag);
                      return AppFilterChip(
                        label: tag,
                        selected: selected,
                        onTap: () {
                          setState(() {
                            selected
                                ? _selectedTags.remove(tag)
                                : _selectedTags.add(tag);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Comment Section
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
                ],
              ),
            ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Pinned action bar at the bottom of the screen.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.foundationGreen500,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
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
                  const SizedBox(height: 4),
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
                ],
              ),
            ),
          ),
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
}
