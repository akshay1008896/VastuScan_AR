import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

/// Draws bounding boxes over detected objects with Vastu compliance coloring.
///
/// Green boxes for compliant items, red for non-compliant,
/// with animated pulsing glow effect.
class DetectionOverlay extends StatefulWidget {
  final List<VastuResult> results;
  final Size previewSize;
  final void Function(VastuResult result)? onInfoTap;

  const DetectionOverlay({
    super.key,
    required this.results,
    required this.previewSize,
    this.onInfoTap,
  });

  @override
  State<DetectionOverlay> createState() => _DetectionOverlayState();
}

class _DetectionOverlayState extends State<DetectionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _DetectionPainter(
            results: widget.results,
            pulseValue: _pulseAnimation.value,
          ),
          child: _buildInfoChips(context),
        );
      },
    );
  }

  Widget _buildInfoChips(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: widget.results.map((result) {
        final box = result.detectedObject.boundingBox;
        final left = box.left * screenSize.width;
        final top = box.top * screenSize.height;
        final width = box.width * screenSize.width;
        final height = box.height * screenSize.height;

        return Positioned(
          left: left,
          top: top,
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label tag
              _buildLabelTag(result),
              SizedBox(height: height - 24),
              // Info button for non-compliant
              if (!result.isCompliant)
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildInfoButton(result),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabelTag(VastuResult result) {
    final isCompliant = result.isCompliant;
    final color = isCompliant ? AppColors.compliant : AppColors.nonCompliant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompliant ? Icons.check_circle : Icons.warning_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            result.rule.element.split('/').first.trim().toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton(VastuResult result) {
    return GestureDetector(
      onTap: () => widget.onInfoTap?.call(result),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.nonCompliant.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.nonCompliant
                      .withOpacity(_pulseAnimation.value * 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.info_outline,
              size: 18,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<VastuResult> results;
  final double pulseValue;

  _DetectionPainter({required this.results, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final result in results) {
      final box = result.detectedObject.boundingBox;
      final rect = Rect.fromLTWH(
        box.left * size.width,
        box.top * size.height,
        box.width * size.width,
        box.height * size.height,
      );

      final isCompliant = result.isCompliant;
      final color = isCompliant ? AppColors.compliant : AppColors.nonCompliant;

      // Draw glow effect
      final glowPaint = Paint()
        ..color = color.withOpacity(pulseValue * 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(8)),
        glowPaint,
      );

      // Draw bounding box
      final borderPaint = Paint()
        ..color = color.withOpacity(0.8 + pulseValue * 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );

      // Draw corner brackets for a "scanning" effect
      _drawCornerBrackets(canvas, rect, color, 16);
    }
  }

  void _drawCornerBrackets(
      Canvas canvas, Rect rect, Color color, double length) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(
        Offset(rect.left, rect.top + length), rect.topLeft, paint);
    canvas.drawLine(
        rect.topLeft, Offset(rect.left + length, rect.top), paint);

    // Top-right
    canvas.drawLine(
        Offset(rect.right - length, rect.top), rect.topRight, paint);
    canvas.drawLine(
        rect.topRight, Offset(rect.right, rect.top + length), paint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - length),
        rect.bottomLeft, paint);
    canvas.drawLine(
        rect.bottomLeft, Offset(rect.left + length, rect.bottom), paint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right - length, rect.bottom),
        rect.bottomRight, paint);
    canvas.drawLine(Offset(rect.right, rect.bottom - length),
        rect.bottomRight, paint);
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return results != oldDelegate.results ||
        (pulseValue - oldDelegate.pulseValue).abs() > 0.01;
  }
}
