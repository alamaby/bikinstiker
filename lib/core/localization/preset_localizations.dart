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
    // Seasonal (Sep 2026 – Jan 2027) — see
    // plans/2026-08-27-seasonal-presets-plan.md.
    case 'back_to_school_doodle':
      return l10n.presetBackToSchoolDoodleLabel;
    case 'cozy_study_club':
      return l10n.presetCozyStudyClubLabel;
    case 'rainy_days':
      return l10n.presetRainyDaysLabel;
    case 'autumn_first_leaf':
      return l10n.presetAutumnFirstLeafLabel;
    case 'harvest_market':
      return l10n.presetHarvestMarketLabel;
    case 'friendly_spooky':
      return l10n.presetFriendlySpookyLabel;
    case 'witchy_potion_lab':
      return l10n.presetWitchyPotionLabLabel;
    case 'gothic_stained_glass':
      return l10n.presetGothicStainedGlassLabel;
    case 'pumpkin_patch_clay':
      return l10n.presetPumpkinPatchClayLabel;
    case 'night_forest_linocut':
      return l10n.presetNightForestLinocutLabel;
    case 'gratitude_journal':
      return l10n.presetGratitudeJournalLabel;
    case 'warm_kitchen_table':
      return l10n.presetWarmKitchenTableLabel;
    case 'woodland_sweater_club':
      return l10n.presetWoodlandSweaterClubLabel;
    case 'november_rain_noir':
      return l10n.presetNovemberRainNoirLabel;
    case 'deal_hunter_pop':
      return l10n.presetDealHunterPopLabel;
    case 'gingerbread_workshop':
      return l10n.presetGingerbreadWorkshopLabel;
    case 'frosted_paper_village':
      return l10n.presetFrostedPaperVillageLabel;
    case 'tropical_holiday_cheer':
      return l10n.presetTropicalHolidayCheerLabel;
    case 'midnight_new_year_chrome':
      return l10n.presetMidnightNewYearChromeLabel;
    case 'year_in_review_scrapbook':
      return l10n.presetYearInReviewScrapbookLabel;
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
    // Seasonal (Sep 2026 – Jan 2027).
    case 'back_to_school_doodle':
      return l10n.presetBackToSchoolDoodleDesc;
    case 'cozy_study_club':
      return l10n.presetCozyStudyClubDesc;
    case 'rainy_days':
      return l10n.presetRainyDaysDesc;
    case 'autumn_first_leaf':
      return l10n.presetAutumnFirstLeafDesc;
    case 'harvest_market':
      return l10n.presetHarvestMarketDesc;
    case 'friendly_spooky':
      return l10n.presetFriendlySpookyDesc;
    case 'witchy_potion_lab':
      return l10n.presetWitchyPotionLabDesc;
    case 'gothic_stained_glass':
      return l10n.presetGothicStainedGlassDesc;
    case 'pumpkin_patch_clay':
      return l10n.presetPumpkinPatchClayDesc;
    case 'night_forest_linocut':
      return l10n.presetNightForestLinocutDesc;
    case 'gratitude_journal':
      return l10n.presetGratitudeJournalDesc;
    case 'warm_kitchen_table':
      return l10n.presetWarmKitchenTableDesc;
    case 'woodland_sweater_club':
      return l10n.presetWoodlandSweaterClubDesc;
    case 'november_rain_noir':
      return l10n.presetNovemberRainNoirDesc;
    case 'deal_hunter_pop':
      return l10n.presetDealHunterPopDesc;
    case 'gingerbread_workshop':
      return l10n.presetGingerbreadWorkshopDesc;
    case 'frosted_paper_village':
      return l10n.presetFrostedPaperVillageDesc;
    case 'tropical_holiday_cheer':
      return l10n.presetTropicalHolidayCheerDesc;
    case 'midnight_new_year_chrome':
      return l10n.presetMidnightNewYearChromeDesc;
    case 'year_in_review_scrapbook':
      return l10n.presetYearInReviewScrapbookDesc;
    default:
      return preset.description;
  }
}
