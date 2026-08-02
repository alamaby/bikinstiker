import '../../data/models/mission.dart';
import '../../l10n/app_localizations.dart';

/// Localizes a DB-driven mission label via its stable code, falling back to
/// the server-provided label when no translation key exists yet.
String localizedMissionLabel(AppLocalizations l10n, Mission mission) {
  switch (mission.code) {
    case 'first_sticker':
      return l10n.missionFirstStickerLabel;
    case 'daily_login':
      return l10n.missionDailyLoginLabel;
    case 'try_all_presets':
      return l10n.missionTryAllPresetsLabel;
    case 'plus_first_3d':
      return l10n.missionPlusFirst3dLabel;
    case 'plus_streak_7':
      return l10n.missionPlusStreak7Label;
    case 'watch_video_ad':
      return l10n.missionWatchAdLabel;
    case 'share_app_daily':
      return l10n.missionShareLabel;
    default:
      return mission.label;
  }
}

String localizedMissionDescription(AppLocalizations l10n, Mission mission) {
  switch (mission.code) {
    case 'first_sticker':
      return l10n.missionFirstStickerDesc;
    case 'daily_login':
      return l10n.missionDailyLoginDesc;
    case 'try_all_presets':
      return l10n.missionTryAllPresetsDesc;
    case 'plus_first_3d':
      return l10n.missionPlusFirst3dDesc;
    case 'plus_streak_7':
      return l10n.missionPlusStreak7Desc;
    case 'watch_video_ad':
      return l10n.missionWatchAdDesc;
    case 'share_app_daily':
      return l10n.missionShareDesc;
    default:
      return mission.description;
  }
}
