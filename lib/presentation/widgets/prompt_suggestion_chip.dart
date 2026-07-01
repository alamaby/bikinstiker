import 'package:flutter/material.dart';

import '../../core/constants/prompt_suggestions.dart';
import '../../core/theme/app_theme.dart';

class PromptSuggestionChip extends StatefulWidget {
  final String presetId;
  final ValueChanged<String> onSuggestionSelected;
  final bool enabled;
  const PromptSuggestionChip({
    super.key,
    required this.presetId,
    required this.onSuggestionSelected,
    this.enabled = true,
  });

  @override
  State<PromptSuggestionChip> createState() => _PromptSuggestionChipState();
}

class _PromptSuggestionChipState extends State<PromptSuggestionChip> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = randomSuggestionFor(widget.presetId);
  }

  void _shuffle() {
    setState(() {
      _current = randomSuggestionFor(widget.presetId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: widget.enabled
                  ? () => widget.onSuggestionSelected(_current)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Try: "$_current"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primary,
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
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.refresh, size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
