import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/di.dart';
import '../../../core/errors/safe_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/whatsapp_pack_exporter.dart';
import '../../../data/models/sticker_pack.dart';
import '../../../data/models/sticker_pack_item.dart';
import '../../../data/repositories/showcase_repository.dart';
import '../../../data/repositories/sticker_pack_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/sticker_pack/sticker_pack_bloc.dart';
import '../showcase/showcase_list_form_sheet.dart';

/// Screen showing a single sticker pack's details.
/// Includes pack metadata, grid of stickers, and actions (rename, delete, add sticker).
class PackDetailScreen extends StatefulWidget {
  final String packId;

  const PackDetailScreen({super.key, required this.packId});

  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  bool _isListed = false;

  @override
  void initState() {
    super.initState();
    // Load pack details when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StickerPackBloc>().add(
        StickerPackDetailLoadRequested(widget.packId),
      );
      _refreshListedState();
    });
  }

  Future<void> _refreshListedState() async {
    try {
      final ids =
          await getIt<ShowcaseRepository>().fetchListedPackIds();
      if (!mounted) return;
      setState(() => _isListed = ids.contains(widget.packId));
    } catch (_) {
      // Badge state is cosmetic; ignore lookup failures.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickerPackBloc, StickerPackState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final pack = state.selectedPack;
        final items = state.selectedPackItems;

        return Scaffold(
          appBar: AppBar(
            title: Text(pack?.name ?? l10n.pack),
            actions: [
              if (pack != null && pack.canRename)
                IconButton(
                  icon: Icon(
                    Icons.storefront_outlined,
                    color: _isListed
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: l10n.showcaseListTitle,
                  onPressed: () => _openShowcaseForm(pack),
                ),
              if (pack != null && pack.canRename)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showRenameDialog(context, pack),
                  tooltip: l10n.rename,
                ),
              if (pack != null && pack.canDelete)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteDialog(context, pack),
                  tooltip: l10n.delete,
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
                      content: Text(
                        safeErrorMessage(l10n, state.errorMessage,
                            fallback: l10n.errorOccurred),
                      ),
                      backgroundColor: context.colors.error,
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
            child: _buildBody(context, pack, items, state, l10n),
          ),
          bottomNavigationBar: pack != null
              ? _buildBottomBar(context, pack, items.length, l10n)
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
    AppLocalizations l10n,
  ) {
    if (state.detailStatus == StickerPackStatus.initial ||
        state.detailStatus == StickerPackStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.detailStatus == StickerPackStatus.error && pack == null) {
      return Center(
        child: Text(
          safeErrorMessage(l10n, state.errorMessage,
              fallback: l10n.errorLoadingPack),
        ),
      );
    }

    if (pack == null) {
      return Center(child: Text(l10n.packNotFound));
    }

if (pack.isLocked) {
      return _LockedState(pack: pack, l10n: l10n);
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
              child: _EmptyItemsState(pack: pack, l10n: l10n),
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
                    packIdentifier: pack.packIdentifier,
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
    AppLocalizations l10n,
  ) {
    final canExport = pack.canExport;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceAlt,
        border: Border(top: BorderSide(color: context.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
onPressed: canExport
                   ? () => _onExportToWhatsApp(context, pack, l10n)
                   : null,
              icon: Icon(Icons.send),
              label: Text(
                canExport
                    ? l10n.exportToWhatsApp
                    : l10n.addMoreStickers(3 - itemCount),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: canExport
                    ? context.colors.tertiary
                    : context.hairline,
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
    AppLocalizations l10n,
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
          SnackBar(
            content: Text(l10n.openingWhatsApp),
            backgroundColor: context.colors.tertiary,
          ),
        );
      case WhatsAppExportNotInstalled():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.whatsAppNotInstalled),
            backgroundColor: context.colors.error,
          ),
        );
      case WhatsAppExportError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportFailed(message)),
            backgroundColor: context.colors.error,
          ),
        );
    }
  }

  Future<void> _openShowcaseForm(StickerPack pack) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final tier = await getIt<ShowcaseRepository>().fetchViewerTier();
      if (!mounted) return;
      if (tier != 'plus') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.showcasePlusRequired),
        ));
        return;
      }
      await showShowcaseListFormSheet(context, packId: pack.id,
        onChanged: () {
          if (!mounted) return;
          // M2: refresh detail + badge setelah save/unlist sukses.
          context.read<StickerPackBloc>().add(
            StickerPackDetailLoadRequested(pack.id),
          );
          _refreshListedState();
        },
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorOccurred)),
        );
      }
    }
  }

  Future<void> _showRenameDialog(BuildContext context, StickerPack pack) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: pack.name);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.renamePack),
          content: TextField(
            controller: controller,
            maxLength: 128,
            decoration: InputDecoration(
              labelText: l10n.packName,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(dialogContext).pop(newName);
                }
              },
              child: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deletePackQuestion),
          content: Text(
            '${l10n.removeStickerQuestion} "${pack.name}"? '
            'The stickers themselves will remain in your history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
              child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.removeStickerQuestion),
          content: Text(
            '${l10n.removeStickerQuestion} "${pack.name}"? '
            'The sticker will remain in your history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
              child: Text(l10n.remove),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.collections_bookmark,
              size: 32,
              color: context.colors.primary,
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
                    l10n.addMoreStickers((3 - itemCount).clamp(0, 3)),
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
                Icon(Icons.lock, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.packLockedMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ] else if (itemCount >= 3) ...[
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.tertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: context.colors.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.packReadyCallout,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
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

class _StickerItemTile extends StatefulWidget {
  final StickerPackItem item;
  final String packIdentifier;
  final bool isPending;
  final VoidCallback? onRemove;

  const _StickerItemTile({
    required this.item,
    required this.packIdentifier,
    required this.isPending,
    this.onRemove,
  });

  @override
  State<_StickerItemTile> createState() => _StickerItemTileState();
}

class _StickerItemTileState extends State<_StickerItemTile> {
  File? _cachedFile;

  @override
  void initState() {
    super.initState();
    _loadCachedFile();
  }

  @override
  void didUpdateWidget(covariant _StickerItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.stickerGenerationId != widget.item.stickerGenerationId ||
        oldWidget.packIdentifier != widget.packIdentifier) {
      _cachedFile = null;
      _loadCachedFile();
    }
  }

  Future<void> _loadCachedFile() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(
      '${dir.path}/pack_stickers_v2/${widget.packIdentifier}/${widget.item.stickerGenerationId}.webp',
    );
    if (!mounted) return;
    setState(() {
      _cachedFile = file.existsSync() ? file : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: context.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _cachedFile != null
                  ? Image.file(
                      _cachedFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(context),
                    )
                  : widget.item.stickerSignedUrl != null
                  ? Image.network(
                      widget.item.stickerSignedUrl!,
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
        if (widget.isPending)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: context.textSecondary,
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
        if (widget.onRemove != null && !widget.isPending)
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              icon: const Icon(Icons.close, size: 16),
              onPressed: widget.onRemove,
              style: IconButton.styleFrom(
                backgroundColor: context.textSecondary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        // Emoji badge bottom-left
        if (widget.item.emojis.isNotEmpty)
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: context.textSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.item.emojis.join(' '),
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
              color: context.textSecondary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${widget.item.position}',
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
            widget.item.emojis.isNotEmpty ? widget.item.emojis.join(' ') : '🎨',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            '#${widget.item.position}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  final StickerPack pack;
  final AppLocalizations l10n;

  const _EmptyItemsState({required this.pack, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 64, color: context.hairline),
            const SizedBox(height: 16),
            Text(
              l10n.packNoStickersYet,
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
  final AppLocalizations l10n;

  const _LockedState({required this.pack, required this.l10n});

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
            Text(l10n.packLockedMessage, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.packLockedMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
