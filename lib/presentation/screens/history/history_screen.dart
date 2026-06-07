import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sticker_generation.dart';
import '../../../data/repositories/sticker_repository.dart';
import '../../blocs/history/history_bloc.dart';
import '../../widgets/status_indicator.dart';

class HistoryScreen extends StatelessWidget {
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
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(state.errorMessage ?? 'Failed to load',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ]),
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
            onRefresh: () async => context.read<HistoryBloc>().add(const HistoryRefreshed()),
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
      case StickerStatus.success: return StatusIndicator.success('Success');
      case StickerStatus.pending: return StatusIndicator.pending('Pending');
      case StickerStatus.failed:  return StatusIndicator.error('Failed');
      case StickerStatus.unknown: return StatusIndicator.pending('Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd().add_jm();
    return Card(
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
                  Text(item.userPrompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${item.presetName} • ${df.format(item.createdAt.toLocal())}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 8),
                  _statusFor(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.black38),
      );
    }
    return FutureBuilder<String?>(
      future: getIt<StickerRepository>().signedUrlForPath(path!),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return Container(
            color: AppColors.surface,
            child: const Center(
              child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        return CachedNetworkImage(imageUrl: snap.data!, fit: BoxFit.cover);
      },
    );
  }
}
