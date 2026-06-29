import 'package:equatable/equatable.dart';

enum StickerPresetRole { guest, free, plus }

StickerPresetRole _roleFrom(String? raw) {
  switch (raw) {
    case 'guest':
      return StickerPresetRole.guest;
    case 'plus':
      return StickerPresetRole.plus;
    case 'free':
    default:
      return StickerPresetRole.free;
  }
}

class StickerPreset extends Equatable {
  final String id;
  final String label;
  final String description;
  final String? emoji;
  final StickerPresetRole requiredRole;
  final DateTime? validFrom;
  final DateTime? validUntil;

  const StickerPreset({
    required this.id,
    required this.label,
    required this.description,
    this.emoji,
    required this.requiredRole,
    this.validFrom,
    this.validUntil,
  });

  factory StickerPreset.fromJson(Map<String, dynamic> json) {
    return StickerPreset(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      emoji: json['emoji'] as String?,
      requiredRole: _roleFrom(json['requiredRole'] as String?),
      validFrom: json['validFrom'] != null
          ? DateTime.parse(json['validFrom'] as String)
          : null,
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'] as String)
          : null,
    );
  }

  bool get isCurrentlyValid {
    final now = DateTime.now().toUtc();
    if (validFrom != null && validFrom!.isAfter(now)) return false;
    if (validUntil != null && validUntil!.isBefore(now)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
    id,
    label,
    description,
    emoji,
    requiredRole,
    validFrom,
    validUntil,
  ];

  @override
  String toString() {
    return 'StickerPreset(id: $id, label: $label, requiredRole: $requiredRole)';
  }
}
