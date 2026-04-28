import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

/// Dreamy pastel detection overlay with corner brackets and connector lines.
class DetectionOverlay extends StatefulWidget {
  final List<VastuResult> results;
  final Size previewSize;
  final void Function(VastuResult result)? onInfoTap;
  final double currentHeading;

  const DetectionOverlay({
    super.key,
    required this.results,
    required this.previewSize,
    required this.currentHeading,
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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
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
    final screenSize = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Stack(
          children: widget.results.asMap().entries.map((entry) {
            return _buildIndicator(context, entry.value, screenSize, entry.key);
          }).toList(),
        );
      },
    );
  }

  Widget _buildIndicator(
      BuildContext context, VastuResult result, Size screen, int index) {
    final obj = result.detectedObject;
    final box = obj.boundingBox;
    final isCompliant = result.isCompliant;

    double cx, cy;

    if (obj.isManual && obj.originalHeading != null) {
      double diff = widget.currentHeading - obj.originalHeading!;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      if (diff.abs() > 50) return const SizedBox.shrink();
      const fov = 65.0;
      cx = screen.width / 2 - (diff / (fov / 2)) * (screen.width / 2);
      cy = screen.height * 0.4 + (index * 25);
    } else if (obj.isManual) {
      cx = screen.width * (0.2 + (index % 3) * 0.3);
      cy = screen.height * 0.4;
    } else {
      cx = (box.left + box.width / 2) * screen.width;
      cy = (box.top + box.height / 2) * screen.height;
    }

    final Color chipBg = isCompliant ? AppColors.compliant : AppColors.nonCompliant;
    final Color chipGlow = isCompliant ? AppColors.compliantGlow : AppColors.nonCompliantGlow;
    final double scale = _pulseAnimation.value;

    final double bLeft = box.left * screen.width;
    final double bTop = box.top * screen.height;
    final double bWidth = box.width * screen.width;
    final double bHeight = box.height * screen.height;

    const double chipWidth = 175;
    final double chipLeft = (cx - chipWidth / 2).clamp(8.0, screen.width - chipWidth - 8);
    
    double chipTopOffset = bTop - 68;
    if (chipTopOffset < 140) {
      chipTopOffset = bTop + bHeight + 16;
    }
    final double chipTop = chipTopOffset.clamp(140.0, screen.height - 100);
    
    final bool showBBox = !obj.isManual && bWidth > 20 && bHeight > 20;

    return Stack(
      children: [
        // Corner brackets
        if (showBBox)
          Positioned(
            left: bLeft, top: bTop, width: bWidth, height: bHeight,
            child: _CornerBrackets(color: chipBg, scale: scale),
          ),

        // Connector line
        if (showBBox)
          Positioned.fill(
            child: CustomPaint(
              painter: _ConnectorPainter(
                from: Offset(chipLeft + chipWidth / 2, chipTop + 34),
                to: Offset(cx, cy),
                color: chipBg,
              ),
            ),
          ),

        // Label chip
        Positioned(
          left: chipLeft, top: chipTop, width: chipWidth,
          child: GestureDetector(
            onTap: () => widget.onInfoTap?.call(result),
            child: Transform.scale(
              scale: scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Frosted label pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: chipBg.withValues(alpha: 0.5), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: chipGlow, blurRadius: 14, spreadRadius: 1),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: chipBg,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            obj.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: chipBg,
                              letterSpacing: 0.6,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Direction sub-label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      '${result.currentDirectionLabel} • ${isCompliant ? "✅ OK" : "⚠ Fix"}',
                      style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  final Color color;
  final double scale;
  const _CornerBrackets({required this.color, required this.scale});

  @override
  Widget build(BuildContext context) {
    final c = color.withValues(alpha: 0.65 * scale);
    const len = 16.0;
    const t = 2.0;
    return Stack(children: [
      Positioned(left: 0, top: 0, child: _corner(c, len, t, true, true)),
      Positioned(right: 0, top: 0, child: _corner(c, len, t, true, false)),
      Positioned(left: 0, bottom: 0, child: _corner(c, len, t, false, true)),
      Positioned(right: 0, bottom: 0, child: _corner(c, len, t, false, false)),
    ]);
  }

  Widget _corner(Color c, double len, double t, bool top, bool left) {
    return SizedBox(
      width: len, height: len,
      child: CustomPaint(painter: _CornerPainter(color: c, top: top, left: left, thickness: t)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color; final bool top; final bool left; final double thickness;
  _CornerPainter({required this.color, required this.top, required this.left, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thickness..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final double x0 = left ? 0 : size.width;
    final double y0 = top ? 0 : size.height;
    canvas.drawLine(Offset(x0, y0), Offset(x0 + (left ? size.width : -size.width), y0), paint);
    canvas.drawLine(Offset(x0, y0), Offset(x0, y0 + (top ? size.height : -size.height)), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.color != color;
}

class _ConnectorPainter extends CustomPainter {
  final Offset from; final Offset to; final Color color;
  _ConnectorPainter({required this.from, required this.to, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.35)..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final path = Path()..moveTo(from.dx, from.dy);
    path.quadraticBezierTo(from.dx, (from.dy + to.dy) / 2, to.dx, to.dy);
    const dashLen = 4.0; const gapLen = 3.0;
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, (d + dashLen).clamp(0.0, metric.length)), paint);
        d += dashLen + gapLen;
      }
    }
    canvas.drawCircle(to, 3, Paint()..color = color.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) => old.from != from || old.to != to;
}
