import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin bootstrap for Supabase. Reads credentials from .env (assets).
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
    final url = dotenv.env['SUPABASE_URL'];
    // New-style publishable key (sb_publishable_...) preferred; the legacy
    // anon key is still accepted during the migration window.
    final anonKey =
        dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
        dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY (or legacy '
        'SUPABASE_ANON_KEY) in .env. Copy .env.example.',
      );
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String? get googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'];
}
