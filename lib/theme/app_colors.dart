import 'package:flutter/material.dart';

/// VastuScan AR Color Palette.
///
/// A premium dark theme with saffron accents inspired by traditional
/// Vastu Shastra aesthetics combined with modern AR design.
class AppColors {
  AppColors._();

  // ─── Primary Dark Backgrounds ─────────────────────────────────
  static const Color deepNavy = Color(0xFF0A0E27);
  static const Color darkSurface = Color(0xFF111633);
  static const Color cardSurface = Color(0xFF1A1F42);
  static const Color elevatedSurface = Color(0xFF232952);

  // ─── Accent Colors ────────────────────────────────────────────
  static const Color saffron = Color(0xFFFF6B35);
  static const Color saffronLight = Color(0xFFFF8F5E);
  static const Color saffronDark = Color(0xFFE55A25);
  static const Color gold = Color(0xFFFFB347);
  static const Color goldDim = Color(0xFFCC8E34);

  // ─── Vastu Compliance Colors ──────────────────────────────────
  static const Color compliant = Color(0xFF00E676);
  static const Color compliantGlow = Color(0x4000E676);
  static const Color compliantBg = Color(0xFF0D2818);
  static const Color nonCompliant = Color(0xFFFF1744);
  static const Color nonCompliantGlow = Color(0x40FF1744);
  static const Color nonCompliantBg = Color(0xFF2D0A0A);
  static const Color warning = Color(0xFFFFAB00);
  static const Color warningGlow = Color(0x40FFAB00);

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B3CC);
  static const Color textMuted = Color(0xFF6B6F8D);
  static const Color textOnSaffron = Color(0xFFFFFFFF);

  // ─── Compass Colors ───────────────────────────────────────────
  static const Color compassNorth = Color(0xFFFF1744);
  static const Color compassTick = Color(0xFF4A4F70);
  static const Color compassActiveTick = Color(0xFFFFB347);
  static const Color compassBg = Color(0xCC0A0E27);

  // ─── Glassmorphism ────────────────────────────────────────────
  static const Color glassWhite = Color(0x12FFFFFF);
  static const Color glassBorder = Color(0x25FFFFFF);
  static const Color glassOverlay = Color(0x0DFFFFFF);

  // ─── Direction Element Colors ─────────────────────────────────
  static const Color elementFire = Color(0xFFFF5722);
  static const Color elementWater = Color(0xFF2196F3);
  static const Color elementEarth = Color(0xFF795548);
  static const Color elementAir = Color(0xFF90CAF9);
  static const Color elementSpace = Color(0xFF9C27B0);

  // ─── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [saffron, Color(0xFFFF8F5E)],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepNavy, Color(0xFF060818)],
  );

  static const LinearGradient scoreGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [nonCompliant, warning, compliant],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient compassGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0x000A0E27),
      Color(0xCC0A0E27),
      Color(0xCC0A0E27),
      Color(0x000A0E27),
    ],
    stops: [0.0, 0.15, 0.85, 1.0],
  );

  /// Get element color by name.
  static Color elementColor(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return elementFire;
      case 'water':
        return elementWater;
      case 'earth':
        return elementEarth;
      case 'air':
        return elementAir;
      case 'space':
        return elementSpace;
      default:
        return textMuted;
    }
  }
}
