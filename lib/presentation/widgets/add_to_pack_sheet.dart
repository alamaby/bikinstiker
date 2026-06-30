import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/sticker_pack.dart';
import '../blocs/sticker_pack/sticker_pack_bloc.dart';
import '../screens/packs/pack_create_screen.dart';

/// Common emojis for WhatsApp sticker packs
const _kEmojiOptions = <String>[
  '😀',
  '😂',
  '😍',
  '🥰',
  '😎',
  '😭',
  '😡',
  '👍',
  '❤️',
  '🔥',
  '🎉',
  '✨',
  '🌟',
  '💯',
  '👌',
  '🙌',
  '🐱',
  '🐶',
  '🐰',
  '🐻',
  '🦁',
  '🐯',
  '🐨',
  '🐸',
  '🍕',
  '🍔',
  '🍟',
  '🌮',
  '🍣',
  '🍦',
  '🍰',
  '☕',
  '⚽',
  '🏀',
  '🏈',
  '⚾',
  '🎾',
  '🏓',
  '🏸',
  '🥊',
  '🚗',
  '✈️',
  '🚀',
  '🛸',
  '🚁',
  '🛶',
  '⛵',
  '🏍️',
  '🎮',
  '🎲',
  '🎨',
  '🎭',
  '🎪',
  '🎤',
  '🎸',
  '🎹',
  '🌈',
  '☀️',
  '🌙',
  '⭐',
  '☁️',
  '❄️',
  '🌸',
  '🌻',
  '💡',
  '💭',
  '💬',
  '💌',
  '📷',
  '📱',
  '💻',
  '🎧',
];

/// Modal bottom sheet that lets the user add a sticker to one of their
/// packs, or create a new pack on the fly.
class AddToPackSheet extends StatefulWidget {
  final String stickerId;

  const AddToPackSheet({super.key, required this.stickerId});

  static Future<void> show(BuildContext context, String stickerId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
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
  final List<String> _selectedEmojis = [];

  @override
  void initState() {
    super.initState();
    // Refresh packs list when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StickerPackBloc>().add(const StickerPackLoadRequested());
    });
  }

  void _toggleEmoji(String emoji) {
    setState(() {
      if (_selectedEmojis.contains(emoji)) {
        _selectedEmojis.remove(emoji);
      } else if (_selectedEmojis.length < 3) {
        _selectedEmojis.add(emoji);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to Pack',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a pack and select 1-3 emojis for WhatsApp.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // Emoji picker - fixed height, scrollable grid
            Text(
              'Emojis (${_selectedEmojis.length}/3)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: GridView.builder(
                itemCount: _kEmojiOptions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final emoji = _kEmojiOptions[index];
                  final selected = _selectedEmojis.contains(emoji);
                  return InkWell(
                    onTap: () => _toggleEmoji(emoji),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.secondary.withValues(alpha: 0.2)
                            : AppColors.surface,
                        border: Border.all(
                          color: selected
                              ? AppColors.secondary
                              : AppColors.outline,
                          width: selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                },
              ),
            ),
            if (_selectedEmojis.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _selectedEmojis.map((emoji) {
                  return Chip(
                    label: Text(emoji, style: const TextStyle(fontSize: 20)),
                    onDeleted: () => _toggleEmoji(emoji),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: AppColors.surface,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
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
      ),
    );
  }

  void _addToPack(BuildContext context, StickerPack pack) {
    if (_selectedEmojis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one emoji'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<StickerPackBloc>().add(
      StickerPackAddStickerRequested(
        packId: pack.id,
        stickerId: widget.stickerId,
        emojis: _selectedEmojis,
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
