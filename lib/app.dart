import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'l10n/app_localizations.dart';
import 'core/di.dart';
import 'core/theme/app_theme.dart';
import 'data/models/sticker_preset.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/credit_transaction_repository.dart';
import 'data/repositories/legal_consent_repository.dart';
import 'data/repositories/locale_repository.dart';
import 'data/repositories/mission_repository.dart';
import 'data/repositories/preset_repository.dart';
import 'data/repositories/onboarding_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/rewarded_ad_repository.dart';
import 'data/repositories/sticker_feedback_repository.dart';
import 'data/repositories/sticker_pack_repository.dart';
import 'data/repositories/sticker_repository.dart';
import 'data/repositories/subscription_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'core/services/share_mission_service.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/history/history_bloc.dart';
import 'presentation/blocs/locale/locale_cubit.dart';
import 'presentation/blocs/locale/locale_state.dart';
import 'presentation/blocs/mission/mission_bloc.dart';
import 'presentation/blocs/preset/preset_bloc.dart';
import 'presentation/blocs/sticker_pack/sticker_pack_bloc.dart';
import 'presentation/blocs/home_prefill/home_prefill_cubit.dart';
import 'presentation/blocs/surprise_me/surprise_me_cubit.dart';
import 'presentation/blocs/sticker_gen/sticker_gen_bloc.dart';
import 'presentation/blocs/subscription/subscription_bloc.dart';
import 'presentation/blocs/wallet/wallet_bloc.dart';
import 'presentation/blocs/legal_consent/legal_consent_cubit.dart';
import 'presentation/blocs/legal_consent/legal_consent_state.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/legal/legal_consent_error_screen.dart';
import 'presentation/screens/legal/legal_consent_screen.dart';
import 'presentation/screens/locale/language_selection_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

class BikinStikerApp extends StatelessWidget {
  const BikinStikerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: getIt<AuthRepository>(),
        ),
        RepositoryProvider<LegalConsentRepository>.value(
          value: getIt<LegalConsentRepository>(),
        ),
        RepositoryProvider<LocaleRepository>.value(
          value: getIt<LocaleRepository>(),
        ),
        RepositoryProvider<WalletRepository>.value(
          value: getIt<WalletRepository>(),
        ),
        RepositoryProvider<StickerRepository>.value(
          value: getIt<StickerRepository>(),
        ),
        RepositoryProvider<StickerFeedbackRepository>.value(
          value: getIt<StickerFeedbackRepository>(),
        ),
        RepositoryProvider<PresetRepository>.value(
          value: getIt<PresetRepository>(),
        ),
        RepositoryProvider<SubscriptionRepository>.value(
          value: getIt<SubscriptionRepository>(),
        ),
        RepositoryProvider<MissionRepository>.value(
          value: getIt<MissionRepository>(),
        ),
        RepositoryProvider<RewardedAdRepository>.value(
          value: getIt<RewardedAdRepository>(),
        ),
        RepositoryProvider<StickerPackRepository>.value(
          value: getIt<StickerPackRepository>(),
        ),
        RepositoryProvider<ProfileRepository>.value(
          value: getIt<ProfileRepository>(),
        ),
        RepositoryProvider<CreditTransactionRepository>.value(
          value: getIt<CreditTransactionRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) =>
                AuthBloc(ctx.read<AuthRepository>())..add(const AuthStarted()),
          ),
          BlocProvider(
            create: (ctx) => WalletBloc(ctx.read<WalletRepository>()),
          ),
          BlocProvider(
            create: (ctx) => StickerGenBloc(ctx.read<StickerRepository>()),
          ),
          BlocProvider(
            create: (ctx) => HistoryBloc(ctx.read<StickerRepository>()),
          ),
          BlocProvider(
            create: (ctx) => PresetBloc(ctx.read<PresetRepository>()),
          ),
          BlocProvider(
            create: (ctx) =>
                SubscriptionBloc(ctx.read<SubscriptionRepository>()),
          ),
          BlocProvider(
            create: (ctx) => MissionBloc(
              ctx.read<MissionRepository>(),
              ctx.read<RewardedAdRepository>(),
              shareService: getIt<ShareMissionService>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => StickerPackBloc(ctx.read<StickerPackRepository>()),
          ),
          BlocProvider(create: (_) => HomePrefillCubit()),
          BlocProvider(create: (_) => SurpriseMeCubit()),
          BlocProvider(
            create: (_) => LocaleCubit(
              getIt<LocaleRepository>(),
              platformLocale: WidgetsBinding.instance.platformDispatcher.locale,
            ),
          ),
          BlocProvider(
            create: (ctx) => LegalConsentCubit(
              ctx.read<LegalConsentRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            return MaterialApp(
              title: 'BikinStiker',
              locale: localeState.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: ThemeMode.system,
              debugShowCheckedModeBanner: false,
              home: const _AuthGate(),
            );
          },
        ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _anonymousRequested = false;
  bool _startingGuestSession = false;
  User? _previousUser;
  String _consentKey = '';

  StickerPresetRole _roleFor(AuthBlocState auth, SubscriptionState subState) {
    if (auth.user == null) return StickerPresetRole.guest;
    if (auth.isGuest) return StickerPresetRole.guest;
    return subState.isPlus ? StickerPresetRole.plus : StickerPresetRole.free;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthBlocState>(
          listenWhen: (p, n) =>
              p.user?.id != n.user?.id ||
              p.user?.isAnonymous != n.user?.isAnonymous,
          listener: (context, state) {
            final wallet = context.read<WalletBloc>();
            final history = context.read<HistoryBloc>();
            final stickerGen = context.read<StickerGenBloc>();
            final preset = context.read<PresetBloc>();
            final subscription = context.read<SubscriptionBloc>();
            final mission = context.read<MissionBloc>();
            final stickerPacks = context.read<StickerPackBloc>();
            if (state.user != null) {
              final isUserIdChanged =
                  _previousUser != null && _previousUser!.id != state.user!.id;
              wallet.add(WalletWatchStarted(state.user!.id));
              wallet.add(WalletRefreshRequested(state.user!.id));
              subscription.add(SubscriptionWatchStarted(state.user!.id));
              mission.add(MissionLoadRequested(state.user!.id));
              stickerPacks.add(const StickerPackLoadRequested());
              preset.add(
                PresetRefreshRequested(
                  role: _roleFor(state, context.read<SubscriptionBloc>().state),
                ),
              );
              if (isUserIdChanged) {
                history.add(const HistoryCleared());
                stickerGen.add(const StickerGenReset());
                stickerPacks.add(const StickerPackDetailCleared());
              } else if (_previousUser?.isAnonymous == true &&
                  state.user?.isAnonymous != true) {
                stickerGen.add(const StickerGenReset());
              }
            } else {
              wallet.add(const WalletWatchStopped());
              subscription.add(const SubscriptionWatchStopped());
              history.add(const HistoryCleared());
              stickerGen.add(const StickerGenReset());
              preset.add(const PresetCleared());
              stickerPacks.add(const StickerPackDetailCleared());
              _previousUser = null;
            }
            _previousUser = state.user;
          },
        ),
        BlocListener<AuthBloc, AuthBlocState>(
          listenWhen: (p, n) => p.status != n.status,
          listener: (context, state) {
            if (state.status == AuthStatus.guest ||
                state.status == AuthStatus.authenticated) {
              _anonymousRequested = false;
              _startingGuestSession = false;
            }
          },
        ),
        BlocListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (p, n) =>
              p.subscription?.tier != n.subscription?.tier ||
              p.subscription?.isExpired != n.subscription?.isExpired,
          listener: (context, state) {
            // Subscription tier changed -> wallet's pack_slot_cap changed server-side.
            // Refresh pack list (locked status may have flipped, slot cap may differ).
            if (context.read<AuthBloc>().state.user != null) {
              context.read<StickerPackBloc>().add(
                const StickerPackLoadRequested(),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, state) {
          final localeState = context.watch<LocaleCubit>().state;
          if (!localeState.explicitlySelected) {
            return const LanguageSelectionScreen();
          }
          final localeCode = localeState.locale.languageCode;
          final legal = context.watch<LegalConsentCubit>().state;

          switch (state.status) {
            case AuthStatus.unknown:
              return const _Splash();
            case AuthStatus.unauthenticated:
              if (!_anonymousRequested) {
                _anonymousRequested = true;
                _startingGuestSession = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.read<AuthBloc>().add(
                          const AuthAnonymousRequested(),
                        );
                  }
                });
              }
              return const _PreparingSession();
            case AuthStatus.submitting:
              if (_startingGuestSession) {
                return const _PreparingSession();
              }
              return const Stack(
                children: [
                  AuthScreen(),
                  Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
              );
            case AuthStatus.guest:
            case AuthStatus.authenticated:
              final userId = state.user!.id;
              final consentKey = '$userId|$localeCode';
              if (_consentKey != consentKey) {
                _consentKey = consentKey;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context
                        .read<LegalConsentCubit>()
                        .check(userId: userId, locale: localeCode);
                  }
                });
              }
              return _buildAfterUser(
                context,
                userId,
                localeCode,
                legal,
              );
          }
        },
      ),
    );
  }

  Widget _buildAfterUser(
    BuildContext context,
    String userId,
    String localeCode,
    LegalConsentState legal,
  ) {
    final consentCubit = context.read<LegalConsentCubit>();
    switch (legal.phase) {
      case LegalConsentPhase.ready:
        if (legal.status != null) {
          if (legal.status!.requiresAcceptance) {
            return LegalConsentScreen(
              status: legal.status!,
              submitting: legal.submitting,
              onAccept:
                  ({required termsSha256, required privacySha256}) async {
                await consentCubit.accept(
                  userId: userId,
                  locale: localeCode,
                  status: legal.status!,
                  termsSha256: termsSha256,
                  privacySha256: privacySha256,
                );
              },
            );
          }
          return _homeOrOnboarding(context);
        }
        return const _Splash();
      case LegalConsentPhase.error:
        return LegalConsentErrorScreen(
          message: legal.errorMessage ?? '',
          onRetry: () =>
              consentCubit.retry(userId: userId, locale: localeCode),
        );
      case LegalConsentPhase.loading:
        return const _Splash();
    }
  }

  Widget _homeOrOnboarding(BuildContext context) {
    final onboarding = getIt<OnboardingRepository>();
    if (!onboarding.hasCompletedCoreFlow) {
      return OnboardingScreen(onFinished: () => setState(() {}));
    }
    return const HomeScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PreparingSession extends StatelessWidget {
  const _PreparingSession();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.preparingGuestSession),
          ],
        ),
      ),
    );
  }
}
