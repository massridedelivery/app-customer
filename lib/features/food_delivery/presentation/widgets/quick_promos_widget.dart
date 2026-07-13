import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:flutter/material.dart';

class QuickPromosWidget extends StatelessWidget {
  const QuickPromosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildPromoCard(
              'ส่งฟรีใกล้บ้าน',
              'ค่าส่งเริ่ม ฿0',
              AppColors.foundationGreen100,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPromoCard(
              'ร้านโค้ดเดือด',
              'ลดสูงสุด ฿100*',
              AppColors.foundationOrange100,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildPromoCard(
              'โปรแบรนด์ดัง',
              'ลดแรงทั้งวีค',
              const Color(0xFFFDE8E8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(String title, String subtitle, Color bgColor) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.caption3.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
          Text(
            subtitle,
            style: AppTypography.caption5.copyWith(color: Colors.black54),
            maxLines: 1,
          ),
          const Spacer(),
          const Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.star_rounded, color: Colors.black12, size: 30),
          ),
        ],
      ),
    );
  }
}
