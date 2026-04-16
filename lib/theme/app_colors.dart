import 'package:flutter/material.dart';

/// VastuScan AR Color Palette — Warm Light Theme.
///
/// A warm, earthy light palette inspired by traditional Vastu Shastra
/// aesthetics — cream, sandstone, and warm saffron-gold accents.
class AppColors {
  AppColors._();

  // ─── Primary Light Backgrounds ────────────────────────────────
  static const Color cream = Color(0xFFFFF8F0);
  static const Color warmSand = Color(0xFFFAF3E8);
  static const Color lightSurface = Color(0xFFF5ECD8);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFFFF3E2);

  // Keep legacy names for backward compat — mapped to light equivalents
  static const Color deepNavy = cream;
  static const Color darkSurface = warmSand;

  // ─── Accent Colors ────────────────────────────────────────────
  static const Color saffron = Color(0xFFE8511A);
  static const Color saffronLight = Color(0xFFFF6B35);
  static const Color saffronDark = Color(0xFFC73D08);
  static const Color gold = Color(0xFFD4870A);
  static const Color goldDim = Color(0xFFA86A08);
  static const Color warmTerracotta = Color(0xFFCB5E2A);

  // ─── Vastu Compliance Colors (darkened for light bg) ──────────
  static const Color compliant = Color(0xFF2E7D32);
  static const Color compliantGlow = Color(0x402E7D32);
  static const Color compliantBg = Color(0xFFE8F5E9);
  static const Color nonCompliant = Color(0xFFC62828);
  static const Color nonCompliantGlow = Color(0x40C62828);
  static const Color nonCompliantBg = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFEF6C00);
  static const Color warningGlow = Color(0x40EF6C00);

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1209);
  static const Color textSecondary = Color(0xFF5C4A2A);
  static const Color textMuted = Color(0xFF9E8A6A);
  static const Color textOnSaffron = Color(0xFFFFFFFF);

  // ─── Compass Colors ───────────────────────────────────────────
  static const Color compassNorth = Color(0xFFD32F2F);
  static const Color compassTick = Color(0xFFBCAA92);
  static const Color compassActiveTick = Color(0xFFD4870A);
  static const Color compassBg = Color(0xE6FFF8F0);

  // ─── Glassmorphism (warm) ─────────────────────────────────────
  static const Color glassWhite = Color(0x20FFFFFF);
  static const Color glassBorder = Color(0x30D4870A);
  static const Color glassOverlay = Color(0x15D4870A);

  // ─── Divider / Border ─────────────────────────────────────────
  static const Color divider = Color(0xFFE8D9C0);
  static const Color border = Color(0xFFD6C5A8);

  // ─── Direction Element Colors ─────────────────────────────────
  static const Color elementFire = Color(0xFFE8511A);
  static const Color elementWater = Color(0xFF1565C0);
  static const Color elementEarth = Color(0xFF6D4C41);
  static const Color elementAir = Color(0xFF0277BD);
  static const Color elementSpace = Color(0xFF6A1B9A);

  // ─── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [saffron, warmTerracotta],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cream, warmSand],
  );

  static const LinearGradient warmCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF3E2)],
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
      Color(0x00FFF8F0),
      Color(0xE6FFF8F0),
      Color(0xE6FFF8F0),
      Color(0x00FFF8F0),
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
