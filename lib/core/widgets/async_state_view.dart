import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// Centered progress spinner for full-screen loading states.
///
/// Wrap in a `Scaffold` body or `SliverFillRemaining` as the layout requires.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: color ?? AppColors.primary),
    );
  }
}

/// Standard error state: an icon, a title, an optional detail line, and an
/// optional retry button. Shared across screens that load remote data.
///
/// Wrap in a `Scaffold` body or `SliverFillRemaining` as the layout requires.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({
    super.key,
    this.message = 'เกิดข้อผิดพลาดในการโหลดข้อมูล',
    this.detail,
    this.onRetry,
    this.retryLabel = 'ลองใหม่',
  });

  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.heading4,
              textAlign: TextAlign.center,
            ),
            if (detail != null && detail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: AppTypography.caption4,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  retryLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
