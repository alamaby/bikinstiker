import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'core/di.dart';
import 'core/services/share_mission_service.dart';
import 'data/datasources/supabase_client.dart';
import 'data/models/share_token.dart';

/// Buffer for a share-claim deep link the app received while cold-starting.
/// The MissionsScreen reads this on first build and replays it through the
/// MissionBloc so a user who tapped a share link while the app was killed
/// still gets their credit.
ShareClaimResult? pendingColdStartShareClaim;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.init();

  // Initialize AdMob SDK with optional app ID from environment
  await MobileAds.instance.initialize();
  // AdMob App ID from env (only needed for production builds)
  // If not set, SDK falls back to test mode

  await configureDependencies();
  await _drainInitialShareDeepLink();
  runApp(const BikinStikerApp());
}

Future<void> _drainInitialShareDeepLink() async {
  final shareService = getIt<ShareMissionService>();
  final ShareClaimResult? claim = await shareService.consumeInitialLink();
  if (claim == null) return;
  pendingColdStartShareClaim = claim;
}
