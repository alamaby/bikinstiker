import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Ad banner placeholder — displays a static label indicating where an ad
/// will appear. No AdMob SDK integration yet; purely a visual placeholder.
class AdsBannerPlaceholder extends StatelessWidget {
  const AdsBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.outline.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ads_click, size: 16, color: Colors.black38),
            SizedBox(width: 6),
            Text(
              'Advertisement',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
