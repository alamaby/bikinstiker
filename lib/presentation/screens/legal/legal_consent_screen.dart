import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_consent_repository.dart';
import '../../../l10n/app_localizations.dart';

/// Renders Terms + Privacy and records acceptance server-side. The exact
/// localized documents are loaded from assets, hashed, and compared against
/// the current registry so the user only ever accepts what the registry
/// actually contained.
class LegalConsentScreen extends StatefulWidget {
  final LegalConsentStatus status;
  final bool submitting;
  final Future<void> Function({
    required String termsSha256,
    required String privacySha256,
  }) onAccept;

  const LegalConsentScreen({
    super.key,
    required this.status,
    required this.submitting,
    required this.onAccept,
  });

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  bool _accepted = false;
  String _privacyMarkdown = '';
  String _termsMarkdown = '';
  bool _loading = true;
  String? _loadError;
  int _loadGeneration = 0;
  String? _loadedSuffix;

  String get _docSuffix {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'id' ? 'id' : 'en';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final suffix = _docSuffix;
    if (_loadedSuffix != suffix) {
      _loadedSuffix = suffix;
      _loadDocuments(suffix);
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments(String suffix) async {
    final generation = ++_loadGeneration;
    try {
      final results = await Future.wait([
        rootBundle.loadString('docs/privacy-policy-$suffix.md'),
        rootBundle.loadString('docs/terms-of-service-$suffix.md'),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      final privacySha = _sha256(results[0]);
      final termsSha = _sha256(results[1]);
      setState(() {
        _privacyMarkdown = results[0];
        _termsMarkdown = results[1];
        _privacyHash = privacySha;
        _termsHash = termsSha;
        _privacyMismatch = privacySha != widget.status.privacy.sha256;
        _termsMismatch = termsSha != widget.status.terms.sha256;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _loadError = 'load';
      });
    }
  }

  String _sha256(String source) =>
      sha256.convert(utf8.encode(source)).toString();

  String _privacyHash = '';
  String _termsHash = '';
  bool _privacyMismatch = false;
  bool _termsMismatch = false;

  Future<void> _onContinue() async {
    if (!_accepted || widget.submitting) return;
    if (_privacyMismatch || _termsMismatch) return;
    await widget.onAccept(
      termsSha256: _termsHash,
      privacySha256: _privacyHash,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
                    child: Text(
                      'BikinStiker',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      l10n.legalTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tab,
                    indicatorColor: context.colors.primary,
                    labelColor: context.colors.primary,
                    unselectedLabelColor: context.textSecondary,
                    dividerHeight: 0,
                    tabs: [
                      Tab(text: l10n.privacyPolicy),
                      Tab(text: l10n.termsOfService),
                    ],
                  ),
                  Expanded(child: _buildContent(l10n)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: (v) =>
                            setState(() => _accepted = v ?? false),
                        activeColor: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.legalConsentText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed:
                        _accepted && !widget.submitting && !_privacyMismatch &&
                                !_termsMismatch
                            ? _onContinue
                            : null,
                    child: widget.submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.continueLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _message(l10n, l10n.consentErrorBody, showRetry: true);
    }
    if (_privacyMismatch || _termsMismatch) {
      return _message(l10n, l10n.consentDocsChanged, showRetry: true);
    }
    return TabBarView(
      controller: _tab,
      children: [
        _MarkdownDoc(markdown: _privacyMarkdown),
        _MarkdownDoc(markdown: _termsMarkdown),
      ],
    );
  }

  Widget _message(AppLocalizations l10n, String body, {required bool showRetry}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: context.colors.error),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textPrimary.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 16),
            if (showRetry)
              FilledButton.icon(
                onPressed: () => _loadDocuments(_docSuffix),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.retry),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarkdownDoc extends StatelessWidget {
  final String markdown;

  const _MarkdownDoc({required this.markdown});

  @override
  Widget build(BuildContext context) {
    if (markdown.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Markdown(
      data: markdown,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        p: TextStyle(fontSize: 14, color: context.textPrimary.withValues(alpha: 0.85)),
        listBullet: TextStyle(fontSize: 14, color: context.textPrimary.withValues(alpha: 0.85)),
        tableHead: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        tableBody: const TextStyle(fontSize: 13),
      ),
    );
  }
}