import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di.dart';
import 'data/datasources/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.init();
  configureDependencies();
  runApp(const BikinStikerApp());
}
