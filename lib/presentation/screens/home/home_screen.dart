import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/presets.dart';
import '../../../core/errors/failures.dart';
import '../../../core/share_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sticker_preset.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/preset/preset_bloc.dart';
import '../../blocs/sticker_gen/sticker_gen_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../widgets/loading_lottie.dart';
import '../auth/auth_screen.dart';
import '../history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _presetId;
  final _promptCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _resultKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels > 0 && pos.pixels >= pos.maxScrollExtent) {
      // Near bottom — no-op for now, but a good hook for future pagination.
    }
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

  void _onPresetSelected(String id) {
    setState(() => _presetId = id);
  }

  void _onGenerate(List<StickerPreset> presets) {
    final input = _promptCtrl.text.trim();
    final validPresetIds = presets.map((p) => p.id).toSet();
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
    if (_presetId == null || !validPresetIds.contains(_presetId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a valid style')));
      return;
    }
    context.read<StickerGenBloc>().add(
      StickerGenSubmitted(presetId: _presetId!, prompt: input),
    );
  }

  void _onRefresh() {
    final auth = context.read<AuthBloc>().state;
    final role = auth.isGuest
        ? StickerPresetRole.guest
        : StickerPresetRole.free;
    context.read<PresetBloc>().add(
      PresetRefreshRequested(role: role, force: true),
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
            final userId = context.read<AuthBloc>().state.user?.id;
            if (userId != null) {
              context.read<WalletBloc>().add(WalletRefreshRequested(userId));
            }
            _scrollToResult();
          }
        },
        child: SafeArea(
          child: BlocBuilder<PresetBloc, PresetState>(
            builder: (context, presetState) {
              final presets = presetState.presets;
              final isLoading = presetState.status == PresetStatus.loading;
              final isError = presetState.status == PresetStatus.failure;
              final isEmpty = presets.isEmpty && !isLoading && !isError;

              if (isError && presets.isEmpty) {
                return _PresetErrorView(
                  message: presetState.errorMessage ?? 'Failed to load styles',
                  onRetry: _onRefresh,
                );
              }

              // Ensure _presetId is set to first available preset
              if (presets.isNotEmpty &&
                  (_presetId == null ||
                      !presets.any((p) => p.id == _presetId))) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && presets.isNotEmpty) {
                    setState(() => _presetId = presets.first.id);
                  }
                });
              }

              return RefreshIndicator(
                onRefresh: () async => _onRefresh(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: BlocBuilder<StickerGenBloc, StickerGenBlocState>(
                    builder: (context, genState) {
                      final submitting =
                          genState.status == StickerGenStatus.submitting;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CreditsCard(),
                          const SizedBox(height: 16),
                          const Text(
                            'Choose a style',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isLoading && presets.isEmpty)
                            const _PresetSkeleton()
                          else if (isEmpty)
                            _EmptyPresetsView(onRefresh: _onRefresh)
                          else
                            _PresetSelector(
                              presets: presets,
                              selectedId: _presetId,
                              onSelected: submitting ? null : _onPresetSelected,
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            'Describe your sticker',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _promptCtrl,
                            enabled: !submitting && !isEmpty,
                            maxLength: kMaxPromptChars,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. a smiling boba tea cup waving hello',
                              filled: submitting,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _GenerateButton(
                            onPressed: () => _onGenerate(presets),
                          ),
                          const SizedBox(height: 24),
                          KeyedSubtree(
                            key: _resultKey,
                            child: const _ResultPanel(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
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

class _PresetSelector extends StatelessWidget {
  final List<StickerPreset> presets;
  final String? selectedId;
  final ValueChanged<String>? onSelected;
  const _PresetSelector({
    required this.presets,
    required this.selectedId,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = presets.firstWhere(
      (p) => p.id == selectedId,
      orElse: () => presets.first,
    );
    final enabled = onSelected != null;

    return GestureDetector(
      onTap: enabled ? () => _openPicker(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.outline),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(selected.emoji ?? '', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selected.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    selected.description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: enabled ? Colors.black54 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PresetPickerSheet(
        presets: presets,
        selectedId: selectedId,
        onSelect: (id) {
          Navigator.of(context).pop();
          onSelected?.call(id);
        },
      ),
    );
  }
}

class _PresetPickerSheet extends StatelessWidget {
  final List<StickerPreset> presets;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const _PresetPickerSheet({
    required this.presets,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose style',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...presets.map((p) {
            final selected = p.id == selectedId;
            return ListTile(
              leading: Text(
                p.emoji ?? '',
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                p.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              subtitle: Text(
                p.description,
                style: const TextStyle(fontSize: 13),
              ),
              trailing: selected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () => onSelect(p.id),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
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

Future<void> _shareSticker(BuildContext context, String signedUrl) async {
  try {
    await shareStickerImage(signedUrl);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          'Failed to share sticker: $e',
          style: const TextStyle(color: Colors.white),
        ),
      ),
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
                        LoadingLottie(size: 120),
                        SizedBox(height: 12),
                        Text(
                          'Conjuring your sticker…',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
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
                        const SizedBox(height: 12),
                        if (!isGuest) ...[
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _shareSticker(
                                    context,
                                    genState.signedUrl!,
                                  ),
                                  icon: const Icon(Icons.share, size: 18),
                                  label: const Text('Share'),
                                ),
                              ),
                            ],
                          ),
                        ],
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

                if (failure is RateLimitedFailure) {
                  return _RateLimitedCard(
                    retryAfterSeconds: failure.retryAfterSeconds,
                  );
                } else if (failure is GenerationInProgressFailure) {
                  return _ParallelRequestCard(
                    retryAfterSeconds: failure.retryAfterSeconds,
                  );
                }

                final msg = failure is InsufficientCreditsFailure
                    ? 'Not enough credits to generate.'
                    : failure?.message ?? 'Generation failed';
                final icon = failure is InsufficientCreditsFailure
                    ? Icons.error_outline
                    : Icons.error_outline;

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

// ---------------------------------------------------------------------------
// Rate limit / parallel request countdown cards
// ---------------------------------------------------------------------------

class _RateLimitedCard extends StatefulWidget {
  final int retryAfterSeconds;
  const _RateLimitedCard({required this.retryAfterSeconds});

  @override
  State<_RateLimitedCard> createState() => _RateLimitedCardState();
}

class _RateLimitedCardState extends State<_RateLimitedCard> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.retryAfterSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > 0) _remaining--;
        if (_remaining == 0) {
          _timer?.cancel();
          Future.microtask(() {
            if (mounted) {
              context.read<StickerGenBloc>().add(const StickerGenReset());
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.retryAfterSeconds > 60
        ? 'Too many requests. Please try again in a few minutes.'
        : 'Too many requests. Please wait ${_remaining}s.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.timer_off_outlined, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: const TextStyle(color: AppColors.error)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              tooltip: 'Dismiss',
              onPressed: () {
                _timer?.cancel();
                context.read<StickerGenBloc>().add(const StickerGenReset());
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ParallelRequestCard extends StatefulWidget {
  final int? retryAfterSeconds;
  const _ParallelRequestCard({this.retryAfterSeconds});

  @override
  State<_ParallelRequestCard> createState() => _ParallelRequestCardState();
}

class _ParallelRequestCardState extends State<_ParallelRequestCard> {
  late int? _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.retryAfterSeconds;
    if (_remaining != null && _remaining! > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_remaining != null && _remaining! > 0) {
            _remaining = _remaining! - 1;
          }
          if (_remaining == 0) {
            _timer?.cancel();
            Future.microtask(() {
              if (mounted) {
                context.read<StickerGenBloc>().add(const StickerGenReset());
              }
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = _remaining != null
        ? 'A generation is already running. Please wait ${_remaining}s.'
        : 'A sticker generation is already in progress.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg, style: const TextStyle(color: AppColors.error)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.error),
              tooltip: 'Dismiss',
              onPressed: () {
                _timer?.cancel();
                context.read<StickerGenBloc>().add(const StickerGenReset());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset loading / error / empty helpers
// ---------------------------------------------------------------------------

class _PresetSkeleton extends StatelessWidget {
  const _PresetSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 160,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPresetsView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyPresetsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_outlined, size: 36, color: AppColors.outline),
          const SizedBox(height: 8),
          const Text(
            'No styles available right now',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to refresh',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _PresetErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _PresetErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
