import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

/// VastuScan AR Theme — Dreamy Pastel Light Theme.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,

      colorScheme: const ColorScheme.light(
        primary: AppColors.saffron,
        onPrimary: AppColors.textOnSaffron,
        secondary: AppColors.gold,
        onSecondary: AppColors.textOnSaffron,
        surface: AppColors.cardSurface,
        onSurface: AppColors.textPrimary,
        error: AppColors.nonCompliant,
        onError: Colors.white,
        outline: AppColors.border,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: AppColors.saffron),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Outfit', fontSize: 48, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary, letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Outfit', fontSize: 36, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: -0.5,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Outfit', fontSize: 28, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary, letterSpacing: 0.15,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary, letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400,
          color: AppColors.textPrimary, letterSpacing: 0.25,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400,
          color: AppColors.textSecondary, letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400,
          color: AppColors.textMuted, letterSpacing: 0.3,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.saffron, letterSpacing: 1.0,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.saffron,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.saffron,
          side: const BorderSide(color: AppColors.pastelPeach, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
          fontSize: 14,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 14,
          color: AppColors.textSecondary, height: 1.5,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.elevatedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.saffron, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontFamily: 'Inter'),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
