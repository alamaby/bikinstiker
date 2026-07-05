import 'package:bikin_stiker/data/models/credit_transaction.dart';
import 'package:bikin_stiker/data/repositories/credit_transaction_repository.dart';
import 'package:bikin_stiker/presentation/blocs/credit_transactions/credit_transactions_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreditTransactionRepository extends Mock
    implements CreditTransactionRepository {}

void main() {
  late MockCreditTransactionRepository repo;
  late CreditTransactionsBloc bloc;

  const testUserId = 'test-user-123';

  setUp(() {
    repo = MockCreditTransactionRepository();
    bloc = CreditTransactionsBloc(repo);
    registerFallbackValue(<CreditTxType>{});
  });

  tearDown(() {
    bloc.close();
  });

  group('default state', () {
    test('has initial status, empty transactions, and all filter', () {
      expect(bloc.state.status, CreditTransactionsStatus.initial);
      expect(bloc.state.transactions, isEmpty);
      expect(bloc.state.filter, CreditTransactionsFilter.all);
      expect(bloc.state.error, isNull);
    });
  });

  group('CreditTransactionsFilterChanged', () {
    test('Earnings filter passes income types set to repo', () async {
      Set<CreditTxType>? capturedTypes;
      int callCount = 0;

      when(() => repo.fetchTransactions(
            any(),
            limit: any(named: 'limit'),
            type: any(named: 'type'),
            types: any(named: 'types'),
          )).thenAnswer((inv) async {
        callCount++;
        capturedTypes = inv.namedArguments[#types] as Set<CreditTxType>?;
        return <CreditTransaction>[];
      });

      bloc.add(const CreditTransactionsStarted(testUserId));
      await bloc.stream.firstWhere(
          (s) => s.status != CreditTransactionsStatus.loading);

      bloc.add(const CreditTransactionsFilterChanged(
          CreditTransactionsFilter.earnings));
      await bloc.stream.firstWhere(
          (s) => s.status == CreditTransactionsStatus.loaded);

      expect(callCount, greaterThanOrEqualTo(1));
      expect(capturedTypes, isNotNull);
      expect(capturedTypes, contains(CreditTxType.topup));
      expect(capturedTypes, contains(CreditTxType.dailyReward));
      expect(capturedTypes, contains(CreditTxType.subscriptionGrant));
      expect(capturedTypes, contains(CreditTxType.missionReward));
      expect(capturedTypes, contains(CreditTxType.adminGrant));
      expect(capturedTypes, contains(CreditTxType.refund));
      // Spent type should NOT be in earnings
      expect(capturedTypes!.contains(CreditTxType.generateSticker), isFalse);
    });

    test('Spent filter passes {generateSticker} to repo', () async {
      Set<CreditTxType>? capturedTypes;

      when(() => repo.fetchTransactions(
            any(),
            limit: any(named: 'limit'),
            type: any(named: 'type'),
            types: any(named: 'types'),
          )).thenAnswer((inv) async {
        capturedTypes = inv.namedArguments[#types] as Set<CreditTxType>?;
        return <CreditTransaction>[];
      });

      bloc.add(const CreditTransactionsStarted(testUserId));
      await bloc.stream.firstWhere(
          (s) => s.status != CreditTransactionsStatus.loading);

      bloc.add(const CreditTransactionsFilterChanged(
          CreditTransactionsFilter.spent));
      await bloc.stream.firstWhere(
          (s) => s.status == CreditTransactionsStatus.loaded);

      expect(capturedTypes, {CreditTxType.generateSticker});
    });

    test('Rewards filter passes dailyReward, missionReward, subscriptionGrant',
        () async {
      Set<CreditTxType>? capturedTypes;

      when(() => repo.fetchTransactions(
            any(),
            limit: any(named: 'limit'),
            type: any(named: 'type'),
            types: any(named: 'types'),
          )).thenAnswer((inv) async {
        capturedTypes = inv.namedArguments[#types] as Set<CreditTxType>?;
        return <CreditTransaction>[];
      });

      bloc.add(const CreditTransactionsStarted(testUserId));
      await bloc.stream.firstWhere(
          (s) => s.status != CreditTransactionsStatus.loading);

      bloc.add(const CreditTransactionsFilterChanged(
          CreditTransactionsFilter.rewards));
      await bloc.stream.firstWhere(
          (s) => s.status == CreditTransactionsStatus.loaded);

      expect(capturedTypes, {
        CreditTxType.dailyReward,
        CreditTxType.missionReward,
        CreditTxType.subscriptionGrant,
      });
    });

    test('All filter passes null types to repo', () async {
      Set<CreditTxType>? capturedTypes;

      when(() => repo.fetchTransactions(
            any(),
            limit: any(named: 'limit'),
            type: any(named: 'type'),
            types: any(named: 'types'),
          )).thenAnswer((inv) async {
        capturedTypes = inv.namedArguments[#types] as Set<CreditTxType>?;
        return <CreditTransaction>[];
      });

      bloc.add(const CreditTransactionsStarted(testUserId));
      await bloc.stream.firstWhere(
          (s) => s.status != CreditTransactionsStatus.loading);

      bloc.add(const CreditTransactionsFilterChanged(
          CreditTransactionsFilter.all));
      await bloc.stream.firstWhere(
          (s) => s.status == CreditTransactionsStatus.loaded);

      expect(capturedTypes, isNull);
    });

    test('filter change emits loading then loaded', () async {
      when(() => repo.fetchTransactions(
            any(),
            limit: any(named: 'limit'),
            type: any(named: 'type'),
            types: any(named: 'types'),
          )).thenAnswer((_) async => <CreditTransaction>[]);

      bloc.add(const CreditTransactionsStarted(testUserId));
      await bloc.stream.firstWhere(
          (s) => s.status != CreditTransactionsStatus.loading);

      bloc.add(const CreditTransactionsFilterChanged(
          CreditTransactionsFilter.earnings));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CreditTransactionsState>()
              .having((s) => s.status, 'status',
                  CreditTransactionsStatus.loading)
              .having(
                  (s) => s.filter, 'filter', CreditTransactionsFilter.earnings),
          isA<CreditTransactionsState>()
              .having((s) => s.status, 'status',
                  CreditTransactionsStatus.loaded)
              .having(
                  (s) => s.filter, 'filter', CreditTransactionsFilter.earnings),
        ]),
      );
    });
  });

  group('CreditTransactionsViewAllRequested', () {
    test('requests with limit=0 and current filter types', () async {
      int capturedLimit = -1;

      when(() => repo.fetchTransactions(
            any(),
            limit: any(named: 'limit'),
            type: any(named: 'type'),
            types: any(named: 'types'),
          )).thenAnswer((inv) async {
        capturedLimit = inv.namedArguments[#limit] as int? ?? -1;
        return <CreditTransaction>[];
      });

      bloc.add(const CreditTransactionsStarted(testUserId));
      await bloc.stream.firstWhere(
          (s) => s.status != CreditTransactionsStatus.loading);

      bloc.add(const CreditTransactionsFilterChanged(
          CreditTransactionsFilter.earnings));
      await bloc.stream.firstWhere(
          (s) => s.status == CreditTransactionsStatus.loaded);

      bloc.add(const CreditTransactionsViewAllRequested());
      await bloc.stream.firstWhere(
          (s) => s.status == CreditTransactionsStatus.loaded);

      expect(capturedLimit, 0);
    });
  });
}
