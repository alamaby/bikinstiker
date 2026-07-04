import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/models/credit_transaction.dart';
import '../../../data/repositories/credit_transaction_repository.dart';

// --- Events ---

sealed class CreditTransactionsEvent extends Equatable {
  const CreditTransactionsEvent();
  @override
  List<Object?> get props => [];
}

class CreditTransactionsStarted extends CreditTransactionsEvent {
  final String userId;
  const CreditTransactionsStarted(this.userId);
  @override
  List<Object?> get props => [userId];
}

class CreditTransactionsRefreshed extends CreditTransactionsEvent {
  const CreditTransactionsRefreshed();
}

enum CreditTransactionsFilter { all, earnings, spent, rewards }

class CreditTransactionsFilterChanged extends CreditTransactionsEvent {
  final CreditTransactionsFilter filter;
  const CreditTransactionsFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class CreditTransactionsViewAllRequested extends CreditTransactionsEvent {
  const CreditTransactionsViewAllRequested();
}

// --- State ---

enum CreditTransactionsStatus { initial, loading, loaded, error }

class CreditTransactionsState extends Equatable {
  final CreditTransactionsStatus status;
  final List<CreditTransaction> transactions;
  final CreditTransactionsFilter filter;
  final String? error;
  final String? userId;

  const CreditTransactionsState({
    this.status = CreditTransactionsStatus.initial,
    this.transactions = const [],
    this.filter = CreditTransactionsFilter.all,
    this.error,
    this.userId,
  });

  CreditTransactionsState copyWith({
    CreditTransactionsStatus? status,
    List<CreditTransaction>? transactions,
    CreditTransactionsFilter? filter,
    String? error,
    String? userId,
  }) {
    return CreditTransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      filter: filter ?? this.filter,
      error: error,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [status, transactions, filter, error, userId];
}

// --- Bloc ---

class CreditTransactionsBloc
    extends Bloc<CreditTransactionsEvent, CreditTransactionsState> {
  final CreditTransactionRepository _repo;

  CreditTransactionsBloc(this._repo) : super(const CreditTransactionsState()) {
    on<CreditTransactionsStarted>(_onStarted);
    on<CreditTransactionsRefreshed>(_onRefreshed);
    on<CreditTransactionsFilterChanged>(_onFilterChanged);
    on<CreditTransactionsViewAllRequested>(_onViewAll);
  }

  Future<void> _onStarted(
    CreditTransactionsStarted event,
    Emitter<CreditTransactionsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CreditTransactionsStatus.loading,
        userId: event.userId,
      ),
    );
    await _fetch(emit);
  }

  Future<void> _onRefreshed(
    CreditTransactionsRefreshed event,
    Emitter<CreditTransactionsState> emit,
  ) async {
    emit(state.copyWith(status: CreditTransactionsStatus.loading));
    await _fetch(emit);
  }

  Future<void> _onFilterChanged(
    CreditTransactionsFilterChanged event,
    Emitter<CreditTransactionsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CreditTransactionsStatus.loading,
        filter: event.filter,
      ),
    );
    await _fetch(emit);
  }

  Future<void> _onViewAll(
    CreditTransactionsViewAllRequested event,
    Emitter<CreditTransactionsState> emit,
  ) async {
    final userId = state.userId;
    if (userId == null) {
      emit(
        state.copyWith(
          status: CreditTransactionsStatus.error,
          error: 'User not authenticated',
        ),
      );
      return;
    }
    emit(state.copyWith(status: CreditTransactionsStatus.loading));
    try {
      final txs = await _repo.fetchTransactions(
        userId,
        types: _typesForFilter(state.filter),
        limit: 0,
      );
      emit(
        state.copyWith(
          status: CreditTransactionsStatus.loaded,
          transactions: txs,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CreditTransactionsStatus.error,
          error: e is Failure ? e.message : e.toString(),
        ),
      );
    }
  }

  Future<void> _fetch(Emitter<CreditTransactionsState> emit) async {
    final userId = state.userId;
    if (userId == null) {
      emit(
        state.copyWith(
          status: CreditTransactionsStatus.error,
          error: 'User not authenticated',
        ),
      );
      return;
    }
    try {
      final txs = await _repo.fetchTransactions(
        userId,
        types: _typesForFilter(state.filter),
      );
      emit(
        state.copyWith(
          status: CreditTransactionsStatus.loaded,
          transactions: txs,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: CreditTransactionsStatus.error,
          error: e is Failure ? e.message : e.toString(),
        ),
      );
    }
  }

  Set<CreditTxType>? _typesForFilter(CreditTransactionsFilter filter) {
    switch (filter) {
      case CreditTransactionsFilter.all:
        return null;
      case CreditTransactionsFilter.earnings:
        return const {
          CreditTxType.topup,
          CreditTxType.dailyReward,
          CreditTxType.refund,
          CreditTxType.subscriptionGrant,
          CreditTxType.missionReward,
          CreditTxType.adminGrant,
        };
      case CreditTransactionsFilter.spent:
        return const {CreditTxType.generateSticker};
      case CreditTransactionsFilter.rewards:
        return const {
          CreditTxType.dailyReward,
          CreditTxType.missionReward,
          CreditTxType.subscriptionGrant,
        };
    }
  }
}
