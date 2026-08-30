import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/safe_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/supabase_client.dart';
import '../../../data/models/showcase_listing.dart';
import '../../../data/repositories/showcase_repository.dart';
import '../../../data/repositories/wallet_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../packs/pack_detail_screen.dart';

/// Detail page of a showcase listing: sticker previews, metadata,
/// rating/favorite/report actions, and the purchase flow.
class ShowcaseDetailScreen extends StatefulWidget {
  final String listingId;

  const ShowcaseDetailScreen({super.key, required this.listingId});

  @override
  State<ShowcaseDetailScreen> createState() => _ShowcaseDetailScreenState();
}

class _ShowcaseDetailScreenState extends State<ShowcaseDetailScreen> {
  ShowcaseDetail? _detail;
  Map<int, String?> _itemUrls = {};
  String? _trayUrl;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = getIt<ShowcaseRepository>();
      final detail = await repo.fetchDetail(widget.listingId);
      // H2a: own listing juga butuh preview URLs — seller melihat
      // konten listingnya sendiri di layar detail.
      final previews =
          await repo.fetchPreviews([widget.listingId], includeItems: true);
      final urls = previews[widget.listingId];
      // Items are returned ordered by position; map by index.
      final mapped = <int, String?>{};
      for (var i = 0; i < detail.items.length; i++) {
        mapped[detail.items[i].position] =
            (i < (urls?.items?.length ?? 0)) ? urls!.items![i] : null;
      }
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _itemUrls = mapped;
        _trayUrl = urls?.trayUrl ?? urls?.previewUrl;
        _loading = false;
      });
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() {
        _error = f.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_detail?.packName ?? l10n.showcaseTitle),
        actions: [
          if (!_loading && _error == null && !_detail!.isOwn) ...[
            IconButton(
              icon: Icon(
                _detail!.viewerFavorited
                    ? Icons.favorite
                    : Icons.favorite_border,
                color:
                    _detail!.viewerFavorited ? AppColors.error : null,
              ),
              onPressed: _busy ? null : _toggleFavorite,
            ),
            IconButton(
              icon: Icon(
                Icons.thumb_up,
                color: _detail!.viewerRated
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: _busy ? null : _toggleRating,
            ),
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: l10n.showcaseReport,
              onPressed: _busy ? null : () => _showReportSheet(),
            ),
          ],
        ],
      ),
      body: _buildBody(context, l10n),
      bottomNavigationBar:
          (!_loading && _error == null) ? _buildBottom(l10n) : null,
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Text(
          safeErrorMessage(l10n, _error, fallback: l10n.error),
        ),
      );
    }
    final d = _detail!;
    final urls = [
      for (final item in d.items) _itemUrls[item.position],
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 280,
            child: urls.whereType<String>().isNotEmpty
                ? PageView.builder(
                    itemCount: urls.length,
                    itemBuilder: (context, i) {
                      final u = urls[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: u != null
                              ? Image.network(u, fit: BoxFit.contain)
                              : Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.image_outlined),
                                ),
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_trayUrl != null)
                          Image.network(_trayUrl!, height: 96)
                        else
                          const Icon(Icons.inventory_2_outlined, size: 64),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(d.packName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(l10n.showcaseBySeller(d.sellerDisplayName),
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined,
                  size: 16, color: context.hairline),
              const SizedBox(width: 4),
              Text('${d.ratingCount}'),
              const SizedBox(width: 12),
              Icon(Icons.favorite_border,
                  size: 16, color: context.hairline),
              const SizedBox(width: 4),
              Text('${d.favoriteCount}'),
              const SizedBox(width: 12),
              Icon(Icons.download_outlined,
                  size: 16, color: context.hairline),
              const SizedBox(width: 4),
              Text('${d.purchaseCount}'),
              const Spacer(),
              Text(l10n.showcaseStickerCount(d.stickerCount),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          if (d.description != null && d.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(d.description!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (d.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tag in d.tags)
                  Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottom(AppLocalizations l10n) {
    final d = _detail!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : _bottomContent(d, l10n),
      ),
    );
  }

  Widget _bottomContent(ShowcaseDetail d, AppLocalizations l10n) {
    if (d.isOwn) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _unlist,
              icon: const Icon(Icons.storefront),
              label: Text(l10n.showcaseUnlist),
            ),
          ),
        ],
      );
    }
    if (d.ownedPackId != null) {
      return FilledButton.icon(
        onPressed: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => PackDetailScreen(packId: d.ownedPackId!),
          ));
        },
        icon: const Icon(Icons.collections_bookmark),
        label: Text(l10n.showcaseOpenOwnedPack),
      );
    }
    return FilledButton.icon(
      onPressed: _showBuyDialog,
      icon: const Icon(Icons.diamond_outlined),
      label: Text(l10n.showcaseBuyFor(d.priceForViewer)),
    );
  }

  // ------------------- actions -------------------

  Future<int?> _fetchBalance() async {
    try {
      final uid = SupabaseBootstrap.client.auth.currentUser?.id;
      if (uid == null) return null;
      final wallet = await getIt<WalletRepository>().fetchBalance(uid);
      return wallet?.balance;
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleRating() async {
    setState(() => _busy = true);
    try {
      final res = await getIt<ShowcaseRepository>().toggleRating(
        widget.listingId,
      );
      setState(() {
        _detail = _copyWithCounts(rated: res.active, ratingCount: res.count);
        _busy = false;
      });
    } on Failure catch (f) {
      setState(() => _busy = false);
      _snack(f.message);
    } catch (e) {
      setState(() => _busy = false);
      _snack(e.toString());
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _busy = true);
    try {
      final res = await getIt<ShowcaseRepository>().toggleFavorite(
        widget.listingId,
      );
      setState(() {
        _detail = _copyWithCounts(
            favorited: res.favorited, favoriteCount: res.count);
        _busy = false;
      });
    } on Failure catch (f) {
      setState(() => _busy = false);
      _snack(f.message);
    } catch (e) {
      setState(() => _busy = false);
      _snack(e.toString());
    }
  }

  ShowcaseDetail _copyWithCounts({
    bool? rated,
    int? ratingCount,
    bool? favorited,
    int? favoriteCount,
  }) {
    final d = _detail!;
    return ShowcaseDetail(
      listingId: d.listingId,
      packName: d.packName,
      description: d.description,
      tags: d.tags,
      basePrice: d.basePrice,
      viewerTier: d.viewerTier,
      priceForViewer: d.priceForViewer,
      stickerCount: d.stickerCount,
      trayIconPath: d.trayIconPath,
      previewImagePath: d.previewImagePath,
      sellerDisplayName: d.sellerDisplayName,
      isOwn: d.isOwn,
      ownedPackId: d.ownedPackId,
      ratingCount: ratingCount ?? d.ratingCount,
      favoriteCount: favoriteCount ?? d.favoriteCount,
      purchaseCount: d.purchaseCount,
      viewerRated: rated ?? d.viewerRated,
      viewerFavorited: favorited ?? d.viewerFavorited,
      items: d.items,
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(safeErrorMessage(l10n, message))),
    );
  }

  Future<void> _unlist() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.showcaseUnlist),
        content: Text(l10n.showcaseUnlistConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await getIt<ShowcaseRepository>().unlistListing(widget.listingId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Failure catch (f) {
      _snack(f.message);
    }
  }

  Future<void> _showReportSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final reasons = <String, String>{
      'copyright': l10n.showcaseReasonCopyright,
      'inappropriate': l10n.showcaseReasonInappropriate,
      'spam': l10n.showcaseReasonSpam,
      'other': l10n.showcaseReasonOther,
    };
    var selected = 'copyright';
    final noteCtrl = TextEditingController();

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.showcaseReport,
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: selected,
                onChanged: (v) => setSheet(() => selected = v!),
                child: Column(
                  children: [
                    for (final entry in reasons.entries)
                      RadioListTile<String>(
                        value: entry.key,
                        title: Text(entry.value),
                        dense: true,
                      ),
                  ],
                ),
              ),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                maxLength: 500,
                decoration:
                    InputDecoration(hintText: l10n.showcaseReportNoteHint),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.send),
              ),
            ],
          ),
        ),
      ),
    );

    if (sent != true || !mounted) return;
    try {
      await getIt<ShowcaseRepository>().reportListing(
        listingId: widget.listingId,
        reason: selected,
        note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
      );
      _snack(l10n.showcaseReportSent);
    } on Failure catch (f) {
      _snack(f.message);
    }
  }

  Future<void> _showBuyDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final d = _detail!;
    final balance = await _fetchBalance();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.showcaseConfirmTitle),
        content: Text(
          balance != null && balance < d.priceForViewer
              ? l10n.showcaseNotEnoughCredits(d.priceForViewer, balance)
              : l10n.showcaseConfirmBody(
                  d.priceForViewer,
                  d.viewerTier == 'plus'
                      ? l10n.tierPlus
                      : l10n.tierFree,
                  (balance != null ? balance - d.priceForViewer : balance) ??
                      0,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          if (balance == null || balance >= d.priceForViewer)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.confirm),
            ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _purchase();
  }

  Future<void> _purchase() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final outcome = await getIt<ShowcaseRepository>()
          .purchase(widget.listingId);
      if (!mounted) return;
      setState(() => _busy = false);
      if (outcome.completed && outcome.packId != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.showcasePurchaseSuccess),
          backgroundColor: AppColors.success,
        ));
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => PackDetailScreen(packId: outcome.packId!),
        ));
      } else if (outcome.refunded) {
        _snack(l10n.showcasePurchaseRefunded);
      } else {
        _snack(l10n.showcasePurchasePendingRetry);
      }
    } on PackSlotLimitFailure {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(l10n.packLimitReachedDesc);
    } on InsufficientCreditsFailure {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(l10n.notEnoughCredits);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(f.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(e.toString());
    }
  }
}
