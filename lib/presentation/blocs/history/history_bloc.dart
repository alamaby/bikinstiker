import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/sticker_generation.dart';
import '../../../data/repositories/sticker_repository.dart';

// --- Enums ---

enum HistorySort { newest, oldest, presetAZ }

enum HistoryStatusFilter { all, success, pending, failed }

enum HistoryDateFilter { all, last7d, last30d, last90d }

extension HistorySortLabel on HistorySort {
  String get label => switch (this) {
        HistorySort.newest => 'Newest first',
        HistorySort.oldest => 'Oldest first',
        HistorySort.presetAZ => 'Preset A-Z',
      };
}

extension HistoryStatusFilterLabel on HistoryStatusFilter {
  String get label => switch (this) {
        HistoryStatusFilter.all => 'All',
        HistoryStatusFilter.success => 'Success',
        HistoryStatusFilter.pending => 'Pending',
        HistoryStatusFilter.failed => 'Failed',
      };
}

extension HistoryDateFilterLabel on HistoryDateFilter {
  String get label => switch (this) {
        HistoryDateFilter.all => 'All time',
        HistoryDateFilter.last7d => 'Last 7 days',
        HistoryDateFilter.last30d => 'Last 30 days',
        HistoryDateFilter.last90d => 'Last 90 days',
      };
}

// --- Events ---

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class HistoryRefreshed extends HistoryEvent {
  const HistoryRefreshed();
}

class HistoryCleared extends HistoryEvent {
  const HistoryCleared();
}

class HistorySortChanged extends HistoryEvent {
  final HistorySort sort;
  const HistorySortChanged(this.sort);
  @override
  List<Object?> get props => [sort];
}

class HistoryStatusFilterChanged extends HistoryEvent {
  final HistoryStatusFilter filter;
  const HistoryStatusFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class HistoryPresetFilterChanged extends HistoryEvent {
  final String? presetId;
  const HistoryPresetFilterChanged(this.presetId);
  @override
  List<Object?> get props => [presetId];
}

class HistoryDateFilterChanged extends HistoryEvent {
  final HistoryDateFilter filter;
  const HistoryDateFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class HistorySearchChanged extends HistoryEvent {
  final String query;
  const HistorySearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class HistoryFiltersCleared extends HistoryEvent {
  const HistoryFiltersCleared();
}

// --- State ---

enum HistoryStatus { idle, loading, success, failure }

class HistoryBlocState extends Equatable {
  final HistoryStatus status;
  final List<StickerGeneration> items;
  final String? errorMessage;

  final HistorySort sort;
  final HistoryStatusFilter statusFilter;
  final String? presetFilter;
  final HistoryDateFilter dateFilter;
  final String searchQuery;

  const HistoryBlocState({
    this.status = HistoryStatus.idle,
    this.items = const [],
    this.errorMessage,
    this.sort = HistorySort.newest,
    this.statusFilter = HistoryStatusFilter.all,
    this.presetFilter,
    this.dateFilter = HistoryDateFilter.all,
    this.searchQuery = '',
  });

  bool get hasActiveFilters =>
      statusFilter != HistoryStatusFilter.all ||
      presetFilter != null ||
      dateFilter != HistoryDateFilter.all ||
      searchQuery.isNotEmpty;

  HistoryBlocState copyWith({
    HistoryStatus? status,
    List<StickerGeneration>? items,
    String? errorMessage,
    HistorySort? sort,
    HistoryStatusFilter? statusFilter,
    String? presetFilter,
    bool clearPresetFilter = false,
    HistoryDateFilter? dateFilter,
    String? searchQuery,
  }) {
    return HistoryBlocState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage,
      sort: sort ?? this.sort,
      statusFilter: statusFilter ?? this.statusFilter,
      presetFilter: clearPresetFilter ? null : (presetFilter ?? this.presetFilter),
      dateFilter: dateFilter ?? this.dateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        errorMessage,
        sort,
        statusFilter,
        presetFilter,
        dateFilter,
        searchQuery,
      ];
}

// --- Bloc ---

class HistoryBloc extends Bloc<HistoryEvent, HistoryBlocState> {
  final StickerRepository _repo;
  HistoryBloc(this._repo) : super(const HistoryBlocState()) {
    on<HistoryRefreshed>(_onRefresh);
    on<HistoryCleared>((_, emit) => emit(const HistoryBlocState()));
    on<HistorySortChanged>(_onSortChanged);
    on<HistoryStatusFilterChanged>(_onStatusFilterChanged);
    on<HistoryPresetFilterChanged>(_onPresetFilterChanged);
    on<HistoryDateFilterChanged>(_onDateFilterChanged);
    on<HistorySearchChanged>(_onSearchChanged);
    on<HistoryFiltersCleared>(_onFiltersCleared);
  }

  Future<void> _onRefresh(
    HistoryRefreshed e,
    Emitter<HistoryBlocState> emit,
  ) async {
    await _refetch(emit);
  }

  Future<void> _onSortChanged(
    HistorySortChanged e,
    Emitter<HistoryBlocState> emit,
  ) async {
    emit(state.copyWith(sort: e.sort));
    await _refetch(emit);
  }

  Future<void> _onStatusFilterChanged(
    HistoryStatusFilterChanged e,
    Emitter<HistoryBlocState> emit,
  ) async {
    emit(state.copyWith(statusFilter: e.filter));
    await _refetch(emit);
  }

  Future<void> _onPresetFilterChanged(
    HistoryPresetFilterChanged e,
    Emitter<HistoryBlocState> emit,
  ) async {
    emit(state.copyWith(
      presetFilter: e.presetId,
      clearPresetFilter: e.presetId == null,
    ));
    await _refetch(emit);
  }

  Future<void> _onDateFilterChanged(
    HistoryDateFilterChanged e,
    Emitter<HistoryBlocState> emit,
  ) async {
    emit(state.copyWith(dateFilter: e.filter));
    await _refetch(emit);
  }

  Future<void> _onSearchChanged(
    HistorySearchChanged e,
    Emitter<HistoryBlocState> emit,
  ) async {
    emit(state.copyWith(searchQuery: e.query));
    await _refetch(emit);
  }

  Future<void> _onFiltersCleared(
    HistoryFiltersCleared e,
    Emitter<HistoryBlocState> emit,
  ) async {
    emit(const HistoryBlocState());
    await _refetch(emit);
  }

  Future<void> _refetch(Emitter<HistoryBlocState> emit) async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      final list = await _repo.fetchHistory(
        limit: 100,
        sortBy: _sortToDbColumn(state.sort),
        sortAscending: state.sort == HistorySort.oldest,
        status: _statusToDb(state.statusFilter),
        presetName: state.presetFilter,
        createdAfter: _dateAfter(state.dateFilter),
        searchPrompt: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      emit(state.copyWith(
        status: HistoryStatus.success,
        items: list,
      ));
    } catch (err) {
      emit(state.copyWith(
        status: HistoryStatus.failure,
        errorMessage: err.toString(),
      ));
    }
  }

  String _sortToDbColumn(HistorySort sort) => switch (sort) {
        HistorySort.presetAZ => 'preset_name',
        _ => 'created_at',
      };

  String? _statusToDb(HistoryStatusFilter filter) => switch (filter) {
        HistoryStatusFilter.all => null,
        HistoryStatusFilter.success => 'success',
        HistoryStatusFilter.pending => 'pending',
        HistoryStatusFilter.failed => 'failed',
      };

  DateTime? _dateAfter(HistoryDateFilter filter) {
    final now = DateTime.now().toUtc();
    return switch (filter) {
      HistoryDateFilter.all => null,
      HistoryDateFilter.last7d => now.subtract(const Duration(days: 7)),
      HistoryDateFilter.last30d => now.subtract(const Duration(days: 30)),
      HistoryDateFilter.last90d => now.subtract(const Duration(days: 90)),
    };
  }
}
