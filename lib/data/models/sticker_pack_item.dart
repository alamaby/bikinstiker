import 'package:equatable/equatable.dart';

/// Represents a sticker within a sticker pack, including its metadata
/// for WhatsApp export (emojis and accessibility text).
class StickerPackItem extends Equatable {
  final String id;
  final String packId;
  final String stickerGenerationId;
  final int position;
  final List<String> emojis;
  final String? accessibilityText;
  final DateTime addedAt;

  const StickerPackItem({
    required this.id,
    required this.packId,
    required this.stickerGenerationId,
    required this.position,
    required this.emojis,
    this.accessibilityText,
    required this.addedAt,
  });

  factory StickerPackItem.fromJson(Map<String, dynamic> json) =>
      StickerPackItem(
        id: json['id'] as String,
        packId: json['pack_id'] as String,
        stickerGenerationId: json['sticker_generation_id'] as String,
        position: json['position'] as int,
        emojis: List<String>.from(json['emojis'] as List),
        accessibilityText: json['accessibility_text'] as String?,
        addedAt: DateTime.parse(json['added_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'pack_id': packId,
    'sticker_generation_id': stickerGenerationId,
    'position': position,
    'emojis': emojis,
    'accessibility_text': accessibilityText,
    'added_at': addedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    packId,
    stickerGenerationId,
    position,
    emojis,
    accessibilityText,
    addedAt,
  ];
}
