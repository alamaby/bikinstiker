import 'package:equatable/equatable.dart';

enum StickerFeedbackRating { down, up }

StickerFeedbackRating _ratingFrom(int raw) {
  return raw == 1 ? StickerFeedbackRating.up : StickerFeedbackRating.down;
}

int stickerFeedbackRatingValue(StickerFeedbackRating rating) {
  return rating == StickerFeedbackRating.up ? 1 : -1;
}

class StickerFeedback extends Equatable {
  final String stickerGenerationId;
  final String userId;
  final StickerFeedbackRating rating;
  final List<String> reasonTags;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StickerFeedback({
    required this.stickerGenerationId,
    required this.userId,
    required this.rating,
    required this.reasonTags,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  factory StickerFeedback.fromJson(Map<String, dynamic> json) {
    final rawTags = json['reason_tags'];
    return StickerFeedback(
      stickerGenerationId: json['sticker_generation_id'] as String,
      userId: json['user_id'] as String,
      rating: _ratingFrom(json['rating'] as int),
      reasonTags: rawTags is List
          ? rawTags.map((tag) => tag.toString()).toList(growable: false)
          : const [],
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
    stickerGenerationId,
    userId,
    rating,
    reasonTags,
    note,
    createdAt,
    updatedAt,
  ];
}
