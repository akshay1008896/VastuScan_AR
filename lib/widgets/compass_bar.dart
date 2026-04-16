import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

/// A horizontal compass bar that stays fixed at the top of the screen.
///
/// Shows cardinal directions with tick marks, smoothly scrolling
/// as the device rotates. Current direction is highlighted.
class CompassBar extends StatelessWidget {
  final double heading;
  final String cardinalDirection;
  final String directionLabel;
  final bool isDemoMode;

  const CompassBar({
    super.key,
    required this.heading,
    required this.cardinalDirection,
    required this.directionLabel,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.compassBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.saffron.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Direction label and heading
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDemoMode)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEMO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                Text(
                  directionLabel.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.saffron,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.saffron.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.saffron.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${heading.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.saffronLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Compass strip
          SizedBox(
            height: 40,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: CustomPaint(
                painter: _CompassStripPainter(heading: heading),
                size: const Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassStripPainter extends CustomPainter {
  final double heading;

  _CompassStripPainter({required this.heading});

  static const _directions = [
    'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final pixelsPerDegree = size.width / 120; // Show ~120° visible range

    // Draw tick marks and labels
    for (int degree = -180; degree <= 540; degree += 5) {
      final normalizedDegree = degree % 360 < 0 ? degree % 360 + 360 : degree % 360;
      final x = centerX + (degree - heading) * pixelsPerDegree;

      if (x < -20 || x > size.width + 20) continue;

      final is45 = normalizedDegree % 45 == 0;
      final is15 = normalizedDegree % 15 == 0;

      final paint = Paint()
        ..color = is45
            ? (normalizedDegree == 0
                ? AppColors.compassNorth
                : AppColors.compassActiveTick)
            : is15
                ? AppColors.compassTick.withOpacity(0.7)
                : AppColors.compassTick.withOpacity(0.3)
        ..strokeWidth = is45 ? 2.0 : 1.0;

      final tickHeight = is45 ? 14.0 : is15 ? 8.0 : 5.0;

      canvas.drawLine(
        Offset(x, centerY - tickHeight / 2),
        Offset(x, centerY + tickHeight / 2),
        paint,
      );

      // Draw cardinal labels
      if (is45) {
        final dirIndex = (normalizedDegree / 45).round() % 8;
        final label = _directions[dirIndex];
        final isNorth = label == 'N';

        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isNorth ? 13 : 11,
              fontWeight: isNorth ? FontWeight.w800 : FontWeight.w600,
              color: isNorth
                  ? AppColors.compassNorth
                  : AppColors.compassActiveTick,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, centerY - tickHeight / 2 - 14),
        );
      }
    }

    // Draw center indicator (triangle)
    final indicatorPaint = Paint()
      ..color = AppColors.saffron
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(centerX - 6, size.height)
      ..lineTo(centerX + 6, size.height)
      ..lineTo(centerX, size.height - 8)
      ..close();
    canvas.drawPath(path, indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassStripPainter oldDelegate) {
    return (heading - oldDelegate.heading).abs() > 0.1;
  }
}
