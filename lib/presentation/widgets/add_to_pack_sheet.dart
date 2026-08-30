import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/emoji_categories.dart';
import '../../core/constants/emoji_keywords.dart';
import '../../core/recent_emojis_service.dart';
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

class _AddToPackSheetState extends State<AddToPackSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(
    length: kEmojiCategories.length,
    vsync: this,
    initialIndex: 1, // Smileys (index 1)
  );
  final List<String> _selectedEmojis = [];
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<String> _recentEmojis = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StickerPackBloc>().add(const StickerPackLoadRequested());
    });
    _loadRecent();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await RecentEmojisService.load();
    if (!mounted) return;
    setState(() {
      _recentEmojis = recent;
    });
  }

  void _toggleEmoji(String emoji) {
    setState(() {
      if (_selectedEmojis.contains(emoji)) {
        _selectedEmojis.remove(emoji);
      } else if (_selectedEmojis.length < 3) {
        _selectedEmojis.add(emoji);
        RecentEmojisService.add(emoji);
        _loadRecent();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults =
        _searchQuery.isEmpty ? <String>[] : searchEmojis(_searchQuery);

    return FractionallySizedBox(
      heightFactor: 0.95,
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
            const SizedBox(height: 12),
            // Search bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search emojis...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => _searchCtrl.clear(),
                      ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tab bar (hidden when searching)
            if (_searchQuery.isEmpty)
              TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: context.textSecondary,
                dividerHeight: 0,
                tabs: kEmojiCategories.asMap().entries.map((entry) {
                  final cat = entry.value;
                  return Tab(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text(cat.name, style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            // Emoji count label
            Text(
              'Emojis (${_selectedEmojis.length}/3)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            // Emoji grid
            SizedBox(
              height: 200,
              child: _searchQuery.isEmpty
                  ? TabBarView(
                      controller: _tab,
                      children: _buildCategoryTabs(),
                    )
                  : _buildSearchResults(searchResults),
            ),
            // Selected chips
            if (_selectedEmojis.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _selectedEmojis.map((emoji) {
                  return Chip(
                    label: Text(emoji, style: const TextStyle(fontSize: 20)),
                    onDeleted: () => _toggleEmoji(emoji),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: context.surfaceAlt,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<StickerPackBloc, StickerPackState>(
                builder: (context, state) {
                  if (state.status == StickerPackStatus.loading &&
                      state.packs.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final availablePacks =
                      state.packs.where((p) => p.canAddStickers).toList();

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

  List<Widget> _buildCategoryTabs() {
    return kEmojiCategories.asMap().entries.map((entry) {
      final i = entry.key;
      final emojis = i == 0 ? _recentEmojis : entry.value.emojis;
      return _buildEmojiGrid(
        emojis,
        emptyText: i == 0 ? 'No recent emojis yet' : null,
      );
    }).toList();
  }

  Widget _buildSearchResults(List<String> results) {
    if (results.isEmpty) {
      return Center(
        child: Text(
          'No emojis match "$_searchQuery"',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return _buildEmojiGrid(results);
  }

  Widget _buildEmojiGrid(List<String> emojis, {String? emptyText}) {
    if (emojis.isEmpty) {
      return Center(
        child: Text(
          emptyText ?? 'No emojis',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: emojis.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (ctx, i) {
        final emoji = emojis[i];
        final selected = _selectedEmojis.contains(emoji);
        return InkWell(
          onTap: () => _toggleEmoji(emoji),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.secondary.withValues(alpha: 0.2)
                  : context.surfaceAlt,
              border: Border.all(
                color: selected ? AppColors.secondary : context.hairline,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        );
      },
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
    final newCount = pack.stickerCount + 1;
    final msg = newCount >= 3
        ? '"${pack.name}" is ready to export to WhatsApp.'
        : 'Added to "${pack.name}". Add ${3 - newCount} more sticker${3 - newCount == 1 ? '' : 's'} to export.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
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
              color: context.hairline,
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
