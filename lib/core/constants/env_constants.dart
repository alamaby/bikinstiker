import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to .env values.
class EnvConstants {
  EnvConstants._();

  static String? get googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'];

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// New-style publishable key (sb_publishable_...) with legacy anon fallback.
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
      dotenv.env['SUPABASE_ANON_KEY'] ??
      '';
}
