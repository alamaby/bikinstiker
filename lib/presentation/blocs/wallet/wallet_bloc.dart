import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/wallet.dart';
import '../../../data/repositories/wallet_repository.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class WalletWatchStarted extends WalletEvent {
  final String userId;
  const WalletWatchStarted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class WalletWatchStopped extends WalletEvent {
  const WalletWatchStopped();
}

class WalletRefreshRequested extends WalletEvent {
  final String userId;
  const WalletRefreshRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class _WalletUpdated extends WalletEvent {
  final Wallet wallet;
  const _WalletUpdated(this.wallet);
  @override
  List<Object?> get props => [wallet];
}

class WalletBlocState extends Equatable {
  final Wallet? wallet;
  final bool loading;
  const WalletBlocState({this.wallet, this.loading = true});

  int get balance => wallet?.balance ?? 0;

  WalletBlocState copyWith({Wallet? wallet, bool? loading}) => WalletBlocState(
    wallet: wallet ?? this.wallet,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [wallet, loading];
}

class WalletBloc extends Bloc<WalletEvent, WalletBlocState> {
  final WalletRepository _repo;
  StreamSubscription<Wallet>? _sub;

  WalletBloc(this._repo) : super(const WalletBlocState()) {
    on<WalletWatchStarted>(_onStart);
    on<WalletWatchStopped>(_onStop);
    on<WalletRefreshRequested>(_onRefresh);
    on<_WalletUpdated>(
      (e, emit) => emit(state.copyWith(wallet: e.wallet, loading: false)),
    );
  }

  Future<void> _onStart(
    WalletWatchStarted e,
    Emitter<WalletBlocState> emit,
  ) async {
    await _sub?.cancel();
    emit(const WalletBlocState(loading: true));
    _sub = _repo.watchBalance(e.userId).listen((w) => add(_WalletUpdated(w)));
  }

  Future<void> _onStop(
    WalletWatchStopped e,
    Emitter<WalletBlocState> emit,
  ) async {
    await _sub?.cancel();
    _sub = null;
    emit(const WalletBlocState(loading: false));
  }

  Future<void> _onRefresh(
    WalletRefreshRequested e,
    Emitter<WalletBlocState> emit,
  ) async {
    final wallet = await _repo.fetchBalance(e.userId);
    if (wallet != null) {
      emit(state.copyWith(wallet: wallet, loading: false));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
