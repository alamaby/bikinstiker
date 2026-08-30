import 'package:flutter/material.dart';

import '../../../core/errors/safe_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class LegalConsentErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const LegalConsentErrorScreen({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  l10n.consentErrorTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message.isEmpty
                      ? l10n.consentErrorBody
                      : safeErrorMessage(
                          l10n,
                          message,
                          fallback: l10n.consentErrorBody,
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.textPrimary.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}