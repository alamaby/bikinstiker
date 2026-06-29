import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/sticker_pack.dart';
import '../blocs/sticker_pack/sticker_pack_bloc.dart';
import '../screens/packs/pack_create_screen.dart';

/// Modal bottom sheet that lets the user add a sticker to one of their
/// packs, or create a new pack on the fly.
class AddToPackSheet extends StatefulWidget {
  final String stickerId;

  const AddToPackSheet({super.key, required this.stickerId});

  static Future<void> show(BuildContext context, String stickerId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<StickerPackBloc>(),
        child: AddToPackSheet(stickerId: stickerId),
      ),
    );
  }

  @override
  State<AddToPackSheet> createState() => _AddToPackSheetState();
}

class _AddToPackSheetState extends State<AddToPackSheet> {
  final _emojisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Refresh packs list when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StickerPackBloc>().add(const StickerPackLoadRequested());
    });
  }

  @override
  void dispose() {
    _emojisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add to Pack',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a pack and add 1-3 emojis for WhatsApp.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emojisController,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Emojis (1-3)',
                  hintText: 'e.g., cat heart',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<StickerPackBloc, StickerPackState>(
                  builder: (context, state) {
                    if (state.status == StickerPackStatus.loading &&
                        state.packs.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final availablePacks = state.packs
                        .where((p) => p.canAddStickers)
                        .toList();

                    if (availablePacks.isEmpty) {
                      return _EmptyOrFullState(
                        isAtCapacity: state.isAtCapacity(),
                        onCreateNew: state.isAtCapacity()
                            ? null
                            : () => _createNewPack(context),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: availablePacks.length + 1,
                      itemBuilder: (context, index) {
                        if (index == availablePacks.length) {
                          return ListTile(
                            leading: const Icon(Icons.add_circle_outline),
                            title: const Text('Create new pack'),
                            onTap: state.isAtCapacity()
                                ? null
                                : () => _createNewPack(context),
                          );
                        }

                        final pack = availablePacks[index];
                        final isPending = state.isPackPending(
                          '${pack.id}:${widget.stickerId}',
                        );

                        return ListTile(
                          leading: const Icon(Icons.collections_bookmark),
                          title: Text(pack.name),
                          subtitle: Text('${pack.stickerCount}/30 stickers'),
                          trailing: isPending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          onTap: isPending
                              ? null
                              : () => _addToPack(context, pack),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToPack(BuildContext context, StickerPack pack) {
    final emojiText = _emojisController.text.trim();
    if (emojiText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one emoji'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Simple parse: take first non-whitespace character
    final emojis = <String>[];
    for (final r in emojiText.runes) {
      emojis.add(String.fromCharCode(r));
      if (emojis.length >= 3) break;
    }

    if (emojis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid emojis'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<StickerPackBloc>().add(
      StickerPackAddStickerRequested(
        packId: pack.id,
        stickerId: widget.stickerId,
        emojis: emojis,
      ),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to "${pack.name}"'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _createNewPack(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<StickerPackBloc>(),
          child: const PackCreateScreen(),
        ),
      ),
    );
  }
}

class _EmptyOrFullState extends StatelessWidget {
  final bool isAtCapacity;
  final VoidCallback? onCreateNew;

  const _EmptyOrFullState({
    required this.isAtCapacity,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAtCapacity
                  ? Icons.folder_off_outlined
                  : Icons.collections_bookmark_outlined,
              size: 64,
              color: AppColors.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isAtCapacity ? 'Pack limit reached' : 'No packs yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isAtCapacity
                  ? 'Delete a pack to create a new one.'
                  : 'Create your first pack to organize stickers.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onCreateNew != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onCreateNew,
                icon: const Icon(Icons.add),
                label: const Text('Create Pack'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
