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
        borderRadius: BorderRadius.circular(999),
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

/// Bottom-sheet catalog of sticker presets. Seasonal presets are grouped in a
/// top section with a limited-time header; above-tier presets render as
/// locked tiles — tapping one shows a Plus hint instead of selecting. Tier
/// enforcement itself always happens server-side in generate-sticker.
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
                      ...seasonal.map((p) => _buildTile(context, l10n, p)),
                      const SizedBox(height: 8),
                    ],
                    ...regular.map((p) => _buildTile(context, l10n, p)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    AppLocalizations l10n,
    StickerPreset p,
  ) {
    final selected = p.id == selectedId;
    final locked = p.isLockedFor(viewRole);
    final validUntil = p.validUntil;

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: ListTile(
        leading: Text(p.emoji ?? '', style: const TextStyle(fontSize: 24)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                localizedPresetLabel(l10n, p),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (p.isSeasonal) ...[
              const SizedBox(width: 6),
              const PresetLimitedBadge(),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizedPresetDescription(l10n, p),
              style: const TextStyle(fontSize: 13),
            ),
            if (p.isSeasonal && validUntil != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.hourglass_bottom,
                    size: 12,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      l10n.seasonalEndsOn(
                        DateFormat.yMMMd(l10n.localeName)
                            .format(validUntil.toLocal()),
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : locked
            ? Icon(Icons.lock_outline, size: 20, color: context.textFaint)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          if (locked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.plusOnlyPreset)),
            );
            return;
          }
          onSelect(p.id);
        },
      ),
    );
  }
}
