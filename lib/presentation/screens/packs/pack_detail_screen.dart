import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/whatsapp_pack_exporter.dart';
import '../../../data/models/sticker_pack.dart';
import '../../../data/models/sticker_pack_item.dart';
import '../../../data/repositories/sticker_pack_repository.dart';
import '../../blocs/sticker_pack/sticker_pack_bloc.dart';

/// Screen showing a single sticker pack's details.
/// Includes pack metadata, grid of stickers, and actions (rename, delete, add sticker).
class PackDetailScreen extends StatefulWidget {
  final String packId;

  const PackDetailScreen({super.key, required this.packId});

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load pack details when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StickerPackBloc>().add(
        StickerPackDetailLoadRequested(widget.packId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickerPackBloc, StickerPackState>(
      builder: (context, state) {
        final pack = state.selectedPack;
        final items = state.selectedPackItems;

        return Scaffold(
          appBar: AppBar(
            title: Text(pack?.name ?? 'Pack'),
            actions: [
              if (pack != null && pack.canRename)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showRenameDialog(context, pack),
                  tooltip: 'Rename',
                ),
              if (pack != null && pack.canDelete)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(context, pack),
                  tooltip: 'Delete',
                ),
            ],
          ),
          body: MultiBlocListener(
            listeners: [
              BlocListener<StickerPackBloc, StickerPackState>(
                listenWhen: (p, n) =>
                    p.errorMessage != n.errorMessage && n.errorMessage != null,
                listener: (context, state) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage ?? 'An error occurred'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  Future.delayed(const Duration(seconds: 3), () {
                    if (context.mounted) {
                      context.read<StickerPackBloc>().add(
                        const StickerPackErrorCleared(),
                      );
                    }
                  });
                },
              ),
            ],
            child: _buildBody(context, pack, items, state),
          ),
          bottomNavigationBar: pack != null
              ? _buildBottomBar(context, pack, items.length)
              : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    StickerPack? pack,
    List<StickerPackItem> items,
    StickerPackState state,
  ) {
    if (state.detailStatus == StickerPackStatus.initial ||
        state.detailStatus == StickerPackStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.detailStatus == StickerPackStatus.error && pack == null) {
      return Center(child: Text(state.errorMessage ?? 'Error loading pack'));
    }

    if (pack == null) {
      return const Center(child: Text('Pack not found'));
    }

    if (pack.isLocked) {
      return _LockedState(pack: pack);
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<StickerPackBloc>().add(
          StickerPackDetailLoadRequested(widget.packId),
        );
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _PackHeader(pack: pack, itemCount: items.length),
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyItemsState(pack: pack),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  final isPending = state.isPackPending(
                    '${pack.id}:${item.stickerGenerationId}',
                  );
                  return _StickerItemTile(
                    item: item,
                    isPending: isPending,
                    onRemove: pack.canRemoveStickers
                        ? () => _showRemoveStickerDialog(
                            context,
                            pack,
                            item.stickerGenerationId,
                          )
                        : null,
                  );
                }, childCount: items.length),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    StickerPack pack,
    int itemCount,
  ) {
    final canExport = pack.canExport;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canExport
                  ? () => _onExportToWhatsApp(context, pack)
                  : null,
              icon: const Icon(Icons.send),
              label: Text(
                canExport
                    ? 'Export to WhatsApp'
                    : 'Add ${3 - itemCount} more stickers',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canExport
                    ? AppColors.success
                    : AppColors.outline,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onExportToWhatsApp(
    BuildContext context,
    StickerPack pack,
  ) async {
    final items = context.read<StickerPackBloc>().state.selectedPackItems;
    final exporter = WhatsAppPackExporter();

    // Show loading overlay
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await exporter.exportPack(
      pack: pack,
      items: items,
      prepareFn: (packId, packItems) async {
        final repo = getIt<StickerPackRepository>();
        return repo.preparePackForExport(
          packId: packId,
          packIdentifier: pack.packIdentifier,
          items: packItems,
        );
      },
    );

    // Dismiss loading overlay
    if (context.mounted) Navigator.of(context).pop();

    if (!context.mounted) return;

    switch (result) {
      case WhatsAppExportSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening WhatsApp...'),
            backgroundColor: AppColors.success,
          ),
        );
      case WhatsAppExportNotInstalled():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'WhatsApp is not installed. Please install WhatsApp first.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      case WhatsAppExportError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $message'),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  Future<void> _showRenameDialog(BuildContext context, StickerPack pack) async {
    final controller = TextEditingController(text: pack.name);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Pack'),
          content: TextField(
            controller: controller,
            maxLength: 128,
            decoration: const InputDecoration(
              labelText: 'Pack name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(dialogContext).pop(newName);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && context.mounted) {
      context.read<StickerPackBloc>().add(
        StickerPackRenameRequested(pack.id, result),
      );
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, StickerPack pack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Pack?'),
          content: Text(
            'Are you sure you want to delete "${pack.name}"? '
            'The stickers themselves will remain in your history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<StickerPackBloc>().add(StickerPackDeleteRequested(pack.id));
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showRemoveStickerDialog(
    BuildContext context,
    StickerPack pack,
    String stickerGenerationId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Sticker?'),
          content: Text(
            'Remove this sticker from "${pack.name}"? '
            'The sticker will remain in your history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<StickerPackBloc>().add(
        StickerPackRemoveStickerRequested(pack.id, stickerGenerationId),
      );
    }
  }
}

class _PackHeader extends StatelessWidget {
  final StickerPack pack;
  final int itemCount;

  const _PackHeader({required this.pack, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.collections_bookmark,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$itemCount of 30 stickers',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (pack.isLocked) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This pack is locked due to a tier change. '
                    'Upgrade to Plus to unlock all packs.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StickerItemTile extends StatelessWidget {
  final StickerPackItem item;
  final bool isPending;
  final VoidCallback? onRemove;

  const _StickerItemTile({
    required this.item,
    required this.isPending,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.stickerSignedUrl != null
                  ? Image.network(
                      item.stickerSignedUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(context),
                    )
                  : _placeholder(context),
            ),
          ),
        ),
        if (isPending)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        if (onRemove != null && !isPending)
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: const Icon(Icons.close, size: 16),
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        // Emoji badge bottom-left
        if (item.emojis.isNotEmpty)
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.emojis.join(' '),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        // Position badge top-left
        Positioned(
          top: 2,
          left: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${item.position}',
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.emojis.isNotEmpty ? item.emojis.join(' ') : '🎨',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            '#${item.position}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  final StickerPack pack;

  const _EmptyItemsState({required this.pack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 64, color: AppColors.outline),
            const SizedBox(height: 16),
            Text(
              'No stickers yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Generate stickers and add them to this pack from the result panel or history.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedState extends StatelessWidget {
  final StickerPack pack;

  const _LockedState({required this.pack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: AppColors.warning),
            const SizedBox(height: 16),
            Text('Pack locked', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'This pack was locked because your tier changed. '
              'Upgrade to Plus to unlock all your packs.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
