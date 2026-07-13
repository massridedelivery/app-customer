// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:customer_app/core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    return ThemeData(
      fontFamily: 'NotoSansThai',
      textTheme: base.textTheme.apply(fontFamily: 'NotoSansThai'),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'NotoSansThai'),
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
