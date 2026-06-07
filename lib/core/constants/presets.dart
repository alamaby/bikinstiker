import 'package:flutter/material.dart';

/// Mirrors the PRESETS map in supabase/functions/generate-sticker/index.ts.
/// IDs MUST match exactly — they are the contract between client and server.
class StickerPreset {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  const StickerPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const List<StickerPreset> kStickerPresets = [
  StickerPreset(
    id: 'kawaii',
    label: 'Kawaii',
    description: 'Cute pastel chibi',
    icon: Icons.favorite,
  ),
  StickerPreset(
    id: 'pixel_art',
    label: 'Pixel Art',
    description: '16-bit retro pixels',
    icon: Icons.grid_4x4,
  ),
  StickerPreset(
    id: 'vector_flat',
    label: 'Vector Flat',
    description: 'Bold flat illustration',
    icon: Icons.shape_line,
  ),
  StickerPreset(
    id: 'chibi_3d',
    label: '3D Chibi',
    description: 'Glossy 3d render',
    icon: Icons.threed_rotation,
  ),
  StickerPreset(
    id: 'retro_sticker',
    label: 'Retro',
    description: '90s halftone vibe',
    icon: Icons.album,
  ),
];

const int kStickerCost = 1;
const int kMaxPromptChars = 200;
