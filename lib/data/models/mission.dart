import 'mission_reward.dart';
import 'user_subscription.dart';

class Mission {
  final String id;
  final String code;
  final String label;
  final String description;
  final int rewardCredits;
  final SubscriptionTier requiredTier;
  final int? maxCompletionsPerUser;
  final int? cooldownSeconds;
  final int? maxCompletionsPerDay;
  final String validationType;
  final int sortOrder;
  final List<MissionReward> rewards;

  const Mission({
    required this.id,
    required this.code,
    required this.label,
    required this.description,
    required this.rewardCredits,
    required this.requiredTier,
    this.maxCompletionsPerUser,
    this.cooldownSeconds,
    this.maxCompletionsPerDay,
    this.validationType = 'manual',
    required this.sortOrder,
    this.rewards = const [],
  });

  bool canAccess(SubscriptionTier userTier) {
    if (requiredTier == SubscriptionTier.free) return true;
    return userTier == SubscriptionTier.plus;
  }

  int rewardForTier(SubscriptionTier userTier) {
    final tierStr = userTier == SubscriptionTier.plus ? 'plus' : 'free';
    MissionReward? best;
    for (final r in rewards) {
      if (!r.isEffective) continue;
      if (!r.appliesToTier(tierStr)) continue;
      if (r.tier == tierStr) {
        best = r;
        break;
      }
      best ??= r;
    }
    return best?.rewardCredits ?? rewardCredits;
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    List<MissionReward> parsedRewards = const [];
    if (json['mission_rewards'] != null) {
      final raw = json['mission_rewards'];
      if (raw is List) {
        parsedRewards = raw
            .map((r) => MissionReward.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    }

    return Mission(
      id: json['id'] as String,
      code: json['code'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      rewardCredits: json['reward_credits'] as int,
      requiredTier: UserSubscription.parseTier(
        json['required_tier'] as String?,
      ),
      maxCompletionsPerUser: json['max_completions_per_user'] as int?,
      cooldownSeconds: json['cooldown_seconds'] as int?,
      maxCompletionsPerDay: json['max_completions_per_day'] as int?,
      validationType: json['validation_type'] as String? ?? 'manual',
      sortOrder: json['sort_order'] as int? ?? 100,
      rewards: parsedRewards,
    );
  }
}
