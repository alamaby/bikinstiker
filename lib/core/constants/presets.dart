import 'package:flutter/material.dart';

/// Mirrors the PRESETS map in supabase/functions/generate-sticker/index.ts.
/// IDs MUST match exactly — they are the contract between client and server.
class StickerPreset {
  final String id;
  final String label;
  final String description;
  final String emoji;

  const StickerPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.emoji,
  });
}

const List<StickerPreset> kStickerPresets = [
  StickerPreset(
    id: 'kawaii',
    label: 'Kawaii',
    description: 'Cute pastel chibi',
    emoji: '💖',
  ),
  StickerPreset(
    id: 'pixel_art',
    label: 'Pixel Art',
    description: '16-bit retro pixels',
    emoji: '🕹️',
  ),
  StickerPreset(
    id: 'vector_flat',
    label: 'Vector Flat',
    description: 'Bold flat illustration',
    emoji: '🎨',
  ),
  StickerPreset(
    id: 'chibi_3d',
    label: '3D Chibi',
    description: 'Glossy 3d render',
    emoji: '🧸',
  ),
  StickerPreset(
    id: 'retro_sticker',
    label: 'Retro',
    description: '90s halftone vibe',
    emoji: '📼',
  ),
];

const int kStickerCost = 1;
const int kMaxPromptChars = 200;
