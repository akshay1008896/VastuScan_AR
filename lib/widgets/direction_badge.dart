import 'package:flutter/material.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

/// A badge showing the current compass direction.
class DirectionBadge extends StatelessWidget {
  final String direction;
  final String label;
  final double heading;

  const DirectionBadge({
    super.key,
    required this.direction,
    required this.label,
    required this.heading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.saffron.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.saffron.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.explore,
            size: 16,
            color: AppColors.saffron,
          ),
          const SizedBox(width: 6),
          Text(
            '$direction  ${heading.toStringAsFixed(0)}°',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.saffronLight,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
