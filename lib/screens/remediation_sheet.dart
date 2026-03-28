import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

/// Bottom sheet showing remediation tips for non-compliant items.
///
/// Features glassmorphism design, direction comparison visualization,
/// and practical Vastu tips from the reference chart.
class RemediationSheet extends StatelessWidget {
  final VastuResult result;

  const RemediationSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildDirectionComparison(),
                  const SizedBox(height: 20),
                  _buildStatusSection(),
                  const SizedBox(height: 20),
                  _buildTipsSection(),
                  const SizedBox(height: 20),
                  _buildPurposeSection(),
                  const SizedBox(height: 24),
                  _buildCloseButton(context),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: result.isCompliant
                ? AppColors.compliant.withOpacity(0.12)
                : AppColors.nonCompliant.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            result.isCompliant
                ? Icons.check_circle_rounded
                : Icons.warning_amber_rounded,
            color: result.isCompliant
                ? AppColors.compliant
                : AppColors.nonCompliant,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.rule.element,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                result.rule.category,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectionComparison() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DirectionCard(
              label: 'CURRENT',
              direction: result.currentDirectionLabel,
              color: result.isCompliant
                  ? AppColors.compliant
                  : AppColors.nonCompliant,
              icon: result.isCompliant
                  ? Icons.check_circle
                  : Icons.cancel,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
          Expanded(
            child: _DirectionCard(
              label: 'IDEAL',
              direction: result.rule.idealDirection,
              color: AppColors.saffron,
              icon: Icons.star_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final isCompliant = result.isCompliant;
    final bgColor = isCompliant ? AppColors.compliantBg : AppColors.nonCompliantBg;
    final borderColor = isCompliant
        ? AppColors.compliant.withOpacity(0.3)
        : AppColors.nonCompliant.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isCompliant
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: isCompliant ? AppColors.compliant : AppColors.nonCompliant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.summary,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isCompliant ? AppColors.compliant : AppColors.nonCompliant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_rounded, size: 18, color: AppColors.gold),
            const SizedBox(width: 8),
            const Text(
              'PRACTICAL TIPS',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: Text(
            result.rule.practicalTips,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurposeSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.saffron.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.saffron.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: AppColors.saffron),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vastu Purpose',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.saffron,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.rule.purpose,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.saffron.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'GOT IT',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.saffron,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final String label;
  final String direction;
  final Color color;
  final IconData icon;

  const _DirectionCard({
    required this.label,
    required this.direction,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 6),
        Text(
          direction,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
