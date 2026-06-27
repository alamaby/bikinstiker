import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Color-blind safe status chip: ALWAYS pairs an icon + label with the color
/// so meaning never relies on hue alone.
class StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const StatusIndicator({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  factory StatusIndicator.success(String label) => StatusIndicator(
    icon: Icons.check_circle,
    label: label,
    color: AppColors.success,
  );

  factory StatusIndicator.error(String label) => StatusIndicator(
    icon: Icons.error_outline,
    label: label,
    color: AppColors.error,
  );

  factory StatusIndicator.pending(String label) => StatusIndicator(
    icon: Icons.hourglass_top,
    label: label,
    color: AppColors.primary,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
