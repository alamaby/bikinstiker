import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/presets.dart';
import '../../../core/constants/prompt_suggestions.dart';
import '../../../core/di.dart';
import '../../../core/errors/failures.dart';
import '../../../core/localization/preset_localizations.dart';
import '../../../core/share_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/sticker_preset.dart';
import '../../../data/models/user_subscription.dart';
import '../../../data/repositories/sticker_repository.dart';
import '../../../data/repositories/surprise_me_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/home_prefill/home_prefill_cubit.dart';
import '../../blocs/preset/preset_bloc.dart';
import '../../blocs/sticker_pack/sticker_pack_bloc.dart';
import '../../blocs/sticker_gen/sticker_gen_bloc.dart';
import '../../blocs/surprise_me/surprise_me_cubit.dart';
import '../../blocs/surprise_me/surprise_me_state.dart';
import '../../blocs/subscription/subscription_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../widgets/ads_banner_placeholder.dart';
import '../../widgets/add_to_pack_sheet.dart';
import '../../widgets/loading_lottie.dart';
import '../../widgets/prompt_suggestion_chip.dart';
import '../../widgets/sticker_feedback_buttons.dart';
import '../../widgets/surprise_me_button.dart';
import '../../widgets/tier_badge.dart';
import '../auth/auth_screen.dart';
import '../packs/packs_list_screen.dart';
import '../history/history_screen.dart';
import '../missions/missions_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _presetId;
  final _promptCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();
  String _captionPosition = 'bottom';
  String? _lastSuccessfulPrompt;
  String? _lastSuccessfulPresetId;
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
    _captionCtrl.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    final input = _promptCtrl.text.trim();
    final captionRaw = _captionCtrl.text.trim().toUpperCase();
    final validPresetIds = presets.map((p) => p.id).toSet();
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.typePromptFirst)));
      return;
    }
    if (input.length > kMaxPromptChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.promptTooLong(kMaxPromptChars))),
      );
      return;
    }
    if (_presetId == null || !validPresetIds.contains(_presetId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chooseValidStyle)));
      return;
    }
    context.read<StickerGenBloc>().add(
      StickerGenSubmitted(
        presetId: _presetId!,
        prompt: input,
        caption: captionRaw.isEmpty ? null : captionRaw,
        captionPosition: captionRaw.isEmpty ? null : _captionPosition,
      ),
    );
  }

  void _reuseLastPrompt() {
    if (_lastSuccessfulPrompt == null || _lastSuccessfulPresetId == null) {
      return;
    }
    setState(() {
      _promptCtrl.text = _lastSuccessfulPrompt!;
      _presetId = _lastSuccessfulPresetId;
      _captionCtrl.clear();
      _captionPosition = 'bottom';
    });
  }

  void _applyPrompt(String text) {
    setState(() => _promptCtrl.text = text);
  }

  void _refreshWallet() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<WalletBloc>().add(WalletRefreshRequested(userId));
    }
  }

  String _localSuggestion({required bool textOnly}) {
    return randomSuggestionFor(
      _presetId ?? 'kawaii',
      textOnly: textOnly,
      avoid: _promptCtrl.text.isEmpty ? null : _promptCtrl.text,
    );
  }

  Future<void> _onSurpriseMePressed({
    required bool isTextOnly,
    required List<StickerPreset> presets,
  }) async {
    // Text-only presets keep the free local curated behavior.
    if (isTextOnly) {
      _applyPrompt(_localSuggestion(textOnly: true));
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    // Null => block (sync with _onGenerate:114), not fallback to 'kawaii'.
    // _presetId is auto-set to presets.first via postFrameCallback:449,
    // so null only occurs during initial load — caught here until R2 disables button.
    final validPresetIds = presets.map((p) => p.id).toSet();
    if (_presetId == null || !validPresetIds.contains(_presetId)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chooseValidStyle)));
      return;
    }

    HapticFeedback.selectionClick();

    SurpriseMeQuota? quota;
    try {
      quota = await context.read<SurpriseMeCubit>().fetchQuota();
    } catch (_) {
      quota = null;
    }
    if (!mounted) return;

    final free = quota != null && !quota.willBeCharged;
    final insufficient =
        quota != null && quota.willBeCharged && quota.balance < 1;
    var goMissions = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          insufficient
              ? l10n.notEnoughCredits
              : free
              ? l10n.surpriseConfirmTitleFree
              : l10n.surpriseConfirmTitlePaid,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (insufficient) ...[
              Text(l10n.surpriseCostLine),
              const SizedBox(height: 4),
              Text(l10n.surpriseTopUpViaMissions),
            ] else if (free)
              Text(l10n.surpriseConfirmBodyFree(quota!.freeRemaining))
            else ...[
              Text(l10n.surpriseCostLine),
              const SizedBox(height: 4),
              Text(
                quota != null
                    ? l10n.surpriseConfirmBodyPaid(quota.balance - 1)
                    : l10n.surpriseCostLine,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          if (insufficient)
            FilledButton(
              onPressed: () {
                goMissions = true;
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(l10n.missions),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.ok),
            ),
        ],
      ),
    );

    if (!mounted) return;
    if (goMissions) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MissionsScreen()));
      return;
    }
    if (confirmed != true) return;
    context.read<SurpriseMeCubit>().requestSurprise(
      presetId: _presetId ?? 'kawaii',
    );
  }

  void _onSurpriseMeStateChanged(AppLocalizations l10n, SurpriseMeState state) {
    if (state is SurpriseMeSuccess) {
      HapticFeedback.mediumImpact();
      _applyPrompt(state.prompt);
      _refreshWallet();
    } else if (state is SurpriseMeFailure) {
      // Provider failed; server already refunded any charge. Fall back to a
      // free local suggestion so the user still gets inspiration.
      _applyPrompt(_localSuggestion(textOnly: false));
      _refreshWallet();
      final String message;
      final failure = state.failure;
      if (failure is InsufficientCreditsFailure) {
        message = l10n.notEnoughCredits;
      } else if (failure is RateLimitedFailure) {
        message = l10n.surpriseWaitSeconds(failure.retryAfterSeconds);
      } else {
        message = '${l10n.surpriseFailed} ${l10n.surpriseLocalFallback}';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _onRefresh() {
    final auth = context.read<AuthBloc>().state;
    final subState = context.read<SubscriptionBloc>().state;
    final userId = auth.user?.id;
    if (userId != null) {
      context.read<WalletBloc>().add(WalletRefreshRequested(userId));
    }
    StickerPresetRole role;
    if (auth.isGuest) {
      role = StickerPresetRole.guest;
    } else {
      role = subState.isPlus ? StickerPresetRole.plus : StickerPresetRole.free;
    }
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
    final l10n = AppLocalizations.of(context)!;
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
                  tooltip: l10n.createAccount,
                  icon: const Icon(Icons.person_add),
                  onPressed: _openAuthWall,
                );
              }
              return Row(
                children: [
                  IconButton(
                    tooltip: l10n.missions,
                    icon: const Icon(Icons.emoji_events_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MissionsScreen()),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.myPacks,
                    icon: const Icon(Icons.collections_bookmark_outlined),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<StickerPackBloc>(),
                          child: const PacksListScreen(),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.history,
                    icon: const Icon(Icons.history),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.profile,
                    icon: const Icon(Icons.person_outline),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<HomePrefillCubit, HomePrefillState>(
        listenWhen: (p, n) => n.hasData,
        listener: (context, state) {
          if (state.prompt != null) {
            _promptCtrl.text = state.prompt!;
          }
          if (state.presetId != null) {
            final presetState = context.read<PresetBloc>().state;
            final allowedIds = presetState.presets.map((p) => p.id).toSet();
            if (allowedIds.contains(state.presetId)) {
              setState(() => _presetId = state.presetId);
            }
          }
          if (state.captionText != null) {
            _captionCtrl.text = state.captionText!;
            _captionPosition = state.captionPosition ?? 'bottom';
          } else {
            _captionCtrl.clear();
            _captionPosition = 'bottom';
          }
          setState(() {});
          context.read<HomePrefillCubit>().clear();
        },
        child: BlocListener<StickerGenBloc, StickerGenBlocState>(
          listenWhen: (p, n) => p.status != n.status,
          listener: (context, state) {
            if (state.status == StickerGenStatus.success) {
              setState(() {
                _lastSuccessfulPrompt = _promptCtrl.text.trim();
                _lastSuccessfulPresetId = _presetId;
              });
            }
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

                // Look up the selected preset to determine input mode
                final selectedPreset = _presetId != null
                    ? presets.where((p) => p.id == _presetId).firstOrNull
                    : null;
                final isTextOnly = selectedPreset?.isTextOnly ?? false;
                final inputMaxChars = isTextOnly ? 20 : kMaxPromptChars;
                final inputHint = isTextOnly
                    ? l10n.inputHintTextOnly
                    : l10n.inputHintSubject;
                final inputLabel = isTextOnly
                    ? l10n.typeYourText
                    : l10n.describeYourSticker;

                if (isError && presets.isEmpty) {
                  return _PresetErrorView(
                    message:
                        presetState.errorMessage ?? l10n.failedToLoadStyles,
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
                        final surpriseBusy =
                            context.watch<SurpriseMeCubit>().state
                                is SurpriseMeLoading;
                        return BlocListener<SurpriseMeCubit, SurpriseMeState>(
                          listener: (context, state) =>
                              _onSurpriseMeStateChanged(l10n, state),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CreditsCard(),
                              const SizedBox(height: 8),
                              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                                builder: (context, subState) {
                                  final isGuest = context
                                      .read<AuthBloc>()
                                      .state
                                      .isGuest;
                                  final showAd = !isGuest && !subState.isPlus;
                                  if (!showAd) return const SizedBox.shrink();
                                  return const AdsBannerPlaceholder();
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.chooseStyle,
                                style: const TextStyle(
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
                                  onSelected: submitting
                                      ? null
                                      : _onPresetSelected,
                                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      inputLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (_lastSuccessfulPrompt != null)
                                    TextButton.icon(
                                      onPressed: submitting
                                          ? null
                                          : _reuseLastPrompt,
                                      icon: const Icon(Icons.replay, size: 16),
                                      label: Text(l10n.useLast),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _promptCtrl,
                                enabled:
                                    !submitting && !surpriseBusy && !isEmpty,
                                maxLength: inputMaxChars,
                                maxLines: isTextOnly ? 1 : 3,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: surpriseBusy
                                      ? l10n.surpriseLoading
                                      : inputHint,
                                  filled: submitting || surpriseBusy,
                                  fillColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              if (surpriseBusy)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        l10n.surpriseLoading,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SurpriseMeButton(
                                  // Disable while presets still loading to avoid false snackbar (R2).
                                  enabled:
                                      !submitting && presets.isNotEmpty,
                                  onPressed: () => _onSurpriseMePressed(
                                    isTextOnly: isTextOnly,
                                    presets: presets,
                                  ),
                                ),
                              if (_promptCtrl.text.isEmpty && _presetId != null)
                                PromptSuggestionChip(
                                  key: ValueKey('chip_$_presetId'),
                                  presetId: _presetId!,
                                  enabled: !submitting && !surpriseBusy,
                                  textOnly: isTextOnly,
                                  onSuggestionSelected: (suggestion) {
                                    _promptCtrl.text = suggestion;
                                    setState(() {});
                                  },
                                ),
                              const SizedBox(height: 16),
                              if (!isTextOnly) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.captionOptional,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_captionCtrl.text.length} / 10',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _captionCtrl,
                                  enabled:
                                      !submitting && !surpriseBusy && !isEmpty,
                                  maxLength: 10,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[A-Z0-9 .!?\-]'),
                                    ),
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: l10n.captionExample,
                                    counterText: '',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                if (_captionCtrl.text.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        l10n.position,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      SegmentedButton<String>(
                                        segments: [
                                          ButtonSegment(
                                            value: 'top',
                                            label: Text(l10n.top),
                                          ),
                                          ButtonSegment(
                                            value: 'bottom',
                                            label: Text(l10n.bottom),
                                          ),
                                        ],
                                        selected: {_captionPosition},
                                        onSelectionChanged: submitting
                                            ? null
                                            : (s) => setState(
                                                () =>
                                                    _captionPosition = s.first,
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                              const SizedBox(height: 8),
                              _GenerateButton(
                                onPressed: submitting || surpriseBusy
                                    ? null
                                    : () => _onGenerate(presets),
                              ),
                              const SizedBox(height: 24),
                              KeyedSubtree(
                                key: _resultKey,
                                child: const _ResultPanel(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
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
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<WalletBloc, WalletBlocState>(
      builder: (context, walletState) {
        return BlocBuilder<AuthBloc, AuthBlocState>(
          builder: (context, authState) {
            return BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, subState) {
                final isGuest = authState.isGuest;
                final balance = walletState.balance;
                final low = !walletState.loading && balance < kStickerCost;
                final label = isGuest
                    ? l10n.guestCredits
                    : subState.isPlus
                    ? l10n.creditsPlus
                    : l10n.credits;
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
                              Row(
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (!isGuest) ...[
                                    const SizedBox(width: 6),
                                    TierBadge(
                                      tier:
                                          subState.subscription?.tier ??
                                          SubscriptionTier.free,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                walletState.loading ? '…' : '$balance',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (isGuest)
                                Text(
                                  l10n.createAccountForCredits,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (low)
                          Tooltip(
                            message: l10n.lowBalance,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.low,
                                  style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
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
                    localizedPresetLabel(l10n, selected),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    localizedPresetDescription(l10n, selected),
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.chooseStyleTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: presets.length,
              itemBuilder: (context, i) {
                final p = presets[i];
                final selected = p.id == selectedId;
                return ListTile(
                  leading: Text(
                    p.emoji ?? '',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    localizedPresetLabel(l10n, p),
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    localizedPresetDescription(l10n, p),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GenerateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<WalletBloc, WalletBlocState>(
      builder: (context, walletState) {
        return BlocBuilder<StickerGenBloc, StickerGenBlocState>(
          builder: (context, genState) {
            final submitting = genState.status == StickerGenStatus.submitting;
            final hasCredits = walletState.balance >= kStickerCost;
            final enabled = !submitting && hasCredits && onPressed != null;
            return Tooltip(
              message: hasCredits ? '' : l10n.notEnoughCredits,
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
                      ? l10n.generating
                      : l10n.generateSticker(kStickerCost),
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
  final l10n = AppLocalizations.of(context);
  try {
    await shareStickerImage(signedUrl);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text(
          l10n == null ? 'Failed to share sticker: $e' : l10n.failedToShare(e),
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
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<StickerGenBloc, StickerGenBlocState>(
      builder: (context, genState) {
        return BlocBuilder<AuthBloc, AuthBlocState>(
          builder: (context, authState) {
            final isGuest = authState.isGuest;
            switch (genState.status) {
              case StickerGenStatus.idle:
                return const SizedBox.shrink();
              case StickerGenStatus.submitting:
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const LoadingLottie(size: 120),
                        const SizedBox(height: 12),
                        Text(
                          l10n.conjuringSticker,
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.done,
                              style: const TextStyle(
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
                            child:
                                genState.imageUrl != null &&
                                    genState.imageUrl!.isNotEmpty
                                ? FutureBuilder<File?>(
                                    future: getIt<StickerRepository>()
                                        .getCachedImageFile(genState.imageUrl!),
                                    builder: (context, snap) {
                                      if (snap.hasError) {
                                        return const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.error,
                                          ),
                                        );
                                      }
                                      final file = snap.data;
                                      if (file == null) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }
                                      return Image.file(
                                        file,
                                        fit: BoxFit.contain,
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: AppColors.error,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!isGuest && genState.stickerId != null) ...[
                          StickerFeedbackButtons(
                            stickerGenerationId: genState.stickerId!,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (!isGuest) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.nextAddToPack,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _shareSticker(
                                    context,
                                    genState.signedUrl!,
                                  ),
                                  icon: const Icon(Icons.share, size: 18),
                                  label: Text(l10n.share),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: genState.stickerId != null
                                      ? () {
                                          AddToPackSheet.show(
                                            context,
                                            genState.stickerId!,
                                          );
                                        }
                                      : null,
                                  icon: const Icon(
                                    Icons.collections_bookmark,
                                    size: 18,
                                  ),
                                  label: Text(l10n.addToPack),
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
                    ? l10n.notEnoughCreditsToGenerate
                    : failure?.message ?? l10n.generationFailed;
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
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.createAccountSaveShare,
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
          label: Text(l10n.createAccountKeepSticker),
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
          label: Text(l10n.signInExistingAccount),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.guestDiscardWarning,
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
    final l10n = AppLocalizations.of(context)!;
    final msg = widget.retryAfterSeconds > 60
        ? l10n.tooManyRequests
        : l10n.tooManyRequestsWait(_remaining);
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
              tooltip: l10n.dismiss,
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
    final l10n = AppLocalizations.of(context)!;
    final msg = _remaining != null
        ? l10n.generationRunning(_remaining!)
        : l10n.generationInProgress;
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
              tooltip: l10n.dismiss,
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
    final l10n = AppLocalizations.of(context)!;
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
          Text(
            l10n.noStylesAvailable,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pullToRefresh,
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
    final l10n = AppLocalizations.of(context)!;
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
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
