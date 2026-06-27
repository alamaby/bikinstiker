import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/share_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sticker_generation.dart';
import '../../../data/repositories/sticker_repository.dart';
import '../../blocs/history/history_bloc.dart';
import '../../widgets/status_indicator.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // HistoryBloc lives at the app root (see app.dart) so the list and
    // signed-URL cache are retained across visits. We just kick off a
    // refresh each time the screen mounts.
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
      appBar: AppBar(title: const Text('Your stickers')),
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
          if (state.items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No stickers yet — generate your first one!'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<HistoryBloc>().add(const HistoryRefreshed()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _HistoryTile(item: state.items[i]),
            ),
          );
        },
      ),
    );
  }
}

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
    return GestureDetector(onTap: () => _openPreview(context), child: tile);
  }
}

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
    return FutureBuilder<String?>(
      future: getIt<StickerRepository>().signedUrlForPath(path!),
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
        if (!snap.hasData || snap.data == null) {
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
        return CachedNetworkImage(imageUrl: snap.data!, fit: BoxFit.cover);
      },
    );
  }
}

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
            ],
          ),
        );
      },
    );
  }
}
