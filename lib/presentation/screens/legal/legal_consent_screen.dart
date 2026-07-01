import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_consent_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final results = await Future.wait([
      rootBundle.loadString('docs/privacy-policy.md'),
      rootBundle.loadString('docs/terms-of-service.md'),
    ]);
    if (!mounted) return;
    setState(() {
      _privacyMarkdown = results[0];
      _termsMarkdown = results[1];
    });
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
                      'Terms of Service & Privacy Policy',
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
                    tabs: const [
                      Tab(text: 'Privacy Policy'),
                      Tab(text: 'Terms of Service'),
                    ],
                  ),
                  // Markdown content
                  Expanded(
                    child: TabBarView(
                      controller: _tab,
                      children: [
                        _MarkdownDoc(markdown: _privacyMarkdown),
                        _MarkdownDoc(markdown: _termsMarkdown),
                      ],
                    ),
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
                          'I have read and accept the Terms of Service and Privacy Policy',
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
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
