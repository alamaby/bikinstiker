import 'dart:async';
import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/di.dart';
import '../../core/services/ad_config_service.dart';

/// Repository for handling rewarded video ads via Google Mobile Ads (AdMob).
class RewardedAdRepository {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _adLoaded = false;
  String? lastErrorMessage;

  final AdConfigService _adConfig = getIt<AdConfigService>();

  /// Initialize the Mobile Ads SDK. Call once at app startup.
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// Initialize with test device configuration. Use during development.
  /// Get your test device ID from logcat when running an app with AdMob
  /// (look for the line starting with "Use RequestConfiguration.Builder.setTestDeviceIds").
  static Future<void> initializeWithTestDevices(
    List<String> testDeviceIds,
  ) async {
    await MobileAds.instance.initialize();
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: testDeviceIds),
    );
  }

  /// Load a rewarded ad using the test ad unit ID.
  /// Returns true if ad is loaded and ready to show.
  Future<bool> loadAd() async {
    if (_isLoading || _adLoaded) return _adLoaded;

    _isLoading = true;
    lastErrorMessage = null;
    final completer = Completer<bool>();

    RewardedAd.load(
      adUnitId: _adConfig.rewardedAdUnitId(),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _adLoaded = true;
          _isLoading = false;
          lastErrorMessage = null;
          _setupFullScreenCallback();
          completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _adLoaded = false;
          _isLoading = false;
          lastErrorMessage = _formatAdError('load', error);
          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  /// Show the loaded rewarded ad.
  /// Returns true only if the user earned the reward (onUserEarnedReward fired).
  Future<bool> showAd() async {
    if (!_adLoaded || _rewardedAd == null) {
      return false;
    }

    final completer = Completer<bool>();
    bool rewardEarned = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _adLoaded = false;
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _adLoaded = false;
        lastErrorMessage = _formatFullScreenError('show', error);
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
      },
    );

    return completer.future;
  }

  /// Load and show in one call. Returns true if reward earned.
  Future<bool> loadAndShow() async {
    final loaded = await loadAd();
    if (!loaded) return false;
    return showAd();
  }

  void _setupFullScreenCallback() {
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _adLoaded = false;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _adLoaded = false;
      },
    );
  }

  String _formatAdError(String stage, LoadAdError error) {
    return 'Failed to $stage ad: code=${error.code}, '
        'domain=${error.domain}, message=${error.message}';
  }

  String _formatFullScreenError(String stage, AdError error) {
    return 'Failed to $stage ad: code=${error.code}, '
        'domain=${error.domain}, message=${error.message}';
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _adLoaded = false;
    lastErrorMessage = null;
  }
}
