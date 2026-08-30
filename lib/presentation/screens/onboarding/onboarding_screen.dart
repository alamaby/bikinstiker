import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/onboarding_repository.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final bool replay;
  final VoidCallback? onFinished;

  const OnboardingScreen({
    super.key,
    this.replay = false,
    this.onFinished,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageCtrl;
  int _currentPage = 0;

  List<_OnboardingStepData> _steps(AppLocalizations l10n) => [
    _OnboardingStepData(
      icon: Icons.auto_awesome,
      title: l10n.onboardingCreateTitle,
      description: l10n.onboardingCreateDesc,
    ),
    _OnboardingStepData(
      icon: Icons.collections_bookmark,
      title: l10n.onboardingPackTitle,
      description: l10n.onboardingPackDesc,
    ),
    _OnboardingStepData(
      icon: Icons.send,
      title: l10n.onboardingWhatsAppTitle,
      description: l10n.onboardingWhatsAppDesc,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  static const int _stepCount = 3;
  bool get _isLastPage => _currentPage == _stepCount - 1;
  bool get _isFirstPage => _currentPage == 0;  Future<void> _finish() async {
    if (!widget.replay) {
      final repo = getIt<OnboardingRepository>();
      await repo.completeCoreFlow();
    }
    if (widget.onFinished != null) {
      widget.onFinished!.call();
      return;
    }
    // Replay from the Profile screen: no gate callback — just go back,
    // otherwise skip/finish leave the user stranded on this screen.
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _next() {
    if (_isLastPage) {
      _finish();
    } else {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() => _finish();

  void _back() {
    if (!_isFirstPage) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = _steps(l10n);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTopBar(l10n),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: steps.length,
                itemBuilder: (_, i) => _buildStepPage(steps[i]),
              ),
            ),
            _buildBottomBar(l10n),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          TextButton(
            onPressed: _skip,
            child: Text(l10n.skip),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_stepCount, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? context.colors.primary : context.hairline,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage(_OnboardingStepData step) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(step.icon, size: 56, color: context.colors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _next,
              child: Text(
                _isLastPage ? l10n.createMyFirstSticker : l10n.next,
              ),
            ),
          ),
          if (!_isFirstPage) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: _back,
                child: Text(l10n.back),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingStepData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingStepData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
