import 'package:flutter/material.dart';

import 'ads_banner_widget.dart';

/// Ad banner placeholder — now uses the real AdsBannerWidget for home screen.
class AdsBannerPlaceholder extends StatelessWidget {
  const AdsBannerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdsBannerWidget(location: AdBannerLocation.home);
  }
}
