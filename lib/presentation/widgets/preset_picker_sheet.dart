import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/preset_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sticker_preset.dart';
import '../../l10n/app_localizations.dart';

/// Small "Limited" chip shown on time-limited (seasonal) presets. Color is
/// never the sole signal — it always carries the localized text label.
class PresetLimitedBadge extends StatelessWidget {
  const PresetLimitedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 10, color: AppColors.secondary),
          const SizedBox(width: 3),
          Text(
            AppLocalizations.of(context)?.limitedBadge ?? 'Limited',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet catalog of sticker presets as a visual grid. Seasonal presets
/// are grouped in a top section with a limited-time header; above-tier
/// presets render as locked tiles — tapping one shows a Plus hint instead of
/// selecting. Tier enforcement itself always happens server-side in
/// generate-sticker.
class PresetPickerSheet extends StatelessWidget {
  final List<StickerPreset> presets;
  final String? selectedId;
  final StickerPresetRole viewRole;
  final ValueChanged<String> onSelect;

  const PresetPickerSheet({
    super.key,
    required this.presets,
    required this.selectedId,
    required this.viewRole,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seasonal = presets.where((p) => p.isSeasonal).toList();
    final regular = presets.where((p) => !p.isSeasonal).toList();

    // Local messenger + transparent scaffold so the locked-tile SnackBar
    // renders INSIDE the modal route (above the sheet content). The root
    // messenger's SnackBars sit below the modal barrier and are never seen.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.textFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.chooseStyleTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (seasonal.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.seasonalSectionTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.seasonalSectionInfo,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildGrid(context, l10n, seasonal),
                      const SizedBox(height: 12),
                    ],
                    _buildGrid(context, l10n, regular),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    AppLocalizations l10n,
    List<StickerPreset> items,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.80,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _GridTile(
        preset: items[i],
        selected: items[i].id == selectedId,
        locked: items[i].isLockedFor(viewRole),
        onTap: () {
          if (items[i].isLockedFor(viewRole)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.plusOnlyPreset)),
            );
            return;
          }
          onSelect(items[i].id);
        },
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final StickerPreset preset;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _GridTile({
    required this.preset,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validUntil = preset.validUntil;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.primary.withValues(alpha: 0.10)
                : context.surfaceAlt,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: Border.all(
              color: selected
                  ? context.colors.primary
                  : context.hairline.withValues(alpha: 0.7),
              width: selected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(preset.emoji ?? '',
                        style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      localizedPresetLabel(l10n, preset),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: context.textPrimary,
                      ),
                    ),
                    if (preset.isSeasonal) ...[
                      const SizedBox(height: 4),
                      const PresetLimitedBadge(),
                    ],
                    if (preset.isSeasonal && validUntil != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.yMMMd(l10n.localeName)
                            .format(validUntil.toLocal()),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: context.colors.onPrimary,
                    ),
                  ),
                )
              else if (locked)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.lock_outline,
                    size: 13,
                    color: context.textFaint,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
