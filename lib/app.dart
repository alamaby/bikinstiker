import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/legal_consent_repository.dart';
import 'data/repositories/sticker_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/history/history_bloc.dart';
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

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthBlocState>(
          listenWhen: (p, n) => p.user?.id != n.user?.id,
          listener: (context, state) {
            final wallet = context.read<WalletBloc>();
            final history = context.read<HistoryBloc>();
            final stickerGen = context.read<StickerGenBloc>();
            final prevUser = context.read<AuthBloc>().state.user;
            if (state.user != null) {
              wallet.add(WalletWatchStarted(state.user!.id));
              // If user changed from guest to registered, reset guest sticker
              if (prevUser?.isAnonymous == true &&
                  state.user?.isAnonymous != true) {
                stickerGen.add(const StickerGenReset());
              }
            } else {
              wallet.add(const WalletWatchStopped());
              history.add(const HistoryCleared());
            }
          },
        ),
        BlocListener<AuthBloc, AuthBlocState>(
          listenWhen: (p, n) => p.status != n.status,
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated &&
                state.user?.isAnonymous == false) {
              // Could trigger bonus grant here if needed
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
            return LegalConsentScreen(
              onAccepted: () =>
                  context.read<AuthBloc>().add(const AuthStarted()),
            );
          }
          switch (state.status) {
            case AuthStatus.unknown:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case AuthStatus.authenticated:
              return const HomeScreen();
            case AuthStatus.unauthenticated:
              // After accepting terms, create anonymous session
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<AuthBloc>().add(const AuthAnonymousRequested());
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            case AuthStatus.guest:
              return const HomeScreen();
            case AuthStatus.submitting:
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
