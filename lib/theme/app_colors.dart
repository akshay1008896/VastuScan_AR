import 'package:flutter/material.dart';

/// VastuScan AR Color Palette — Dreamy Pastel Light Theme.
///
/// Inspired by soft, warm pastel aesthetics with peach-pink-lavender
/// gradient accents and frosted glass surfaces.
class AppColors {
  AppColors._();

  // ─── Primary Light Backgrounds ────────────────────────────────
  static const Color cream = Color(0xFFFFF6F1);
  static const Color warmSand = Color(0xFFFFF0EA);
  static const Color lightSurface = Color(0xFFFFE8DF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFFFF3ED);

  // Legacy names
  static const Color deepNavy = cream;
  static const Color darkSurface = warmSand;

  // ─── Accent Colors ────────────────────────────────────────────
  static const Color saffron = Color(0xFFFF8A65);        // Warm peach-coral
  static const Color saffronLight = Color(0xFFFFAB91);   // Light peach
  static const Color saffronDark = Color(0xFFE64A19);    // Deep coral
  static const Color gold = Color(0xFFFFB74D);           // Warm amber
  static const Color goldLight = Color(0xFFFFD54F);      // Light amber
  static const Color goldDim = Color(0xFFFFA000);        // Deep amber
  static const Color warmTerracotta = Color(0xFFFF7043); // Warm orange

  // ─── Pastel Accent Palette (from reference) ───────────────────
  static const Color pastelPeach = Color(0xFFFFCCBC);
  static const Color pastelPink = Color(0xFFFFCDD2);
  static const Color pastelLavender = Color(0xFFD1C4E9);
  static const Color pastelMint = Color(0xFFB2DFDB);
  static const Color pastelYellow = Color(0xFFFFF9C4);

  // ─── Vastu Compliance Colors ──────────────────────────────────
  static const Color compliant = Color(0xFF43A047);
  static const Color compliantGlow = Color(0x3043A047);
  static const Color compliantBg = Color(0xFFE8F5E9);
  static const Color nonCompliant = Color(0xFFE53935);
  static const Color nonCompliantGlow = Color(0x30E53935);
  static const Color nonCompliantBg = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFA726);
  static const Color warningGlow = Color(0x30FFA726);

  // ─── Text Colors ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D2D3A);
  static const Color textSecondary = Color(0xFF6B6B80);
  static const Color textMuted = Color(0xFFA0A0B5);
  static const Color textOnSaffron = Color(0xFFFFFFFF);

  // ─── Compass Colors ───────────────────────────────────────────
  static const Color compassNorth = Color(0xFFE53935);
  static const Color compassTick = Color(0xFFBCAAC0);
  static const Color compassActiveTick = Color(0xFFFF8A65);
  static const Color compassBg = Color(0xE6FFF6F1);

  // ─── Glassmorphism (dreamy) ───────────────────────────────────
  static const Color glassWhite = Color(0x50FFFFFF);
  static const Color glassBorder = Color(0x25FF8A65);
  static const Color glassOverlay = Color(0x10FF8A65);

  // ─── Divider / Border ─────────────────────────────────────────
  static const Color divider = Color(0xFFF0E0D8);
  static const Color border = Color(0xFFE8D5CC);

  // ─── Direction Element Colors ─────────────────────────────────
  static const Color elementFire = Color(0xFFFF5722);
  static const Color elementWater = Color(0xFF42A5F5);
  static const Color elementEarth = Color(0xFF8D6E63);
  static const Color elementAir = Color(0xFF4FC3F7);
  static const Color elementSpace = Color(0xFFAB47BC);

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

  /// Dreamy pastel blob gradient for backgrounds
  static const LinearGradient dreamyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF6F1),
      Color(0xFFFFE8DF),
      Color(0xFFF3E5F5),
      Color(0xFFFFF0EA),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static const LinearGradient warmCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF3ED)],
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
      Color(0x00FFF6F1),
      Color(0xE6FFF6F1),
      Color(0xE6FFF6F1),
      Color(0x00FFF6F1),
    ],
    stops: [0.0, 0.15, 0.85, 1.0],
  );

  /// Peach-pink pill gradient (for buttons / chips)
  static const LinearGradient pillGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFAB91), Color(0xFFFF8A65)],
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
