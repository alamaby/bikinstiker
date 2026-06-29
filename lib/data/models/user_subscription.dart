enum SubscriptionTier { free, plus }

class UserSubscription {
  final String id;
  final String userId;
  final SubscriptionTier tier;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool isActive;

  const UserSubscription({
    required this.id,
    required this.userId,
    required this.tier,
    required this.startedAt,
    required this.expiresAt,
    required this.isActive,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPlus => tier == SubscriptionTier.plus && !isExpired;

  static SubscriptionTier parseTier(String? value) {
    if (value == 'plus') return SubscriptionTier.plus;
    return SubscriptionTier.free;
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tier: parseTier(json['tier'] as String?),
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
