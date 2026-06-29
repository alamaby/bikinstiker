import 'user_subscription.dart';

class Mission {
  final String id;
  final String code;
  final String label;
  final String description;
  final int rewardCredits;
  final SubscriptionTier requiredTier;
  final int? maxCompletionsPerUser;
  final int sortOrder;

  const Mission({
    required this.id,
    required this.code,
    required this.label,
    required this.description,
    required this.rewardCredits,
    required this.requiredTier,
    this.maxCompletionsPerUser,
    required this.sortOrder,
  });

  bool canAccess(SubscriptionTier userTier) {
    if (requiredTier == SubscriptionTier.free) return true;
    return userTier == SubscriptionTier.plus;
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
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
      sortOrder: json['sort_order'] as int? ?? 100,
    );
  }
}
