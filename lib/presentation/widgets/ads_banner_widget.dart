import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/di.dart';
import '../../core/services/ad_config_service.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/subscription/subscription_bloc.dart';
import '../../core/theme/app_theme.dart';

export '../../core/services/ad_config_service.dart' show AdBannerLocation;

/// Ad banner widget that shows a real AdMob banner for eligible users.
/// Returns SizedBox.shrink() while loading or on error to avoid layout shift.
class AdsBannerWidget extends StatefulWidget {
  final AdBannerLocation location;

  const AdsBannerWidget({
    super.key,
    required this.location,
  });

  @override
  State<AdsBannerWidget> createState() => _AdsBannerWidgetState();
}

class _AdsBannerWidgetState extends State<AdsBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasError = false;
  bool _isEligible = true;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
    if (_isEligible) {
      _loadAd();
    }
  }

  void _checkEligibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      final subState = context.read<SubscriptionBloc>().state;
      final eligible = !authState.isGuest && !subState.isPlus;
      if (mounted) {
        setState(() {
          _isEligible = eligible;
          if (!eligible) {
            _hasError = true; // won't render
          }
        });
      }
    });
  }

  void _loadAd() {
    final config = getIt<AdConfigService>();
    final adUnitId = config.bannerAdUnitId(widget.location);

    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: ${error.message}');
          if (mounted) setState(() => _hasError = true);
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEligible || _hasError) {
      return const SizedBox.shrink();
    }

    if (!_isLoaded || _bannerAd == null) {
      return _Placeholder();
    }

    return Container(
      height: 64,
      width: double.infinity,
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.hairline),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ads_click, size: 16, color: context.textFaint),
            SizedBox(width: 6),
            Text(
              'Advertisement',
              style: TextStyle(
                fontSize: 12,
                color: context.textFaint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
