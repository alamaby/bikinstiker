import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/user_subscription.dart';

class TierBadge extends StatelessWidget {
  final SubscriptionTier tier;
  const TierBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final isPlus = tier == SubscriptionTier.plus;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPlus
            ? context.colors.primary
            : context.hairline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPlus ? 'PLUS' : 'FREE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: isPlus
              ? Theme.of(context).colorScheme.onPrimary
              : context.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
