import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/user_subscription.dart';
import '../../../data/repositories/subscription_repository.dart';

sealed class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class SubscriptionWatchStarted extends SubscriptionEvent {
  final String userId;
  const SubscriptionWatchStarted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class SubscriptionWatchStopped extends SubscriptionEvent {
  const SubscriptionWatchStopped();
}

class SubscriptionRefreshRequested extends SubscriptionEvent {
  final String userId;
  const SubscriptionRefreshRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

class _SubscriptionUpdated extends SubscriptionEvent {
  final UserSubscription? subscription;
  const _SubscriptionUpdated(this.subscription);
  @override
  List<Object?> get props => [subscription];
}

enum SubscriptionStatus { unknown, loaded }

class SubscriptionState extends Equatable {
  final SubscriptionStatus status;
  final UserSubscription? subscription;

  const SubscriptionState({
    this.status = SubscriptionStatus.unknown,
    this.subscription,
  });

  bool get isPlus => subscription?.isPlus ?? false;
  bool get isExpired => subscription?.isExpired ?? true;

  SubscriptionState copyWith({
    UserSubscription? subscription,
    SubscriptionStatus? status,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      subscription: subscription ?? this.subscription,
    );
  }

  @override
  List<Object?> get props => [status, subscription];
}

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repo;
  StreamSubscription<UserSubscription?>? _sub;

  SubscriptionBloc(this._repo) : super(const SubscriptionState()) {
    on<SubscriptionWatchStarted>(_onStart);
    on<SubscriptionWatchStopped>(_onStop);
    on<SubscriptionRefreshRequested>(_onRefresh);
    on<_SubscriptionUpdated>(_onUpdated);
  }

  Future<void> _onStart(
    SubscriptionWatchStarted e,
    Emitter<SubscriptionState> emit,
  ) async {
    await _sub?.cancel();
    _sub = _repo
        .watchCurrent(e.userId)
        .listen((sub) => add(_SubscriptionUpdated(sub)));
  }

  Future<void> _onStop(
    SubscriptionWatchStopped e,
    Emitter<SubscriptionState> emit,
  ) async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _onRefresh(
    SubscriptionRefreshRequested e,
    Emitter<SubscriptionState> emit,
  ) async {
    final sub = await _repo.fetchCurrent(e.userId);
    emit(state.copyWith(subscription: sub, status: SubscriptionStatus.loaded));
  }

  void _onUpdated(_SubscriptionUpdated e, Emitter<SubscriptionState> emit) {
    emit(
      state.copyWith(
        subscription: e.subscription,
        status: SubscriptionStatus.loaded,
      ),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
