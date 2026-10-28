import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

/// A server line in a chat (`msg_type: system`), such as the note a call
/// leaves ("📞 โทร 1:24 นาที", "📞 สายที่ไม่ได้รับ"): centred and grey, from
/// neither side.
class ChatSystemNote extends StatelessWidget {
  const ChatSystemNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTypography.caption5.copyWith(
              color: AppColors.semanticGrayNeutralFgLowOnWhite,
            ),
          ),
        ),
      ),
    );
  }
}
