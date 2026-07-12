import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/onboarding_repository.dart';

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

  static const _steps = [
    _OnboardingStepData(
      icon: Icons.auto_awesome,
      title: 'Create your sticker',
      description: 'Write a short idea, choose a style, then generate your sticker.',
    ),
    _OnboardingStepData(
      icon: Icons.collections_bookmark,
      title: 'Add it to a pack',
      description: 'Choose or create a pack, then add 1-3 emojis so the sticker is easy to find in WhatsApp.',
    ),
    _OnboardingStepData(
      icon: Icons.send,
      title: 'Add your pack to WhatsApp',
      description: 'Add at least 3 stickers to a pack, then tap Export to WhatsApp.',
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

  bool get _isLastPage => _currentPage == _steps.length - 1;
  bool get _isFirstPage => _currentPage == 0;

  Future<void> _finish() async {
    if (!widget.replay) {
      final repo = getIt<OnboardingRepository>();
      await repo.completeCoreFlow();
    }
    widget.onFinished?.call();
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _steps.length,
                itemBuilder: (_, i) => _buildStepPage(_steps[i]),
              ),
            ),
            _buildBottomBar(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          TextButton(
            onPressed: _skip,
            child: const Text('Skip'),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_steps.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.outline,
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(step.icon, size: 56, color: AppColors.primary),
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
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
              child: Text(_isLastPage ? 'Create My First Sticker' : 'Next'),
            ),
          ),
          if (!_isFirstPage) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: _back,
                child: const Text('Back'),
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
