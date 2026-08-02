import '../../data/models/sticker_preset.dart';
import '../../l10n/app_localizations.dart';

/// Localizes a DB-driven preset label via its stable id, falling back to the
/// server-provided English label when no translation key exists yet.
String localizedPresetLabel(AppLocalizations l10n, StickerPreset preset) {
  switch (preset.id) {
    case 'kawaii':
      return l10n.presetKawaiiLabel;
    case 'pixel_art':
      return l10n.presetPixelArtLabel;
    case 'vector_flat':
      return l10n.presetVectorFlatLabel;
    case 'chibi_3d':
      return l10n.presetChibi3dLabel;
    case 'retro_sticker':
      return l10n.presetRetroStickerLabel;
    default:
      return preset.label;
  }
}

String localizedPresetDescription(AppLocalizations l10n, StickerPreset preset) {
  switch (preset.id) {
    case 'kawaii':
      return l10n.presetKawaiiDesc;
    case 'pixel_art':
      return l10n.presetPixelArtDesc;
    case 'vector_flat':
      return l10n.presetVectorFlatDesc;
    case 'chibi_3d':
      return l10n.presetChibi3dDesc;
    case 'retro_sticker':
      return l10n.presetRetroStickerDesc;
    default:
      return preset.description;
  }
}
