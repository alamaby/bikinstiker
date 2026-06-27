import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_consent_repository.dart';

class LegalConsentScreen extends StatefulWidget {
  final VoidCallback onAccepted;

  const LegalConsentScreen({super.key, required this.onAccepted});

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _accepted = false;
  bool _submitting = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      setState(() {});
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
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
                    const SizedBox(height: 8),
                    const Text(
                      'Terms of Service & Privacy Policy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _section('What this app does', [
                      'BikinStiker generates AI-powered WhatsApp stickers from your text prompts.',
                      'You pick a style, type a short description, and the app creates a die-cut sticker with a white background.',
                    ]),
                    _section('Credits & accounts', [
                      'Guest users receive 1 free credit to try the app.',
                      'Registered users receive 5 starter credits.',
                      'Each sticker generation costs 1 credit.',
                      'Saving or sharing generated stickers requires creating an account or signing in.',
                      'If you create an account from the guest session, your sticker is kept.',
                      'If you sign in to an existing account, the guest sticker is discarded and not transferred.',
                    ]),
                    _section('Advertising (Google AdMob)', [
                      'BikinStiker plans to use Google AdMob for advertising and monetization.',
                      'Google AdMob may collect and process advertising identifiers, device information, app interactions, diagnostics, and approximate location depending on your device settings, consent choices, and Google\'s policies.',
                    ]),
                    _section('Data we process', [
                      'Account data (email, authentication state).',
                      'Prompts and generated sticker metadata.',
                      'Credit balances and transaction history.',
                      'Anti-bot events for abuse prevention.',
                      'Advertising-related data when ads are enabled.',
                    ]),
                    _section('Your responsibilities', [
                      'Do not submit prompts that violate applicable laws, third-party rights, or platform policies.',
                      'You are responsible for the content you generate.',
                    ]),
                    _section('Changes', [
                      'Credits, generation limits, and ad behavior may change to prevent abuse and maintain service availability.',
                      'Significant changes to these terms will require renewed acceptance.',
                    ]),
                    const SizedBox(height: 24),
                    _AcceptCheckbox(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v),
                    ),
                  ],
                ),
              ),
            ),
            _BottomBar(
              accepted: _accepted,
              submitting: _submitting,
              onPressed: _onContinue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<String> bullets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...bullets.map(
          (b) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u2022 ',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                Expanded(
                  child: Text(
                    b,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AcceptCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AcceptCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          activeColor: AppColors.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'I have read and accept the Terms of Service and Privacy Policy',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool accepted;
  final bool submitting;
  final VoidCallback onPressed;

  const _BottomBar({
    required this.accepted,
    required this.submitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: FilledButton(
        onPressed: accepted && !submitting ? onPressed : null,
        child: submitting
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Continue'),
      ),
    );
  }
}
