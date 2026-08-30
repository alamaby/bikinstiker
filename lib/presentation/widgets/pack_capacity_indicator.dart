import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';

/// Shows the user's pack slot usage: "X of Y packs used".
/// Displays a linear progress bar and warning state when at capacity.
class PackCapacityIndicator extends StatelessWidget {
  final int activeCount;
  final int slotCap;

  const PackCapacityIndicator({
    super.key,
    required this.activeCount,
    required this.slotCap,
  });

  bool get _isAtCapacity => activeCount >= slotCap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = slotCap > 0
        ? (activeCount / slotCap).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAtCapacity
            ? AppColors.error.withValues(alpha: 0.1)
            : context.surfaceAlt,
        border: Border.all(color: context.hairline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.packSlots, style: Theme.of(context).textTheme.titleSmall),
              Text(
                l10n.packSlotsUsed(activeCount, slotCap),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isAtCapacity ? AppColors.error : null,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: context.hairline.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _isAtCapacity ? AppColors.error : AppColors.primary,
            ),
          ),
          if (_isAtCapacity) ...[
            const SizedBox(height: 8),
            Text(
              l10n.packLimitReached,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
