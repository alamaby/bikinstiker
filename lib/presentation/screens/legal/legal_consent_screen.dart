import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_consent_repository.dart';
import '../../../l10n/app_localizations.dart';

class LegalConsentScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const LegalConsentScreen({super.key, required this.onAccepted});

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  bool _accepted = false;
  bool _submitting = false;
  String _privacyMarkdown = '';
  String _termsMarkdown = '';
  bool _loading = true;
  String? _loadError;
  int _loadGeneration = 0;
  String? _loadedSuffix;

  String get _docSuffix =>
      Localizations.localeOf(context).languageCode == 'id' ? 'id' : 'en';

  @override
  void initState() {
    super.initState();
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
      setState(() {
        _privacyMarkdown = results[0];
        _termsMarkdown = results[1];
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _loadError = 'Failed to load documents';
      });
    }
  }

  Future<void> _onContinue() async {
    if (!_accepted || _submitting) return;
    setState(() => _submitting = true);
    try {
      await context.read<LegalConsentRepository>().acceptCurrent();
      if (!mounted) return;
      widget.onAccepted();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BikinStiker',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
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
                  // Tab bar
                  TabBar(
                    controller: _tab,
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.black54,
                    dividerHeight: 0,
                    tabs: [
                      Tab(text: l10n.privacyPolicy),
                      Tab(text: l10n.termsOfService),
                    ],
                  ),
                  // Markdown content
                  Expanded(
                    child: _buildContent(l10n),
                  ),
                ],
              ),
            ),
            // Checkbox + Continue
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.background,
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
                    onPressed: _accepted && !_submitting
                        ? _onContinue
                        : null,
                    child: _submitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
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
    return TabBarView(
      controller: _tab,
      children: [
        _MarkdownDoc(markdown: _privacyMarkdown),
        _MarkdownDoc(markdown: _termsMarkdown),
      ],
    );
  }
}

/// Renders a markdown document in a scrollable container.
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
        p: const TextStyle(fontSize: 14, color: Colors.black87),
        listBullet: const TextStyle(fontSize: 14, color: Colors.black87),
        tableHead: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        tableBody: const TextStyle(fontSize: 13),
      ),
    );
  }
}
