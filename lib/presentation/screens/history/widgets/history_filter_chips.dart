import 'package:flutter/material.dart';

import '../../../../core/localization/preset_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/sticker_preset.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../blocs/history/history_bloc.dart';

/// One selectable row in a filter bottom sheet.
class FilterOption<T> {
  final T value;
  final String label;
  final String? emoji;
  const FilterOption({required this.value, required this.label, this.emoji});
}

/// Filter chip that opens a bottom-sheet picker (replaces dropdown menus —
/// better thumb reachability and nothing clips on narrow screens). The chip
/// itself stays a compact "Label: value" pill.
class FilterChipDropdown<T> extends StatelessWidget {
  final String label;
  final String title;
  final T current;
  final List<FilterOption<T>> options;
  final ValueChanged<T> onSelected;
  final bool locked;

  const FilterChipDropdown({
    super.key,
    required this.label,
    required this.title,
    required this.current,
    required this.options,
    required this.onSelected,
    this.locked = false,
  });

  String get _currentLabel {
    for (final option in options) {
      if (option.value == current) return option.label;
    }
    return options.isNotEmpty ? options.first.label : '';
  }

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return _LockedChip(label: label);
    }
    return GestureDetector(
      onTap: () => _openFilterSheet<T>(
        context,
        title: title,
        options: options,
        selected: current,
        onSelect: onSelected,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.surfaceAlt,
          border: Border.all(color: context.hairline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $_currentLabel',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet option picker (drag handle + title + check-marked rows).
Future<void> _openFilterSheet<T>(
  BuildContext context, {
  required String title,
  required List<FilterOption<T>> options,
  required T selected,
  required ValueChanged<T> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(sheetContext).bottom,
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
              title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: options
                    .map((option) => ListTile(
                          leading: option.emoji != null
                              ? Text(option.emoji!,
                                  style: const TextStyle(fontSize: 18))
                              : null,
                          title: Text(option.label),
                          trailing: option.value == selected
                              ? Icon(Icons.check_circle,
                                  color: context.colors.primary)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            onSelect(option.value);
                          },
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _LockedChip extends StatelessWidget {
  final String label;
  const _LockedChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceAlt,
        border: Border.all(color: context.hairline.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.lock_outline, size: 12, color: context.textFaint),
        ],
      ),
    );
  }
}

List<FilterOption<String>> buildPresetFilterOptions({
  required List<StickerPreset> presets,
  required AppLocalizations l10n,
}) {
  final options = <FilterOption<String>>[
    FilterOption(value: '', label: l10n.all),
  ];
  for (final p in presets) {
    options.add(
      FilterOption(
        value: p.id,
        label: localizedPresetLabel(l10n, p),
        emoji: p.emoji,
      ),
    );
  }
  return options;
}

List<FilterOption<HistorySort>> buildSortOptions(AppLocalizations l10n) {
  return HistorySort.values
      .map((s) => FilterOption(value: s, label: sortLabel(l10n, s)))
      .toList();
}

List<FilterOption<HistoryStatusFilter>> buildStatusFilterOptions(
  AppLocalizations l10n,
) {
  return HistoryStatusFilter.values
      .map((f) => FilterOption(value: f, label: statusFilterLabel(l10n, f)))
      .toList();
}

List<FilterOption<HistoryDateFilter>> buildDateFilterOptions(
  AppLocalizations l10n,
) {
  return HistoryDateFilter.values
      .map((f) => FilterOption(value: f, label: dateFilterLabel(l10n, f)))
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
