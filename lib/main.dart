import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di.dart';
import 'data/datasources/supabase_client.dart';
import 'data/repositories/rewarded_ad_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.init();
  await RewardedAdRepository.initialize();
  await configureDependencies();
  runApp(const BikinStikerApp());
}
