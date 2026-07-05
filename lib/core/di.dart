import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/supabase_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/credit_transaction_repository.dart';
import '../data/repositories/legal_consent_repository.dart';
import '../data/repositories/mission_repository.dart';
import '../data/repositories/preset_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/rewarded_ad_repository.dart';
import '../data/repositories/sticker_feedback_repository.dart';
import '../data/repositories/sticker_pack_repository.dart';
import '../data/repositories/sticker_repository.dart';
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/wallet_repository.dart';
import 'image_cache.dart';
import 'services/ad_config_service.dart';

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
  getIt.registerLazySingleton<ImageCacheService>(() => ImageCacheService());
  getIt.registerLazySingleton<StickerRepository>(
    () => SupabaseStickerRepository(client, getIt<ImageCacheService>()),
  );
  getIt.registerLazySingleton<StickerFeedbackRepository>(
    () => SupabaseStickerFeedbackRepository(client),
  );
  getIt.registerLazySingleton<PresetRepository>(
    () => SupabasePresetRepository(client),
  );
  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SupabaseSubscriptionRepository(client),
  );
  getIt.registerLazySingleton<MissionRepository>(
    () => SupabaseMissionRepository(client),
  );
  getIt.registerLazySingleton<StickerPackRepository>(
    () => SupabaseStickerPackRepository(client),
  );
  getIt.registerLazySingleton<RewardedAdRepository>(
    () => RewardedAdRepository(),
  );
  getIt.registerLazySingleton<ProfileRepository>(
    () => SupabaseProfileRepository(client),
  );
  getIt.registerLazySingleton<CreditTransactionRepository>(
    () => SupabaseCreditTransactionRepository(client),
  );
  getIt.registerLazySingleton<AdConfigService>(() => AdConfigService());
}
