import 'package:flutter/material.dart';

import '../../core/constants/prompt_suggestions.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class PromptSuggestionChip extends StatefulWidget {
  final String presetId;
  final ValueChanged<String> onSuggestionSelected;
  final bool enabled;
  final bool textOnly;
  const PromptSuggestionChip({
    super.key,
    required this.presetId,
    required this.onSuggestionSelected,
    this.enabled = true,
    this.textOnly = false,
  });

  @override
  State<PromptSuggestionChip> createState() => _PromptSuggestionChipState();
}

class _PromptSuggestionChipState extends State<PromptSuggestionChip> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = randomSuggestionFor(widget.presetId, textOnly: widget.textOnly);
  }

  void _shuffle() {
    setState(() {
      _current = randomSuggestionFor(
        widget.presetId,
        textOnly: widget.textOnly,
        avoid: _current,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 14, color: context.colors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: widget.enabled
                  ? () => widget.onSuggestionSelected(_current)
                  : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  (AppLocalizations.of(context)?.trySuggestion(_current)) ??
                      'Try: "$_current"',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: context.colors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _shuffle,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.refresh, size: 18, color: context.colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
