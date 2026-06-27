import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/presets.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_theme.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/sticker_gen/sticker_gen_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../auth/auth_screen.dart';
import '../history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _presetId = kStickerPresets.first.id;
  final _promptCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();

  @override
  void dispose() {
    _promptCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultKey.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _onGenerate() {
    final input = _promptCtrl.text.trim();
    final validPresetIds = kStickerPresets.map((p) => p.id).toSet();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Type a short prompt first')),
      );
      return;
    }
    if (input.length > kMaxPromptChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prompt must be $kMaxPromptChars characters or less'),
        ),
      );
      return;
    }
    if (!validPresetIds.contains(_presetId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a valid style')));
      return;
    }
    context.read<StickerGenBloc>().add(
      StickerGenSubmitted(presetId: _presetId, prompt: input),
    );
  }

  void _openAuthWall() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(mode: AuthScreenMode.guestAuthWall),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BikinStiker',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthBlocState>(
            builder: (context, authState) {
              final isGuest = authState.isGuest;
              if (isGuest) {
                return IconButton(
                  tooltip: 'Create account',
                  icon: const Icon(Icons.person_add),
                  onPressed: _openAuthWall,
                );
              }
              return Row(
                children: [
                  IconButton(
                    tooltip: 'History',
                    icon: const Icon(Icons.history),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AuthBloc>().add(
                      const AuthSignOutRequested(),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<StickerGenBloc, StickerGenBlocState>(
        listenWhen: (p, n) => p.status != n.status,
        listener: (context, state) {
          if (state.status == StickerGenStatus.success ||
              state.status == StickerGenStatus.failure) {
            _scrollToResult();
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CreditsCard(),
                const SizedBox(height: 16),
                const Text(
                  'Choose a style',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                _PresetGrid(
                  selectedId: _presetId,
                  onSelected: (id) => setState(() => _presetId = id),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Describe your sticker',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _promptCtrl,
                  maxLength: kMaxPromptChars,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. a smiling boba tea cup waving hello',
                  ),
                ),
                const SizedBox(height: 8),
                _GenerateButton(onPressed: _onGenerate),
                const SizedBox(height: 24),
                KeyedSubtree(key: _resultKey, child: const _ResultPanel()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletBlocState>(
      builder: (context, walletState) {
        return BlocBuilder<AuthBloc, AuthBlocState>(
          builder: (context, authState) {
            final isGuest = authState.isGuest;
            final balance = walletState.balance;
            final low = !walletState.loading && balance < kStickerCost;
            final label = isGuest ? 'Guest Credits' : 'Credits';
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt,
                      color: low ? AppColors.error : AppColors.secondary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            walletState.loading ? '…' : '$balance',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isGuest)
                            const Text(
                              'Create an account for 5 credits',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (low)
                      const Tooltip(
                        message: 'Low balance',
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: AppColors.error),
                            SizedBox(width: 4),
                            Text(
                              'Low',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PresetGrid extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;
  const _PresetGrid({required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: kStickerPresets.map((p) {
        final selected = p.id == selectedId;
        return InkWell(
          onTap: () => onSelected(p.id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.surface,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outline,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  p.icon,
                  color: selected ? AppColors.primary : Colors.black54,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        p.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        p.description,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GenerateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletBlocState>(
      builder: (context, walletState) {
        return BlocBuilder<StickerGenBloc, StickerGenBlocState>(
          builder: (context, genState) {
            final submitting = genState.status == StickerGenStatus.submitting;
            final hasCredits = walletState.balance >= kStickerCost;
            final enabled = !submitting && hasCredits;
            return Tooltip(
              message: hasCredits ? '' : 'Not enough credits',
              child: FilledButton.icon(
                onPressed: enabled ? onPressed : null,
                icon: submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  submitting
                      ? 'Generating…'
                      : 'Generate Sticker  ($kStickerCost credit)',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StickerGenBloc, StickerGenBlocState>(
      builder: (context, genState) {
        return BlocBuilder<AuthBloc, AuthBlocState>(
          builder: (context, authState) {
            final isGuest = authState.isGuest;
            switch (genState.status) {
              case StickerGenStatus.idle:
                return const SizedBox.shrink();
              case StickerGenStatus.submitting:
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.hourglass_top, color: AppColors.primary),
                        SizedBox(height: 8),
                        Text('Conjuring your sticker…'),
                      ],
                    ),
                  ),
                );
              case StickerGenStatus.success:
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle, color: AppColors.success),
                            SizedBox(width: 6),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: genState.signedUrl!,
                              fit: BoxFit.contain,
                              placeholder: (_, _) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (_, _, _) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isGuest) ...[
                          const SizedBox(height: 16),
                          _GuestResultCta(),
                        ],
                      ],
                    ),
                  ),
                );
              case StickerGenStatus.failure:
                final failure = genState.failure;
                String msg;
                IconData icon;

                if (failure is InsufficientCreditsFailure) {
                  msg = 'Not enough credits to generate.';
                  icon = Icons.error_outline;
                } else if (failure is RateLimitedFailure) {
                  msg = failure.retryAfterSeconds > 60
                      ? 'Too many requests. Please try again in a few minutes.'
                      : 'Too many requests. Please wait ${failure.retryAfterSeconds}s.';
                  icon = Icons.timer_off_outlined;
                } else if (failure is GenerationInProgressFailure) {
                  msg = failure.retryAfterSeconds != null
                      ? 'A generation is already running. Please wait ${failure.retryAfterSeconds}s.'
                      : 'A sticker generation is already in progress.';
                  icon = Icons.hourglass_top;
                } else {
                  msg = failure?.message ?? 'Generation failed';
                  icon = Icons.error_outline;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            msg,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
            }
          },
        );
      },
    );
  }
}

class _GuestResultCta extends StatelessWidget {
  const _GuestResultCta();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Create an account to save or share this sticker.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const AuthScreen(mode: AuthScreenMode.guestAuthWall),
            ),
          ),
          icon: const Icon(Icons.person_add),
          label: const Text('Create account and keep sticker'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const AuthScreen(mode: AuthScreenMode.guestAuthWall),
            ),
          ),
          icon: const Icon(Icons.login),
          label: const Text('Sign in to existing account'),
        ),
        const SizedBox(height: 8),
        Text(
          'If you sign in to an existing account, this guest sticker will be discarded.',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
