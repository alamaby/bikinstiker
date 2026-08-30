import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di.dart';
import '../../../core/errors/safe_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/showcase_listing.dart';
import '../../../data/repositories/showcase_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/showcase/showcase_cubit.dart';
import 'showcase_detail_screen.dart';

/// Browse screen for the sticker pack Showcase.
class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  Map<String, ShowcasePreviewUrls> _previews = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ShowcaseCubit>().refresh();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      context.read<ShowcaseCubit>().setQuery(value);
    });
  }

  Future<void> _loadPreviews(List<ShowcaseListing> listings) async {
    // H2b: kartu milik sendiri juga butuh preview (dirender di grid).
    final ids = listings.map((l) => l.id).toList();
    if (ids.isEmpty) {
      setState(() => _previews = {});
      return;
    }
    final repo = getIt<ShowcaseRepository>();
    final previews = await repo.fetchPreviews(ids);
    if (!mounted) return;
    setState(() => _previews = previews);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.showcaseTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.showcaseSearchHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          BlocConsumer<ShowcaseCubit, ShowcaseState>(
            listenWhen: (p, n) => p.listings != n.listings,
            listener: (context, state) => _loadPreviews(state.listings),
            builder: (context, state) {
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  children: [
                    _sortChip(context, state, ShowcaseSort.trending,
                        l10n.showcaseSortTrending),
                    _sortChip(context, state, ShowcaseSort.topRated,
                        l10n.showcaseSortTopRated),
                    _sortChip(context, state, ShowcaseSort.popular,
                        l10n.showcaseSortPopular),
                    _sortChip(context, state, ShowcaseSort.newest,
                        l10n.showcaseSortNewest),
                  ],
                ),
              );
            },
          ),
          Expanded(child: _buildBody(context, l10n)),
        ],
      ),
    );
  }

  Widget _sortChip(
    BuildContext context,
    ShowcaseState state,
    ShowcaseSort sort,
    String label,
  ) {
    final selected = state.sort == sort;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) =>
            context.read<ShowcaseCubit>().setSort(sort),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<ShowcaseCubit, ShowcaseState>(
      builder: (context, state) {
        if (state.isInitial || (state.isLoading && state.listings.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == ShowcaseStatus.error &&
            state.listings.isEmpty) {
          return Center(
            child: Text(
              safeErrorMessage(l10n, state.errorMessage, fallback: l10n.error),
            ),
          );
        }
        if (state.listings.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<ShowcaseCubit>().refresh(),
            child: ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined,
                            size: 64, color: context.hairline),
                        const SizedBox(height: 16),
                        Text(l10n.showcaseEmpty,
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => context.read<ShowcaseCubit>().refresh(),
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: state.listings.length,
            itemBuilder: (context, index) {
              final listing = state.listings[index];
              return _ListingCard(
                listing: listing,
                preview: _previews[listing.id],
                onTap: () async {
                  final cubit = context.read<ShowcaseCubit>();
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        ShowcaseDetailScreen(listingId: listing.id),
                  ));
                  if (!context.mounted) return;
                  await cubit.refresh(silent: true);
                  await _loadPreviews(cubit.state.listings);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ShowcaseListing listing;
  final ShowcasePreviewUrls? preview;
  final VoidCallback onTap;

  const _ListingCard({
    required this.listing,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final url = preview?.previewUrl;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (url != null)
                    Image.network(url, fit: BoxFit.cover)
                  else
                    Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Icon(Icons.image_outlined, size: 40),
                    ),
                  if (listing.isOwned)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Chip(
                        label: Text(l10n.showcaseOwned,
                            style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            context.colors.tertiary.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.packName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      listing.sellerDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.thumb_up_outlined,
                            size: 14, color: context.hairline),
                        const SizedBox(width: 2),
                        Text('${listing.ratingCount}',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(width: 8),
                        Icon(Icons.favorite_border,
                            size: 14, color: context.hairline),
                        const SizedBox(width: 2),
                        Text('${listing.favoriteCount}',
                            style: Theme.of(context).textTheme.bodySmall),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.diamond_outlined,
                                  size: 13,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary),
                              const SizedBox(width: 2),
                              Text(
                                '${listing.priceForViewer}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
