class MissionProgress {
  final String id;
  final String userId;
  final String missionId;
  final DateTime completedAt;
  final int creditsAwarded;

  const MissionProgress({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.completedAt,
    required this.creditsAwarded,
  });

  factory MissionProgress.fromJson(Map<String, dynamic> json) {
    return MissionProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      missionId: json['mission_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      creditsAwarded: json['credits_awarded'] as int,
    );
  }
}
