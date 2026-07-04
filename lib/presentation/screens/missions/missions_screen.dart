import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/user_subscription.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/mission/mission_bloc.dart';
import '../../blocs/subscription/subscription_bloc.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../widgets/tier_badge.dart';
import 'widgets/daily_checkin_card.dart';
import 'widgets/mission_section_header.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  Timer? _ticker;
  Timer? _celebrationTimer;
  bool _showCheckinCelebration = false;
  int? _pendingCheckinDay;
  int? _justClaimedDay;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _celebrationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Sign in required')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Missions')),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MissionBloc, MissionState>(
            listenWhen: (p, n) =>
                p.errorMessage != n.errorMessage && n.errorMessage != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? 'Claim failed'),
                  backgroundColor: AppColors.error,
                ),
              );
              Future.delayed(const Duration(seconds: 3), () {
                if (context.mounted) {
                  context.read<MissionBloc>().add(const MissionErrorCleared());
                }
              });
            },
          ),
          BlocListener<MissionBloc, MissionState>(
            listenWhen: (p, n) =>
                p.successMessage != n.successMessage &&
                n.successMessage != null,
            listener: (context, state) {
              final msg = state.successMessage ?? '';

              // Refresh wallet balance on mission success
              context.read<WalletBloc>().add(WalletRefreshRequested(userId));

              if (msg.startsWith('checkin_success:')) {
                final credits = msg.split(':').last;
                _showCheckinAnimation();
                _showSuccessSnackBar(context, 'Check-in successful!', credits);
              } else if (msg.startsWith('mission_success:')) {
                final credits = msg.split(':').last;
                _showSuccessSnackBar(context, 'Mission completed!', credits);
              }

              Future.delayed(const Duration(seconds: 3), () {
                if (context.mounted) {
                  context.read<MissionBloc>().add(const MissionErrorCleared());
                }
              });
            },
          ),
        ],

        child: Stack(
          children: [
            BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, subState) {
                return BlocBuilder<MissionBloc, MissionState>(
                  builder: (context, state) {
                    if (state.status == MissionStatus.initial) {
                      context.read<MissionBloc>().add(
                        MissionLoadRequested(userId),
                      );
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == MissionStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == MissionStatus.error &&
                        state.missions.isEmpty) {
                      return Center(child: Text(state.errorMessage ?? 'Error'));
                    }

                    final userTier =
                        subState.subscription?.tier ?? SubscriptionTier.free;

                    final dailyLogin = state.missions
                        .where((m) => m.code == 'daily_login')
                        .toList();
                    final quickRewards = _quickRewards(state.missions);
                    final achievements = _achievements(state.missions);

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<MissionBloc>().add(
                          MissionLoadRequested(userId),
                        );
                      },
                      child: CustomScrollView(
                        slivers: [
                          // Daily Rewards section
                          if (dailyLogin.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: MissionSectionHeader(
                                icon: Icons.local_fire_department,
                                title: 'Daily Rewards',
                                count: dailyLogin.length,
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final m = dailyLogin[index];
                                return DailyCheckinCard(
                                  mission: m,
                                  streak: state.streak,
                                  justClaimedDay: _justClaimedDay,
                                  onClaim: () {
                                    final cycleDay =
                                        state.streak?.currentCycleDay ?? 1;
                                    _pendingCheckinDay = cycleDay <= 0
                                        ? 1
                                        : cycleDay;
                                    context.read<MissionBloc>().add(
                                      const MissionDailyCheckinClaimRequested(),
                                    );
                                  },
                                );
                              }, childCount: dailyLogin.length),
                            ),
                          ],

                          // Quick Rewards section
                          if (quickRewards.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: MissionSectionHeader(
                                icon: Icons.flash_on,
                                title: 'Quick Rewards',
                                count: quickRewards.length,
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final mission = quickRewards[index];
                                return _MissionTile(
                                  mission: mission,
                                  completions: state.completionsFor(mission.id),
                                  canAccess: mission.canAccess(userTier),
                                  isPending: state.isMissionPending(mission.id),
                                  isDebounced: state.isMissionDebounced(
                                    mission.id,
                                  ),
                                  cooldownRemaining: state.cooldownRemainingFor(
                                    mission.id,
                                    mission,
                                  ),
                                  isDailyLimitReached: state
                                      .isDailyLimitReached(mission.id, mission),
                                  isCompleted: state.isMissionCompleted(
                                    mission.id,
                                    mission,
                                  ),
                                  onComplete: () {
                                    if (mission.code == 'watch_video_ad') {
                                      context.read<MissionBloc>().add(
                                        MissionWatchAdRequested(
                                          userId,
                                          mission.id,
                                        ),
                                      );
                                    } else {
                                      context.read<MissionBloc>().add(
                                        MissionCompleteRequested(
                                          userId,
                                          mission.id,
                                        ),
                                      );
                                    }
                                  },
                                );
                              }, childCount: quickRewards.length),
                            ),
                          ],

                          // Achievements section
                          if (achievements.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: MissionSectionHeader(
                                icon: Icons.emoji_events,
                                title: 'Achievements',
                                count: achievements.length,
                              ),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final mission = achievements[index];
                                return _MissionTile(
                                  mission: mission,
                                  completions: state.completionsFor(mission.id),
                                  canAccess: mission.canAccess(userTier),
                                  isPending: state.isMissionPending(mission.id),
                                  isDebounced: state.isMissionDebounced(
                                    mission.id,
                                  ),
                                  cooldownRemaining: state.cooldownRemainingFor(
                                    mission.id,
                                    mission,
                                  ),
                                  isDailyLimitReached: state
                                      .isDailyLimitReached(mission.id, mission),
                                  isCompleted: state.isMissionCompleted(
                                    mission.id,
                                    mission,
                                  ),
                                  onComplete: () {
                                    context.read<MissionBloc>().add(
                                      MissionCompleteRequested(
                                        userId,
                                        mission.id,
                                      ),
                                    );
                                  },
                                );
                              }, childCount: achievements.length),
                            ),
                          ],

                          // Bottom padding
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            if (_showCheckinCelebration)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    alignment: Alignment.center,
                    color: Colors.black.withValues(alpha: 0.04),
                    child: Lottie.asset(
                      'assets/animations/celebration.json',
                      width: 220,
                      height: 220,
                      repeat: false,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCheckinAnimation() {
    if (!mounted) return;
    _celebrationTimer?.cancel();
    setState(() {
      _showCheckinCelebration = true;
      _justClaimedDay = _pendingCheckinDay;
    });
    _celebrationTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _showCheckinCelebration = false;
        _justClaimedDay = null;
        _pendingCheckinDay = null;
      });
    });
  }

  /// Quick rewards: recurring missions with cooldown/daily limit, excluding daily_login
  List<Mission> _quickRewards(List<Mission> missions) {
    return missions.where((m) {
      final isRecurring =
          m.maxCompletionsPerUser == null || m.maxCompletionsPerUser! > 1;
      final isDailyStreak = m.code == 'daily_login';
      return isRecurring && !isDailyStreak;
    }).toList();
  }

  void _showSuccessSnackBar(
    BuildContext context,
    String title,
    String credits,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Row(
          children: [
            const Text('\u{1F389}', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$credits',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Achievements: one-time missions (max_completions_per_user = 1, no cooldown/daily limit)
  List<Mission> _achievements(List<Mission> missions) {
    return missions.where((m) {
      final isOneTime = (m.maxCompletionsPerUser ?? 1) == 1;
      final hasCooldownOrDailyLimit =
          m.cooldownSeconds != null || m.maxCompletionsPerDay != null;
      return isOneTime && !hasCooldownOrDailyLimit;
    }).toList();
  }
}

class _MissionTile extends StatelessWidget {
  final Mission mission;
  final int completions;
  final bool canAccess;
  final bool isPending;
  final bool isDebounced;
  final Duration? cooldownRemaining;
  final bool isDailyLimitReached;
  final bool isCompleted;
  final VoidCallback onComplete;

  const _MissionTile({
    required this.mission,
    required this.completions,
    required this.canAccess,
    required this.isPending,
    required this.isDebounced,
    this.cooldownRemaining,
    this.isDailyLimitReached = false,
    this.isCompleted = false,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final canComplete =
        canAccess &&
        !isCompleted &&
        !isPending &&
        !isDebounced &&
        !isDailyLimitReached;

    String buttonLabel = 'Claim';
    if (mission.code == 'watch_video_ad') {
      buttonLabel = 'Watch Ad';
    } else if (mission.code == 'share_app_daily') {
      buttonLabel = 'Share';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!canAccess) TierBadge(tier: mission.requiredTier),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.bolt, size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  '+${mission.rewardCredits} credit${mission.rewardCredits == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (isCompleted)
                  const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else if (!canAccess)
                  const Text(
                    'Requires Plus',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (isDailyLimitReached)
                  const Text(
                    'Daily limit reached',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (cooldownRemaining != null)
                  Text(
                    _formatDuration(cooldownRemaining!),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black38,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  FilledButton(
                    onPressed: canComplete ? onComplete : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: isPending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            buttonLabel,
                            style: const TextStyle(fontSize: 13),
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (d.inHours > 0) {
      return '${d.inHours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }
}
