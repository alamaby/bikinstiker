import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../core/errors/safe_error_message.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sticker_feedback.dart';
import '../../data/repositories/sticker_feedback_repository.dart';
import '../../l10n/app_localizations.dart';

class StickerFeedbackButtons extends StatefulWidget {
  final String stickerGenerationId;
  final bool compact;

  const StickerFeedbackButtons({
    super.key,
    required this.stickerGenerationId,
    this.compact = false,
  });

  @override
  State<StickerFeedbackButtons> createState() => _StickerFeedbackButtonsState();
}

class _StickerFeedbackButtonsState extends State<StickerFeedbackButtons> {
  StickerFeedbackRating? _rating;
  bool _loading = true;
  bool _submitting = false;

  StickerFeedbackRepository get _repo => getIt<StickerFeedbackRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StickerFeedbackButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stickerGenerationId != widget.stickerGenerationId) {
      _rating = null;
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final feedback = await _repo.fetch(widget.stickerGenerationId);
      if (!mounted) return;
      setState(() {
        _rating = feedback?.rating;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _submit(StickerFeedbackRating rating) async {
    if (_submitting) return;
    final previous = _rating;
    setState(() {
      _rating = rating;
      _submitting = true;
    });

    try {
      final feedback = await _repo.submit(
        stickerGenerationId: widget.stickerGenerationId,
        rating: rating,
      );
      if (!mounted) return;
      setState(() => _rating = feedback.rating);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.thanksForFeedback)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _rating = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.colors.error,
          content: Text(
            safeErrorMessage(AppLocalizations.of(context)!, 'Failed to save feedback: $e'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final children = [
      _FeedbackButton(
        label: widget.compact ? null : l10n.goodResult,
        icon: Icons.thumb_up_alt_outlined,
        selectedIcon: Icons.thumb_up_alt,
        selected: _rating == StickerFeedbackRating.up,
        enabled: !_submitting,
        onPressed: () => _submit(StickerFeedbackRating.up),
      ),
      const SizedBox(width: 8),
      _FeedbackButton(
        label: widget.compact ? null : l10n.poorResult,
        icon: Icons.thumb_down_alt_outlined,
        selectedIcon: Icons.thumb_down_alt,
        selected: _rating == StickerFeedbackRating.down,
        enabled: !_submitting,
        onPressed: () => _submit(StickerFeedbackRating.down),
      ),
    ];

    if (widget.compact) {
      return Row(mainAxisSize: MainAxisSize.min, children: children);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.rateThisResult,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(children: children),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final String? label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  const _FeedbackButton({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? Theme.of(context).colorScheme.onPrimary : context.colors.primary;
    final background = selected ? context.colors.primary : context.surfaceAlt;
    final style = OutlinedButton.styleFrom(
      foregroundColor: foreground,
      backgroundColor: background,
      side: BorderSide(color: selected ? context.colors.primary : context.hairline),
      padding: label == null
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );

    if (label == null) {
      return OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: style,
        child: Icon(selected ? selectedIcon : icon, size: 18),
      );
    }

    return Expanded(
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: style,
        icon: Icon(selected ? selectedIcon : icon, size: 18),
        label: Text(label!),
      ),
    );
  }
}
