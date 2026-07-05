import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'core/di.dart';
import 'data/datasources/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.init();

  // Initialize AdMob SDK with optional app ID from environment
  await MobileAds.instance.initialize();
  // AdMob App ID from env (only needed for production builds)
  // If not set, SDK falls back to test mode

  await configureDependencies();
  runApp(const BikinStikerApp());
}
