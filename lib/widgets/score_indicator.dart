import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

import 'package:vastuscan_ar/models/vastu_result.dart';

/// Animated circular Vastu Score indicator widget.
///
/// Shows a ring progress with percentage and item count,
/// smoothly animating between values.
class ScoreIndicator extends StatefulWidget {
  final double score;
  final int totalItems;
  final int compliantItems;
  final int nonCompliantItems;
  final List<VastuResult> results;

  const ScoreIndicator({
    super.key,
    required this.score,
    required this.totalItems,
    required this.compliantItems,
    required this.nonCompliantItems,
    this.results = const [],
  });

  @override
  State<ScoreIndicator> createState() => _ScoreIndicatorState();
}

class _ScoreIndicatorState extends State<ScoreIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scoreAnimation =
        Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ScoreIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.score - widget.score).abs() > 0.5) {
      _scoreAnimation = Tween<double>(
        begin: oldWidget.score,
        end: widget.score,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score >= 75) return AppColors.compliant;
    if (score >= 45) return AppColors.warning;
    return AppColors.nonCompliant;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.saffron.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _scoreAnimation,
        builder: (context, _) {
          final animatedScore = _scoreAnimation.value;
          final scoreColor = _getScoreColor(animatedScore);

          final nonCompliantResults = widget.results.where((r) => !r.isCompliant).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Circular progress
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CustomPaint(
                      painter: _CircularScorePainter(
                        score: animatedScore / 100,
                        color: scoreColor,
                      ),
                      child: Center(
                        child: Text(
                          '${animatedScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Score details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'VASTU SCORE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${widget.totalItems} items',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 6,
                            child: LinearProgressIndicator(
                              value: animatedScore / 100,
                              backgroundColor: AppColors.lightSurface,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(scoreColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Item counts
                        Row(
                          children: [
                            _StatusDot(
                              color: AppColors.compliant,
                              label: '${widget.compliantItems} OK',
                            ),
                            const SizedBox(width: 16),
                            _StatusDot(
                              color: AppColors.nonCompliant,
                              label: '${widget.nonCompliantItems} Fix',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (nonCompliantResults.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                    ),
                  ]
                ],
              ),
              if (_isExpanded && nonCompliantResults.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Column(
                      children: nonCompliantResults.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.nonCompliant, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${r.rule.element} (Current: ${r.currentDirectionLabel})', 
                                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Move to: ${r.rule.idealDirection}', 
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.rule.practicalTips, 
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ]
            ],
          );
        },
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

class _CircularScorePainter extends CustomPainter {
  final double score;
  final Color color;

  _CircularScorePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.lightSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * score,
      false,
      scorePaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * score,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularScorePainter oldDelegate) {
    return (score - oldDelegate.score).abs() > 0.005 ||
        color != oldDelegate.color;
  }
}
