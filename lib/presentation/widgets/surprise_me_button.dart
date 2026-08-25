import 'package:flutter/material.dart';

import '../../core/constants/prompt_suggestions.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class SurpriseMeButton extends StatelessWidget {
  final String presetId;
  final ValueChanged<String> onPressed;
  final bool enabled;
  final bool textOnly;

  /// Current suggestion/text to exclude from the random pick so consecutive
  /// taps never produce the same value.
  final String? avoid;
  const SurpriseMeButton({
    super.key,
    required this.presetId,
    required this.onPressed,
    this.enabled = true,
    this.textOnly = false,
    this.avoid,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: enabled
              ? () => onPressed(
                  randomSuggestionFor(
                    presetId,
                    textOnly: textOnly,
                    avoid: avoid,
                  ),
                )
              : null,
          icon: const Icon(Icons.casino, size: 18),
          label: Text(l10n?.surpriseMe ?? 'Surprise me'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
    );
  }
}
