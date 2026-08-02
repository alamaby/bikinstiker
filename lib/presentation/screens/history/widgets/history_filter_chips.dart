import 'package:flutter/material.dart';

import '../../../../core/localization/preset_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/sticker_preset.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blocs/history/history_bloc.dart';

class FilterChipDropdown<T> extends StatelessWidget {
  final String label;
  final String value;
  final List<PopupMenuEntry<T>> items;
  final ValueChanged<T> onSelected;
  final bool locked;

  const FilterChipDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return _LockedChip(label: label);
    }
    return PopupMenuButton<T>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}

class _LockedChip extends StatelessWidget {
  final String label;
  const _LockedChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.lock_outline, size: 12, color: Colors.black38),
        ],
      ),
    );
  }
}

List<PopupMenuEntry<String>> buildPresetFilterItems({
  required List<StickerPreset> presets,
  required AppLocalizations l10n,
}) {
  final items = <PopupMenuEntry<String>>[
    PopupMenuItem(value: '', child: Text(l10n.all)),
  ];
  for (final p in presets) {
    items.add(
      PopupMenuItem(
        value: p.id,
        child: Row(
          children: [
            if (p.emoji != null) ...[
              Text(p.emoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Text(localizedPresetLabel(l10n, p)),
          ],
        ),
      ),
    );
  }
  return items;
}

List<PopupMenuEntry<HistorySort>> buildSortItems(AppLocalizations l10n) {
  return HistorySort.values
      .map((s) => PopupMenuItem(value: s, child: Text(sortLabel(l10n, s))))
      .toList();
}

List<PopupMenuEntry<HistoryStatusFilter>> buildStatusFilterItems(
  AppLocalizations l10n,
) {
  return HistoryStatusFilter.values
      .map((f) => PopupMenuItem(value: f, child: Text(statusFilterLabel(l10n, f))))
      .toList();
}

List<PopupMenuEntry<HistoryDateFilter>> buildDateFilterItems(
  AppLocalizations l10n,
) {
  return HistoryDateFilter.values
      .map((f) => PopupMenuItem(value: f, child: Text(dateFilterLabel(l10n, f))))
      .toList();
}

String sortLabel(AppLocalizations l10n, HistorySort sort) {
  switch (sort) {
    case HistorySort.newest:
      return l10n.sortNewest;
    case HistorySort.oldest:
      return l10n.sortOldest;
    case HistorySort.presetAZ:
      return l10n.sortPresetAZ;
  }
}

String statusFilterLabel(AppLocalizations l10n, HistoryStatusFilter filter) {
  switch (filter) {
    case HistoryStatusFilter.all:
      return l10n.all;
    case HistoryStatusFilter.success:
      return l10n.success;
    case HistoryStatusFilter.pending:
      return l10n.pending;
    case HistoryStatusFilter.failed:
      return l10n.failed;
  }
}

String dateFilterLabel(AppLocalizations l10n, HistoryDateFilter filter) {
  switch (filter) {
    case HistoryDateFilter.all:
      return l10n.allTime;
    case HistoryDateFilter.last7d:
      return l10n.last7d;
    case HistoryDateFilter.last30d:
      return l10n.last30d;
    case HistoryDateFilter.last90d:
      return l10n.last90d;
  }
}
