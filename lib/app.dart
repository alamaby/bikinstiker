import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/sticker_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/history/history_bloc.dart';
import 'presentation/blocs/sticker_gen/sticker_gen_bloc.dart';
import 'presentation/blocs/wallet/wallet_bloc.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/home/home_screen.dart';

class BikinStikerApp extends StatelessWidget {
  const BikinStikerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: getIt<AuthRepository>()),
        RepositoryProvider<WalletRepository>.value(value: getIt<WalletRepository>()),
        RepositoryProvider<StickerRepository>.value(value: getIt<StickerRepository>()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) =>
                AuthBloc(ctx.read<AuthRepository>())..add(const AuthStarted()),
          ),
          BlocProvider(create: (ctx) => WalletBloc(ctx.read<WalletRepository>())),
          BlocProvider(create: (ctx) => StickerGenBloc(ctx.read<StickerRepository>())),
          BlocProvider(create: (ctx) => HistoryBloc(ctx.read<StickerRepository>())),
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
    return BlocListener<AuthBloc, AuthBlocState>(
      listenWhen: (p, n) => p.user?.id != n.user?.id,
      listener: (context, state) {
        final wallet = context.read<WalletBloc>();
        final history = context.read<HistoryBloc>();
        if (state.user != null) {
          wallet.add(WalletWatchStarted(state.user!.id));
        } else {
          wallet.add(const WalletWatchStopped());
          history.add(const HistoryCleared());
        }
      },
      child: BlocBuilder<AuthBloc, AuthBlocState>(
        builder: (context, state) {
          switch (state.status) {
            case AuthStatus.unknown:
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            case AuthStatus.authenticated:
              return const HomeScreen();
            case AuthStatus.unauthenticated:
            case AuthStatus.submitting:
              return const AuthScreen();
          }
        },
      ),
    );
  }
}
