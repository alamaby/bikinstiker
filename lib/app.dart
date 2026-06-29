import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'core/di.dart';
import 'core/theme/app_theme.dart';
import 'data/models/sticker_preset.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/legal_consent_repository.dart';
import 'data/repositories/preset_repository.dart';
import 'data/repositories/sticker_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/history/history_bloc.dart';
import 'presentation/blocs/preset/preset_bloc.dart';
import 'presentation/blocs/sticker_gen/sticker_gen_bloc.dart';
import 'presentation/blocs/wallet/wallet_bloc.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/legal/legal_consent_screen.dart';

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
        RepositoryProvider<WalletRepository>.value(
          value: getIt<WalletRepository>(),
        ),
        RepositoryProvider<StickerRepository>.value(
          value: getIt<StickerRepository>(),
        ),
        RepositoryProvider<PresetRepository>.value(
          value: getIt<PresetRepository>(),
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
        ],
        child: MaterialApp(
          title: 'BikinStiker',
          theme: AppTheme.light(),
          debugShowCheckedModeBanner: false,
          home: const _AuthGate(),
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

  StickerPresetRole _roleFor(AuthBlocState auth) {
    if (auth.user == null) return StickerPresetRole.guest;
    // TODO(subscription): read is_plus from user_wallets once it exists.
    return auth.isGuest ? StickerPresetRole.guest : StickerPresetRole.free;
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
            if (state.user != null) {
              final isUserIdChanged =
                  _previousUser != null && _previousUser!.id != state.user!.id;
              wallet.add(WalletWatchStarted(state.user!.id));
              wallet.add(WalletRefreshRequested(state.user!.id));
              preset.add(PresetRefreshRequested(role: _roleFor(state)));
              if (isUserIdChanged) {
                history.add(const HistoryCleared());
                stickerGen.add(const StickerGenReset());
              } else if (_previousUser?.isAnonymous == true &&
                  state.user?.isAnonymous != true) {
                stickerGen.add(const StickerGenReset());
              }
            } else {
              wallet.add(const WalletWatchStopped());
              history.add(const HistoryCleared());
              stickerGen.add(const StickerGenReset());
              preset.add(const PresetCleared());
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
      ],
      child: BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, state) {
          final hasAccepted = context
              .read<LegalConsentRepository>()
              .hasAcceptedCurrent;
          if (!hasAccepted) {
            _anonymousRequested = false;
            _startingGuestSession = false;
            return LegalConsentScreen(onAccepted: () => setState(() {}));
          }
          switch (state.status) {
            case AuthStatus.unknown:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case AuthStatus.authenticated:
              return const HomeScreen();
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
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Preparing your guest session...'),
                    ],
                  ),
                ),
              );
            case AuthStatus.guest:
              return const HomeScreen();
            case AuthStatus.submitting:
              if (_startingGuestSession) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Preparing your guest session...'),
                      ],
                    ),
                  ),
                );
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
          }
        },
      ),
    );
  }
}
