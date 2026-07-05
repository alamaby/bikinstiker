import 'dart:io' show Platform;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service that provides AdMob configuration from environment variables.
/// Falls back to test IDs when env vars are absent (dev mode).
class AdConfigService {
  static const _testAdUnitIds = {
    'android': 'ca-app-pub-3940256099942544/5224354917',
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

  /// Whether a real production ad unit is configured for this location.
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
enum AdBannerLocation {
  home,
  history,
  missions,
  profile,
  packs,
}
