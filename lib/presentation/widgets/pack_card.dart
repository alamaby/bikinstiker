import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/sticker_pack.dart';

/// Card widget displaying a single sticker pack in a grid.
/// Shows tray icon placeholder, pack name, sticker count, and lock state.
class PackCard extends StatelessWidget {
  final StickerPack pack;
  final VoidCallback? onTap;

  const PackCard({super.key, required this.pack, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tray icon placeholder area (96x96 ideal)
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: AppColors.surface,
                child: Center(
                  child: Icon(
                    Icons.collections_bookmark,
                    size: 48,
                    color: pack.isLocked
                        ? AppColors.outline
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
            // Pack name and count
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pack.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (pack.isLocked)
                        const Icon(
                          Icons.lock,
                          size: 16,
                          color: AppColors.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pack.stickerCount}/30 stickers',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
