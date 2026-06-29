import 'package:equatable/equatable.dart';

/// Represents a sticker pack that can contain 3-30 stickers
/// and be exported to WhatsApp as a native sticker pack.
class StickerPack extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String packIdentifier; // Unique identifier for WhatsApp (userId-packId)
  final String trayIconPath; // Storage path to tray icon PNG
  final int stickerCount;
  final bool isActive;
  final bool isLocked;
  final DateTime? lockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StickerPack({
    required this.id,
    required this.userId,
    required this.name,
    required this.packIdentifier,
    required this.trayIconPath,
    required this.stickerCount,
    required this.isActive,
    required this.isLocked,
    this.lockedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this pack can accept more stickers (not locked, active, and < 30 stickers)
  bool get canAddStickers => !isLocked && isActive && stickerCount < 30;

  /// Whether stickers can be removed from this pack
  bool get canRemoveStickers => !isLocked && isActive;

  /// Whether this pack can be renamed
  bool get canRename => !isLocked && isActive;

  /// Whether this pack can be deleted
  bool get canDelete => isActive;

  /// Whether this pack can be exported to WhatsApp (needs ≥3 stickers)
  bool get canExport => !isLocked && isActive && stickerCount >= 3;

  factory StickerPack.fromJson(Map<String, dynamic> json) => StickerPack(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    name: json['name'] as String,
    packIdentifier: json['pack_identifier'] as String,
    trayIconPath: json['tray_icon_path'] as String,
    stickerCount: json['sticker_count'] as int,
    isActive: json['is_active'] as bool,
    isLocked: json['is_locked'] as bool,
    lockedAt: json['locked_at'] != null
        ? DateTime.parse(json['locked_at'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'pack_identifier': packIdentifier,
    'tray_icon_path': trayIconPath,
    'sticker_count': stickerCount,
    'is_active': isActive,
    'is_locked': isLocked,
    'locked_at': lockedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    packIdentifier,
    trayIconPath,
    stickerCount,
    isActive,
    isLocked,
    lockedAt,
    createdAt,
    updatedAt,
  ];
}

/// Sort options for sticker pack lists
enum StickerPackSort { newest, oldest, nameAsc }
