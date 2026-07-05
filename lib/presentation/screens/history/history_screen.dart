import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/share_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sticker_generation.dart';
import '../../../data/models/sticker_preset.dart';
import '../../../data/repositories/sticker_repository.dart';
import '../../blocs/history/history_bloc.dart';
import '../../blocs/home_prefill/home_prefill_cubit.dart';
import '../../blocs/preset/preset_bloc.dart';
import '../../blocs/subscription/subscription_bloc.dart';
import '../../widgets/add_to_pack_sheet.dart';
import '../../widgets/ads_banner_widget.dart';
import '../../widgets/status_indicator.dart';
import 'widgets/history_filter_chips.dart';
import 'widgets/history_search_field.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return const _HistoryView();
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your stickers'),
        actions: [
          BlocBuilder<HistoryBloc, HistoryBlocState>(
            builder: (context, state) {
              if (!state.hasActiveFilters) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  context.read<HistoryBloc>().add(const HistoryFiltersCleared());
                },
                child: const Text('Clear'),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<HistoryBloc, HistoryBlocState>(
        builder: (context, state) {
          if (state.status == HistoryStatus.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HistoryStatus.failure && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        state.errorMessage ?? 'Failed to load',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              _FilterBar(state: state),
              const SizedBox(height: 8),
              const AdsBannerWidget(location: AdBannerLocation.history),
              const SizedBox(height: 8),
              Expanded(
                child: state.items.isEmpty
                    ? _EmptyState(hasActiveFilters: state.hasActiveFilters)
                    : RefreshIndicator(
                        onRefresh: () async => context
                            .read<HistoryBloc>()
                            .add(const HistoryRefreshed()),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.items.length,
                          separatorBuilder: (_, i) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _HistoryTile(item: state.items[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  final HistoryBlocState state;
  const _FilterBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final isPlus = context.read<SubscriptionBloc>().state.isPlus;
    final presets = context.watch<PresetBloc>().state.presets;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              FilterChipDropdown<HistoryStatusFilter>(
                label: 'Status',
                value: state.statusFilter.label,
                items: buildStatusFilterItems(),
                onSelected: (f) => context
                    .read<HistoryBloc>()
                    .add(HistoryStatusFilterChanged(f)),
              ),
              const SizedBox(width: 8),
              FilterChipDropdown<String>(
                label: 'Preset',
                value: _presetLabel(state.presetFilter, presets),
                items: buildPresetFilterItems(presets: presets),
                onSelected: (id) => context.read<HistoryBloc>().add(
                      HistoryPresetFilterChanged(id.isEmpty ? null : id),
                    ),
              ),
              const SizedBox(width: 8),
              FilterChipDropdown<HistoryDateFilter>(
                label: 'Date',
                value: state.dateFilter.label,
                items: buildDateFilterItems(),
                onSelected: isPlus
                    ? (f) => context
                        .read<HistoryBloc>()
                        .add(HistoryDateFilterChanged(f))
                    : (_) => _showPlusOnlySnackBar(context, 'Date filter'),
                locked: !isPlus,
              ),
              const Spacer(),
              PopupMenuButton<HistorySort>(
                onSelected: (s) => context
                    .read<HistoryBloc>()
                    .add(HistorySortChanged(s)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                itemBuilder: (_) => buildSortItems(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.sort.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HistorySearchField(
            enabled: state.status != HistoryStatus.loading,
            locked: !isPlus,
            onChanged: (q) =>
                context.read<HistoryBloc>().add(HistorySearchChanged(q)),
          ),
        ],
      ),
    );
  }

  String _presetLabel(String? presetId, List<StickerPreset> presets) {
    if (presetId == null || presetId.isEmpty) return 'All';
    try {
      return presets.firstWhere((p) => p.id == presetId).label;
    } catch (_) {
      return presetId;
    }
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool hasActiveFilters;
  const _EmptyState({required this.hasActiveFilters});

  @override
  Widget build(BuildContext context) {
    if (hasActiveFilters) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list_off,
                size: 40,
                color: Colors.black38,
              ),
              const SizedBox(height: 12),
              const Text(
                'No stickers match your filters',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () {
                  context
                      .read<HistoryBloc>()
                      .add(const HistoryFiltersCleared());
                },
                child: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No stickers yet — generate your first one!'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History tile (unchanged except uses state.items)
// ---------------------------------------------------------------------------

class _HistoryTile extends StatelessWidget {
  final StickerGeneration item;
  const _HistoryTile({required this.item});

  Widget _statusFor() {
    switch (item.status) {
      case StickerStatus.success:
        return StatusIndicator.success('Success');
      case StickerStatus.pending:
        return StatusIndicator.pending('Pending');
      case StickerStatus.failed:
        return StatusIndicator.error('Failed');
      case StickerStatus.unknown:
        return StatusIndicator.pending('Unknown');
    }
  }

  bool get _canOpen =>
      item.status == StickerStatus.success &&
      item.imageUrl != null &&
      item.imageUrl!.isNotEmpty;

  void _openPreview(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _StickerPreviewSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();
    final tile = Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _Thumb(path: item.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.userPrompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.presetName} • ${df.format(item.createdAt.toLocal())}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  _statusFor(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!_canOpen) return tile;
    return GestureDetector(
      onTap: () => _openPreview(context),
      onLongPress: () => _showContextMenu(context),
      child: tile,
    );
  }

  void _showContextMenu(BuildContext context) {
    final isPlus = context.read<SubscriptionBloc>().state.isPlus;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.replay,
                color: isPlus ? AppColors.primary : Colors.black38,
              ),
              title: Text(
                'Regenerate with same prompt',
                style: TextStyle(
                  color: isPlus ? null : Colors.black54,
                  fontWeight: isPlus ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              subtitle: isPlus
                  ? null
                  : const Text('Plus only',
                      style: TextStyle(fontSize: 12)),
              trailing: isPlus
                  ? null
                  : const Icon(Icons.lock_outline,
                      size: 16, color: Colors.black38),
              onTap: isPlus
                  ? () {
                      Navigator.of(sheetCtx).pop();
                      _regenerate(context);
                    }
                  : () {
                      Navigator.of(sheetCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Regenerate is a Plus feature'),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _regenerate(BuildContext context) {
    context.read<HomePrefillCubit>().set(
          presetId: item.presetName,
          prompt: item.userPrompt,
        );
    Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------------------
// Thumbnail (local file cache)
// ---------------------------------------------------------------------------

class _Thumb extends StatelessWidget {
  final String? path;
  const _Thumb({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return Container(
        color: AppColors.surface,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.black38,
        ),
      );
    }
    return FutureBuilder<File?>(
      future: getIt<StickerRepository>().getCachedImageFile(path!),
      builder: (context, snap) {
        if (snap.hasError) {
          return Container(
            color: AppColors.surface,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.error,
            ),
          );
        }
        final file = snap.data;
        if (file == null) {
          return Container(
            color: AppColors.surface,
            child: const Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return Image.file(file, fit: BoxFit.cover);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sticker preview sheet
// ---------------------------------------------------------------------------

class _StickerPreviewSheet extends StatelessWidget {
  final StickerGeneration item;
  const _StickerPreviewSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _Thumb(path: item.imageUrl),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.userPrompt,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.presetName} • ${df.format(item.createdAt.toLocal())}',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    final repo = getIt<StickerRepository>();
                    final signedUrl = await repo.signedUrlForPath(
                      item.imageUrl!,
                    );
                    if (signedUrl == null || !context.mounted) return;
                    await shareStickerImage(signedUrl);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text(
                          'Failed to share sticker: $e',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).pop();
                  AddToPackSheet.show(context, item.id);
                },
                icon: const Icon(Icons.collections_bookmark),
                label: const Text('Add to Pack'),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _showPlusOnlySnackBar(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature is a Plus feature')),
  );
}
