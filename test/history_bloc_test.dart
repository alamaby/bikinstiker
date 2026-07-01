import 'package:bikin_stiker/data/models/sticker_generation.dart';
import 'package:bikin_stiker/data/repositories/sticker_repository.dart';
import 'package:bikin_stiker/presentation/blocs/history/history_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStickerRepository extends Mock implements StickerRepository {}

void main() {
  late MockStickerRepository repo;
  late HistoryBloc bloc;

  setUp(() {
    repo = MockStickerRepository();
    bloc = HistoryBloc(repo);
    registerFallbackValue(StickerGeneration(
      id: '',
      userId: '',
      presetName: '',
      userPrompt: '',
      finalPrompt: '',
      imageUrl: null,
      cost: 0,
      status: StickerStatus.unknown,
      createdAt: DateTime(2026),
    ));
  });

  tearDown(() {
    bloc.close();
  });

  void stubFetchHistory() {
    when(() => repo.fetchHistory(
          limit: any(named: 'limit'),
          presetName: any(named: 'presetName'),
          status: any(named: 'status'),
          createdAfter: any(named: 'createdAfter'),
          createdBefore: any(named: 'createdBefore'),
          searchPrompt: any(named: 'searchPrompt'),
          sortBy: any(named: 'sortBy'),
          sortAscending: any(named: 'sortAscending'),
        )).thenAnswer((_) async => []);
  }

  void stubFetchHistoryWithItems(List<StickerGeneration> items) {
    when(() => repo.fetchHistory(
          limit: any(named: 'limit'),
          presetName: any(named: 'presetName'),
          status: any(named: 'status'),
          createdAfter: any(named: 'createdAfter'),
          createdBefore: any(named: 'createdBefore'),
          searchPrompt: any(named: 'searchPrompt'),
          sortBy: any(named: 'sortBy'),
          sortAscending: any(named: 'sortAscending'),
        )).thenAnswer((_) async => items);
  }

  StickerGeneration stubGen({
    String presetName = 'kawaii',
    StickerStatus status = StickerStatus.success,
    DateTime? createdAt,
  }) {
    return StickerGeneration(
      id: 'id-1',
      userId: 'user-1',
      presetName: presetName,
      userPrompt: 'a cute cat',
      finalPrompt: 'enhanced prompt',
      imageUrl: null,
      cost: 1,
      status: status,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
  }

  group('default state', () {
    test('has idle status, empty items, no filters', () {
      expect(bloc.state.status, HistoryStatus.idle);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.sort, HistorySort.newest);
      expect(bloc.state.statusFilter, HistoryStatusFilter.all);
      expect(bloc.state.presetFilter, isNull);
      expect(bloc.state.dateFilter, HistoryDateFilter.all);
      expect(bloc.state.searchQuery, isEmpty);
      expect(bloc.state.hasActiveFilters, isFalse);
    });
  });

  group('HistoryRefreshed', () {
    test('calls fetchHistory with default params', () async {
      stubFetchHistory();

      bloc.add(const HistoryRefreshed());
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: null,
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });

    test('emits loading then success with items', () async {
      final items = [stubGen()];
      stubFetchHistoryWithItems(items);

      bloc.add(const HistoryRefreshed());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<HistoryBlocState>()
              .having((s) => s.status, 'status', HistoryStatus.loading),
          isA<HistoryBlocState>()
              .having((s) => s.status, 'status', HistoryStatus.success)
              .having((s) => s.items.length, 'items.length', 1),
        ]),
      );
    });
  });

  group('HistorySortChanged', () {
    test('oldest sort triggers refetch with sortAscending=true', () async {
      stubFetchHistory();

      bloc.add(const HistorySortChanged(HistorySort.oldest));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: true,
            presetName: null,
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });

    test('presetAZ sort triggers refetch with sortBy=preset_name', () async {
      stubFetchHistory();

      bloc.add(const HistorySortChanged(HistorySort.presetAZ));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'preset_name',
            sortAscending: false,
            presetName: null,
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });
  });

  group('HistoryStatusFilterChanged', () {
    test('success filter triggers refetch with status=success', () async {
      stubFetchHistory();

      bloc.add(const HistoryStatusFilterChanged(HistoryStatusFilter.success));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: null,
            status: 'success',
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });

    test('all filter triggers refetch with status=null', () async {
      stubFetchHistory();

      bloc.add(const HistoryStatusFilterChanged(HistoryStatusFilter.all));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: null,
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });
  });

  group('HistoryPresetFilterChanged', () {
    test('preset filter triggers refetch with presetName', () async {
      stubFetchHistory();

      bloc.add(const HistoryPresetFilterChanged('kawaii'));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: 'kawaii',
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });

    test('clearing preset filter triggers refetch with presetName=null',
        () async {
      stubFetchHistory();

      bloc.add(const HistoryPresetFilterChanged(null));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: null,
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });
  });

  group('HistoryDateFilterChanged', () {
    test('last7d filter triggers refetch with createdAfter ~7 days ago',
        () async {
      stubFetchHistory();

      bloc.add(const HistoryDateFilterChanged(HistoryDateFilter.last7d));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      final captured = verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: null,
            status: null,
            createdAfter: captureAny(named: 'createdAfter'),
            createdBefore: null,
            searchPrompt: null,
          )).captured.first as DateTime;

      final diff = DateTime.now().toUtc().difference(captured);
      expect(diff.inDays, greaterThanOrEqualTo(6));
      expect(diff.inDays, lessThanOrEqualTo(8));
    });

    test('all date filter triggers refetch with createdAfter=null', () async {
      stubFetchHistory();

      bloc.add(const HistoryDateFilterChanged(HistoryDateFilter.all));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: null,
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });
  });

  group('HistorySearchChanged', () {
    test('search triggers refetch with searchPrompt', () async {
      stubFetchHistory();

      bloc.add(const HistorySearchChanged('cat'));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: null,
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: 'cat',
          )).called(1);
    });

    test('empty search triggers refetch with searchPrompt=null', () async {
      stubFetchHistory();

      bloc.add(const HistorySearchChanged(''));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      verify(() => repo.fetchHistory(
            limit: 100,
            sortBy: 'created_at',
            sortAscending: false,
            presetName: null,
            status: null,
            createdAfter: null,
            createdBefore: null,
            searchPrompt: null,
          )).called(1);
    });
  });

  group('HistoryFiltersCleared', () {
    test('resets state to defaults', () async {
      stubFetchHistory();

      // Set some filters first
      bloc.add(const HistoryStatusFilterChanged(HistoryStatusFilter.failed));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      // Clear
      bloc.add(const HistoryFiltersCleared());
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.success);

      expect(bloc.state.sort, HistorySort.newest);
      expect(bloc.state.statusFilter, HistoryStatusFilter.all);
      expect(bloc.state.presetFilter, isNull);
      expect(bloc.state.dateFilter, HistoryDateFilter.all);
      expect(bloc.state.searchQuery, isEmpty);
      expect(bloc.state.hasActiveFilters, isFalse);
    });
  });

  group('hasActiveFilters', () {
    test('returns false when no filters set', () {
      expect(bloc.state.hasActiveFilters, isFalse);
    });

    test('returns true when status filter is not all', () {
      const state = HistoryBlocState(
        statusFilter: HistoryStatusFilter.success,
      );
      expect(state.hasActiveFilters, isTrue);
    });

    test('returns true when preset filter is set', () {
      const state = HistoryBlocState(presetFilter: 'kawaii');
      expect(state.hasActiveFilters, isTrue);
    });

    test('returns true when date filter is not all', () {
      const state = HistoryBlocState(
        dateFilter: HistoryDateFilter.last7d,
      );
      expect(state.hasActiveFilters, isTrue);
    });

    test('returns true when search query is not empty', () {
      const state = HistoryBlocState(searchQuery: 'cat');
      expect(state.hasActiveFilters, isTrue);
    });
  });
}
