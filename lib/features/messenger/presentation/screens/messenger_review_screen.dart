import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/messenger/presentation/controllers/messenger_review_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Post-delivery review for a messenger order (SCRUM-41): a 1-5 star rating
/// plus an optional comment. Reachable from the tracking screen once the
/// order is DELIVERED.
class MessengerReviewScreen extends ConsumerStatefulWidget {
  final String orderId;

  const MessengerReviewScreen({super.key, required this.orderId});

  @override
  ConsumerState<MessengerReviewScreen> createState() =>
      _MessengerReviewScreenState();
}

class _MessengerReviewScreenState
    extends ConsumerState<MessengerReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(messengerReviewControllerProvider.notifier).submit(
          orderId: widget.orderId,
          rating: _rating,
          comment: _commentController.text,
        );
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<AsyncValue<void>>(messengerReviewControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          final raw = error.toString().replaceFirst('Exception: ', '');
          // Already reviewed → not an error the user can act on; acknowledge
          // and leave rather than inviting a retry.
          if (raw == 'ALREADY_REVIEWED') {
            _snack(l10n.msgrAlreadyReviewed);
            context.go('/main');
            return;
          }
          // The controller reports a missing rating as a code; localize it.
          _snack(
            raw == kMessengerRatingRequired ? l10n.msgrRatingRequired : raw,
            isError: true,
          );
        },
        data: (_) {
          _snack(l10n.msgrReviewThanks);
          context.go('/main');
        },
      );
    });

    final isSubmitting = ref.watch(messengerReviewControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/main'),
        ),
        title: Text(l10n.msgrRateDeliveryTitle, style: AppTypography.heading4),
        actions: [
          TextButton(
            onPressed: () => context.go('/main'),
            child: Text(
              l10n.msgrSkip,
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
                  _buildSection(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.sports_motorsports,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.msgrHowWasDriver,
                          style: AppTypography.label2.copyWith(
                            color: AppColors.semanticGrayNeutralFgHigh,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.msgrRateThisDelivery,
                          style: AppTypography.caption5.copyWith(
                            color: AppColors.semanticGrayNeutralFgLowOnWhite,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStarRow(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.msgrCommentOptional,
                            style: AppTypography.label2),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _commentController,
                            maxLines: 4,
                            maxLength: 1000,
                            decoration: InputDecoration(
                              hintText: l10n.msgrCommentHint,
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
                ],
              ),
            ),
          ),
          // Pinned action bar at the bottom.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
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
                              l10n.msgrSubmitReview,
                              style: AppTypography.label1.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => context.go('/main'),
                      child: Text(
                        l10n.msgrSkipForNow,
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

  Widget _buildStarRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              i < _rating ? Icons.star_rate_sharp : Icons.star_outline,
              size: 42,
              color: i < _rating ? AppColors.amber : AppColors.grey300,
            ),
          ),
        );
      }),
    );
  }
}
