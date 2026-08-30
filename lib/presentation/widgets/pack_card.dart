import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/sticker_pack.dart';
import '../../l10n/app_localizations.dart';

/// Card widget displaying a single sticker pack in a grid.
/// Shows tray icon placeholder, pack name, sticker count, and lock state.
class PackCard extends StatelessWidget {
  final StickerPack pack;
  final VoidCallback? onTap;

  /// True when the pack has an active/suspended Showcase listing.
  final bool isListed;

  const PackCard({
    super.key,
    required this.pack,
    this.onTap,
    this.isListed = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PackThumbnail(pack: pack),
                  if (isListed)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Chip(
                        label: Text(
                          AppLocalizations.of(context)?.packListedBadge ??
                              'Listed',
                          style: const TextStyle(fontSize: 10),
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        backgroundColor:
                            AppColors.secondary.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
            ),
            // Pack name and count
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
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
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.packStickerCount(pack.stickerCount, 30),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackThumbnail extends StatelessWidget {
  final StickerPack pack;

  const _PackThumbnail({required this.pack});

  @override
  Widget build(BuildContext context) {
    final url = pack.firstStickerSignedUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => _placeholder(context),
        errorWidget: (context, url, error) => _placeholder(context),
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.collections_bookmark,
          size: 48,
          color: pack.isLocked ? context.hairline : context.colors.primary,
        ),
      ),
    );
  }
}
