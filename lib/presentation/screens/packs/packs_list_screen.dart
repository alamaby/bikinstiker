import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/errors/safe_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/showcase_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/sticker_pack/sticker_pack_bloc.dart';
import '../../blocs/showcase/showcase_cubit.dart';
import '../../widgets/ads_banner_widget.dart';
import '../../widgets/pack_capacity_indicator.dart';
import '../../widgets/pack_card.dart';
import '../showcase/showcase_screen.dart';
import 'pack_create_screen.dart';
import 'pack_detail_screen.dart';

/// Screen showing the user's sticker packs in a grid.
/// Includes capacity indicator, FAB to create new packs, and pull-to-refresh.
class PacksListScreen extends StatefulWidget {
  const PacksListScreen({super.key});

  @override
  State<PacksListScreen> createState() => _PacksListScreenState();
}

class _PacksListScreenState extends State<PacksListScreen> {
  Set<String> _listedPackIds = const <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshListedIds();
    });
  }

  // L9: badge "Listed" pada kartu pack yang punya listing showcase.
  Future<void> _refreshListedIds() async {
    try {
      final ids = await getIt<ShowcaseRepository>().fetchListedPackIds();
      if (!mounted) return;
      setState(() => _listedPackIds = ids);
    } catch (_) {
      // Kosmetik; abaikan kegagalan lookup.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myStickerPacks),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: l10n.showcaseTitle,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => ShowcaseCubit(
                    getIt<ShowcaseRepository>(),
                  ),
                  child: const ShowcaseScreen(),
                ),
              ));
            },
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
              return Center(
                child: Text(
                  safeErrorMessage(l10n, state.errorMessage,
                      fallback: l10n.error),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<StickerPackBloc>().add(
                  const StickerPackLoadRequested(),
                );
                await _refreshListedIds();
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
                              childAspectRatio: 0.70,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final pack = state.packs[index];
                          return PackCard(
                            pack: pack,
                            isListed:
                                _listedPackIds.contains(pack.id),
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
            label: Text(l10n.newPack),
            backgroundColor: state.isAtCapacity()
                ? context.hairline
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.collections_bookmark_outlined,
                size: 44,
                color: context.textFaint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noPacksYet,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.packOrgGuidance,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
