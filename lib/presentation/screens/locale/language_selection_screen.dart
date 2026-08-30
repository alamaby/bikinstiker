import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/locale/locale_cubit.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selected;

  void _select(String code) {
    setState(() => _selected = code);
  }

  void _continue() async {
    final code = _selected;
    if (code == null) return;
    await context.read<LocaleCubit>().setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              Icon(
                Icons.auto_awesome,
                size: 48,
                color: context.colors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'BikinStiker',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.languageTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: context.textSecondary),
              ),
              const SizedBox(height: 40),
              _LanguageOption(
                code: 'en',
                label: l10n.english,
                selected: _selected == 'en',
                onTap: () => _select('en'),
              ),
              const SizedBox(height: 12),
              _LanguageOption(
                code: 'id',
                label: l10n.bahasaIndonesia,
                selected: _selected == 'id',
                onTap: () => _select('id'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _selected == null ? null : _continue,
                child: Text(l10n.continueLabel),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.colors.primary.withValues(alpha: 0.08)
          : context.surfaceAlt,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? context.colors.primary : context.hairline,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 17)),
              const Spacer(),
              if (selected)
                Icon(Icons.check_circle, color: context.colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
