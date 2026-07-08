import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service that provides AdMob configuration from environment variables.
/// Falls back to test IDs when env vars are absent (dev mode).
class AdConfigService {
  static const _testAdUnitIds = {
    'android': 'ca-app-pub-3940256099942544/6300978111',
    'ios': 'ca-app-pub-3940256099942544/2934735716',
  };

  /// AdMob App ID from env or empty string.
  String get appId => dotenv.env['ADMOB_APP_ID'] ?? '';

  /// Whether a real ADMOB_APP_ID is configured (not just a placeholder).
  bool get hasAppId =>
      appId.isNotEmpty && !appId.contains('XXXXXXX') && appId.contains('~');

  /// Banner ad unit ID for a given location.
  /// Falls back to test IDs when env var is absent or placeholder.
  String bannerAdUnitId(AdBannerLocation location) {
    final key = _bannerEnvKey(location);
    final value = dotenv.env[key] ?? '';
    if (value.isEmpty || value.contains('XXXXXXX')) {
      return _testAdUnitId;
    }
    return value;
  }

  /// Rewarded ad unit ID from env, falling back to test IDs.
  String rewardedAdUnitId() {
    final key = Platform.isIOS
        ? 'ADMOB_REWARDED_IOS'
        : 'ADMOB_REWARDED_ANDROID';
    final value = dotenv.env[key] ?? '';
    if (value.isEmpty || value.contains('XXXXXXX')) {
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    return value;
  }

  /// Whether a real production rewarded ad unit is configured.
  bool get hasProductionRewardedId {
    final key = Platform.isIOS
        ? 'ADMOB_REWARDED_IOS'
        : 'ADMOB_REWARDED_ANDROID';
    final value = dotenv.env[key] ?? '';
    return value.isNotEmpty &&
        !value.contains('XXXXXXX') &&
        value.contains('/');
  }

  bool hasProductionBannerId(AdBannerLocation location) {
    final value = dotenv.env[_bannerEnvKey(location)] ?? '';
    return value.isNotEmpty &&
        !value.contains('XXXXXXX') &&
        value.contains('/');
  }

  String _bannerEnvKey(AdBannerLocation location) {
    switch (location) {
      case AdBannerLocation.home:
        return 'ADMOB_BANNER_HOME';
      case AdBannerLocation.history:
        return 'ADMOB_BANNER_HISTORY';
      case AdBannerLocation.missions:
        return 'ADMOB_BANNER_MISSIONS';
      case AdBannerLocation.profile:
        return 'ADMOB_BANNER_PROFILE';
      case AdBannerLocation.packs:
        return 'ADMOB_BANNER_PACKS';
    }
  }

  String get _testAdUnitId {
    if (Platform.isIOS) return _testAdUnitIds['ios']!;
    return _testAdUnitIds['android']!;
  }
}

/// Enum matching the 5 banner ad placement locations.
enum AdBannerLocation { home, history, missions, profile, packs }
