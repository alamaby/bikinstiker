import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../data/models/showcase_listing.dart';
import '../../../data/repositories/showcase_repository.dart';

enum ShowcaseStatus { initial, loading, loaded, error }

class ShowcaseState extends Equatable {
  final ShowcaseStatus status;
  final List<ShowcaseListing> listings;
  final String query;
  final String? tag;
  final ShowcaseSort sort;
  final String? errorMessage;

  const ShowcaseState({
    this.status = ShowcaseStatus.initial,
    this.listings = const [],
    this.query = '',
    this.tag,
    this.sort = ShowcaseSort.trending,
    this.errorMessage,
  });

  bool get isLoading => status == ShowcaseStatus.loading;
  bool get isInitial => status == ShowcaseStatus.initial;

  ShowcaseState copyWith({
    ShowcaseStatus? status,
    List<ShowcaseListing>? listings,
    String? query,
    Object? tag = _unset,
    ShowcaseSort? sort,
    String? errorMessage,
  }) {
    return ShowcaseState(
      status: status ?? this.status,
      listings: listings ?? this.listings,
      query: query ?? this.query,
      tag: identical(tag, _unset) ? this.tag : tag as String?,
      sort: sort ?? this.sort,
      errorMessage: errorMessage,
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props =>
      [status, listings, query, tag, sort, errorMessage];
}

class ShowcaseCubit extends Cubit<ShowcaseState> {
  final ShowcaseRepository _repo;

  ShowcaseCubit(this._repo) : super(const ShowcaseState());

  /// [silent] mempertahankan list lama tanpa flash spinner (dipakai saat
  /// kembali dari layar detail). Error saat silent tidak mengosongkan grid.
  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(status: ShowcaseStatus.loading));
    }
    try {
      final listings = await _repo.search(
        query: state.query.isEmpty ? null : state.query,
        tag: state.tag,
        sort: state.sort,
      );
      emit(state.copyWith(
        status: ShowcaseStatus.loaded,
        listings: listings,
        errorMessage: null,
      ));
    } on Failure catch (f) {
      final keepList = silent && state.listings.isNotEmpty;
      emit(state.copyWith(
        status: keepList ? ShowcaseStatus.loaded : ShowcaseStatus.error,
        errorMessage: f.message,
      ));
    } catch (e) {
      final keepList = silent && state.listings.isNotEmpty;
      emit(state.copyWith(
        status: keepList ? ShowcaseStatus.loaded : ShowcaseStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> setQuery(String query) async {
    if (query == state.query) return;
    emit(state.copyWith(query: query));
    await refresh();
  }

  Future<void> setTag(String? tag) async {
    if (tag == state.tag) return;
    emit(state.copyWith(tag: tag));
    await refresh();
  }

  Future<void> setSort(ShowcaseSort sort) async {
    if (sort == state.sort) return;
    emit(state.copyWith(sort: sort));
    await refresh();
  }
}
