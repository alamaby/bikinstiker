import 'package:flutter/material.dart';

import '../../core/constants/prompt_suggestions.dart';
import '../../core/theme/app_theme.dart';

class SurpriseMeButton extends StatelessWidget {
  final String presetId;
  final ValueChanged<String> onPressed;
  final bool enabled;
  const SurpriseMeButton({
    super.key,
    required this.presetId,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: enabled
              ? () => onPressed(randomSuggestionFor(presetId))
              : null,
          icon: const Icon(Icons.casino, size: 18),
          label: const Text('Surprise me'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ),
    );
  }
}
