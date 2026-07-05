import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../blocs/sticker_pack/sticker_pack_bloc.dart';
import '../../widgets/ads_banner_widget.dart';
import '../../widgets/pack_capacity_indicator.dart';
import '../../widgets/pack_card.dart';
import 'pack_create_screen.dart';
import 'pack_detail_screen.dart';

/// Screen showing the user's sticker packs in a grid.
/// Includes capacity indicator, FAB to create new packs, and pull-to-refresh.
class PacksListScreen extends StatelessWidget {
  const PacksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Sticker Packs')),
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
        child: BlocBuilder<StickerPackBloc, StickerPackState>(
          builder: (context, state) {
            if (state.status == StickerPackStatus.initial) {
              context.read<StickerPackBloc>().add(
                const StickerPackLoadRequested(),
              );
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == StickerPackStatus.loading &&
                state.packs.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == StickerPackStatus.error &&
                state.packs.isEmpty) {
              return Center(child: Text(state.errorMessage ?? 'Error'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<StickerPackBloc>().add(
                  const StickerPackLoadRequested(),
                );
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          PackCapacityIndicator(
                            activeCount: state.activeCount,
                            slotCap: state.slotCap,
                          ),
                          const SizedBox(height: 12),
                          const AdsBannerWidget(location: AdBannerLocation.packs),
                        ],
                      ),
                    ),
                  ),
                  if (state.packs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(isAtCapacity: state.isAtCapacity()),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final pack = state.packs[index];
                          return PackCard(
                            pack: pack,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<StickerPackBloc>(),
                                    child: PackDetailScreen(packId: pack.id),
                                  ),
                                ),
                              );
                            },
                          );
                        }, childCount: state.packs.length),
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<StickerPackBloc, StickerPackState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            onPressed: state.isAtCapacity()
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<StickerPackBloc>(),
                          child: const PackCreateScreen(),
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.add),
            label: const Text('New Pack'),
            backgroundColor: state.isAtCapacity()
                ? AppColors.outline
                : AppColors.secondary,
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isAtCapacity;

  const _EmptyState({required this.isAtCapacity});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: AppColors.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No packs yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a pack to organize your stickers for WhatsApp import.\nYou need at least 3 stickers to import a pack.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
