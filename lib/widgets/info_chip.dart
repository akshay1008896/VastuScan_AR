import 'package:flutter/material.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

/// A floating info chip that appears on non-compliant detected objects.
class InfoChip extends StatelessWidget {
  final String label;
  final String direction;
  final VoidCallback? onTap;

  const InfoChip({
    super.key,
    required this.label,
    required this.direction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.nonCompliant.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.nonCompliant.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              'Move to $direction',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
