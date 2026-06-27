import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/supabase_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/legal_consent_repository.dart';
import '../data/repositories/sticker_repository.dart';
import '../data/repositories/wallet_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final client = SupabaseBootstrap.client;
  final prefs = await SharedPreferences.getInstance();

  getIt.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(client),
  );
  getIt.registerLazySingleton<LegalConsentRepository>(
    () => LegalConsentRepository(prefs),
  );
  getIt.registerLazySingleton<WalletRepository>(
    () => SupabaseWalletRepository(client),
  );
  getIt.registerLazySingleton<StickerRepository>(
    () => SupabaseStickerRepository(client),
  );
}
