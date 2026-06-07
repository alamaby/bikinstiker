import 'package:get_it/get_it.dart';

import '../data/datasources/supabase_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/sticker_repository.dart';
import '../data/repositories/wallet_repository.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  final client = SupabaseBootstrap.client;

  getIt.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepository(client),
  );
  getIt.registerLazySingleton<WalletRepository>(
    () => SupabaseWalletRepository(client),
  );
  getIt.registerLazySingleton<StickerRepository>(
    () => SupabaseStickerRepository(client),
  );
}
