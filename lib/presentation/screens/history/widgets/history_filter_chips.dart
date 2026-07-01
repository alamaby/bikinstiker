import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/sticker_preset.dart';
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
}) {
  final items = <PopupMenuEntry<String>>[
    const PopupMenuItem(value: '', child: Text('All')),
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
            Text(p.label),
          ],
        ),
      ),
    );
  }
  return items;
}

List<PopupMenuEntry<HistorySort>> buildSortItems() {
  return HistorySort.values
      .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
      .toList();
}

List<PopupMenuEntry<HistoryStatusFilter>> buildStatusFilterItems() {
  return HistoryStatusFilter.values
      .map((f) => PopupMenuItem(value: f, child: Text(f.label)))
      .toList();
}

List<PopupMenuEntry<HistoryDateFilter>> buildDateFilterItems() {
  return HistoryDateFilter.values
      .map((f) => PopupMenuItem(value: f, child: Text(f.label)))
      .toList();
}
