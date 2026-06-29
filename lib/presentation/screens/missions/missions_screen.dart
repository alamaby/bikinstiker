import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/mission.dart';
import '../../data/models/user_subscription.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/mission/mission_bloc.dart';
import '../blocs/subscription/subscription_bloc.dart';
import '../widgets/tier_badge.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Sign in required')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Missions')),
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, subState) {
          return BlocBuilder<MissionBloc, MissionState>(
            builder: (context, state) {
              if (state.status == MissionStatus.initial) {
                context.read<MissionBloc>().add(MissionLoadRequested(userId));
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

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MissionBloc>().add(MissionLoadRequested(userId));
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.missions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final mission = state.missions[index];
                    return _MissionTile(
                      mission: mission,
                      completions: state.completionsFor(mission.id),
                      canAccess: mission.canAccess(userTier),
                      isCompleting: state.status == MissionStatus.completing,
                      onComplete: () {
                        context.read<MissionBloc>().add(
                          MissionCompleteRequested(userId, mission.id),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final Mission mission;
  final int completions;
  final bool canAccess;
  final bool isCompleting;
  final VoidCallback onComplete;

  const _MissionTile({
    required this.mission,
    required this.completions,
    required this.canAccess,
    required this.isCompleting,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final maxedOut =
        mission.maxCompletionsPerUser != null &&
        completions >= mission.maxCompletionsPerUser!;
    final canComplete = canAccess && !maxedOut && !isCompleting;

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
                if (maxedOut)
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
                else
                  FilledButton(
                    onPressed: canComplete ? onComplete : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: isCompleting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Claim', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
