import 'package:equatable/equatable.dart';

enum StickerStatus { pending, success, failed, unknown }

StickerStatus _statusFrom(String? raw) {
  switch (raw) {
    case 'pending':
      return StickerStatus.pending;
    case 'success':
      return StickerStatus.success;
    case 'failed':
      return StickerStatus.failed;
    default:
      return StickerStatus.unknown;
  }
}

class StickerGeneration extends Equatable {
  final String id;
  final String userId;
  final String presetName;
  final String userPrompt;
  final String finalPrompt;
  final String? imageUrl; // storage path, e.g. {userId}/{id}.png
  final int cost;
  final StickerStatus status;
  final DateTime createdAt;

  const StickerGeneration({
    required this.id,
    required this.userId,
    required this.presetName,
    required this.userPrompt,
    required this.finalPrompt,
    required this.imageUrl,
    required this.cost,
    required this.status,
    required this.createdAt,
  });

  factory StickerGeneration.fromJson(Map<String, dynamic> json) => StickerGeneration(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        presetName: json['preset_name'] as String,
        userPrompt: json['user_prompt'] as String,
        finalPrompt: json['final_prompt'] as String,
        imageUrl: json['image_url'] as String?,
        cost: json['cost'] as int,
        status: _statusFrom(json['status'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props =>
      [id, userId, presetName, userPrompt, finalPrompt, imageUrl, cost, status, createdAt];
}
