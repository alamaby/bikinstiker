class MissionReward {
  final String? tier;
  final int rewardCredits;
  final String? seasonId;
  final double? seasonMultiplier;
  final DateTime? effectiveFrom;
  final DateTime? effectiveUntil;

  const MissionReward({
    this.tier,
    required this.rewardCredits,
    this.seasonId,
    this.seasonMultiplier,
    this.effectiveFrom,
    this.effectiveUntil,
  });

  bool get isEffective {
    final now = DateTime.now();
    if (effectiveFrom != null && now.isBefore(effectiveFrom!)) return false;
    if (effectiveUntil != null && now.isAfter(effectiveUntil!)) return false;
    return true;
  }

  bool appliesToTier(String userTier) => tier == null || tier == userTier;

  factory MissionReward.fromJson(Map<String, dynamic> json) {
    return MissionReward(
      tier: json['tier'] as String?,
      rewardCredits: json['reward_credits'] as int,
      seasonId: json['season_id'] as String?,
      seasonMultiplier: json['season_multiplier'] != null
          ? (json['season_multiplier'] as num).toDouble()
          : null,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.parse(json['effective_from'] as String)
          : null,
      effectiveUntil: json['effective_until'] != null
          ? DateTime.parse(json['effective_until'] as String)
          : null,
    );
  }
}
