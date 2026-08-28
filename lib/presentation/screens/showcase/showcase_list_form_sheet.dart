import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/errors/failures.dart';
import '../../../core/errors/safe_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/showcase_repository.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom sheet for listing / editing / unlisting a pack on the Showcase.
/// Caller is responsible for the Plus-tier gate. [onChanged] dipanggil setelah
/// save/unlist sukses agar caller bisa me-refresh state pack (M2).
Future<void> showShowcaseListFormSheet(
  BuildContext context, {
  required String packId,
  VoidCallback? onChanged,
}) async {
  final repo = getIt<ShowcaseRepository>();
  final existing = await repo.fetchListingForPack(packId);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ListFormSheet(
      packId: packId,
      existingListingId: existing?.listingId,
      initialPrice: existing?.priceCredits ?? 10,
      initialDescription: existing?.description ?? '',
      initialTags: existing?.tags.join(', ') ?? '',
      onChanged: onChanged,
    ),
  );
}

class _ListFormSheet extends StatefulWidget {
  final String packId;
  final String? existingListingId;
  final int initialPrice;
  final String initialDescription;
  final String initialTags;
  final VoidCallback? onChanged;

  const _ListFormSheet({
    required this.packId,
    required this.existingListingId,
    required this.initialPrice,
    required this.initialDescription,
    required this.initialTags,
    this.onChanged,
  });

  @override
  State<_ListFormSheet> createState() => _ListFormSheetState();
}

class _ListFormSheetState extends State<_ListFormSheet> {
  late int _price = widget.initialPrice.clamp(5, 100);
  late final TextEditingController _descCtrl =
      TextEditingController(text: widget.initialDescription);
  late final TextEditingController _tagsCtrl =
      TextEditingController(text: widget.initialTags);
  bool _busy = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  List<String> get _tags => _tagsCtrl.text
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existingListingId == null
                ? l10n.showcaseListTitle
                : l10n.showcaseEditTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.diamond_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.showcasePriceLabel)),
              Text('$_price',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          Slider(
            value: _price.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            label: '$_price',
            onChanged: _busy ? null : (v) => setState(() => _price = v.round()),
          ),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            maxLength: 500,
            enabled: !_busy,
            decoration:
                InputDecoration(hintText: l10n.showcaseDescriptionHint),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tagsCtrl,
            enabled: !_busy,
            decoration: InputDecoration(
              hintText: l10n.showcaseTagsHint,
              helperText: l10n.showcaseTagsHelper,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.existingListingId != null) ...[
                OutlinedButton.icon(
                  onPressed: _busy ? null : _unlist,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  icon: const Icon(Icons.storefront),
                  label: Text(l10n.showcaseUnlistShort),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.existingListingId == null
                          ? l10n.showcaseListConfirm
                          : l10n.save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(safeErrorMessage(l10n, msg))),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final repo = getIt<ShowcaseRepository>();
      if (widget.existingListingId == null) {
        await repo.createListing(
          packId: widget.packId,
          priceCredits: _price,
          description: _descCtrl.text,
          tags: _tags,
        );
      } else {
        await repo.updateListing(
          listingId: widget.existingListingId!,
          priceCredits: _price,
          description: _descCtrl.text,
          tags: _tags,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      widget.onChanged?.call();
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.showcaseListSuccess),
        backgroundColor: AppColors.success,
      ));
    } on Failure catch (f) {
      setState(() => _busy = false);
      _snack(f.message);
    } catch (e) {
      setState(() => _busy = false);
      _snack(e.toString());
    }
  }

  Future<void> _unlist() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await getIt<ShowcaseRepository>()
          .unlistListing(widget.existingListingId!);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      widget.onChanged?.call();
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.showcaseUnlisted),
      ));
    } on Failure catch (f) {
      setState(() => _busy = false);
      _snack(f.message);
    }
  }
}
