import 'package:bikin_stiker/data/models/credit_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreditTransaction.fromJson type mapping', () {
    test('maps snake_case DB strings to correct enum values via fromJson', () {
      // _typeFrom is private; test through the public fromJson factory
      final mappings = [
        ('topup', CreditTxType.topup),
        ('daily_reward', CreditTxType.dailyReward),
        ('generate_sticker', CreditTxType.generateSticker),
        ('refund', CreditTxType.refund),
        ('subscription_grant', CreditTxType.subscriptionGrant),
        ('mission_reward', CreditTxType.missionReward),
        ('expired', CreditTxType.expired),
        ('locked', CreditTxType.locked),
        ('admin_grant', CreditTxType.adminGrant),
      ];

      for (final (raw, expected) in mappings) {
        final json = {
          'id': 'tx-1',
          'user_id': 'user-1',
          'amount': 10,
          'type': raw,
          'reference_id': 'ref-123',
          'created_at': '2026-07-01T10:00:00Z',
        };
        final tx = CreditTransaction.fromJson(json);
        expect(tx.type, expected, reason: 'Failed for type "$raw"');
      }
    });

    test('unknown DB type string maps to CreditTxType.unknown', () {
      final json = {
        'id': 'tx-1',
        'user_id': 'user-1',
        'amount': 10,
        'type': 'some_unknown_type',
        'reference_id': 'ref-123',
        'created_at': '2026-07-01T10:00:00Z',
      };
      final tx = CreditTransaction.fromJson(json);
      expect(tx.type, CreditTxType.unknown);
    });
  });

  group('CreditTransaction.fromJson', () {
    final baseJson = {
      'id': 'tx-1',
      'user_id': 'user-1',
      'amount': 10,
      'type': 'topup',
      'reference_id': 'ref-123',
      'created_at': '2026-07-01T10:00:00Z',
      'expires_at': null,
      'consumed_at': null,
      'expired_at': null,
      'source_tier': null,
    };

    test('parses a basic income transaction (topup)', () {
      final tx = CreditTransaction.fromJson(baseJson);

      expect(tx.id, 'tx-1');
      expect(tx.userId, 'user-1');
      expect(tx.amount, 10);
      expect(tx.type, CreditTxType.topup);
      expect(tx.referenceId, 'ref-123');
      expect(tx.createdAt.year, 2026);
    });

    test('parses a spending transaction (generateSticker, negative)', () {
      final json = {...baseJson, 'amount': -5, 'type': 'generate_sticker'};
      final tx = CreditTransaction.fromJson(json);

      expect(tx.amount, -5);
      expect(tx.type, CreditTxType.generateSticker);
      expect(tx.isDebit, isTrue);
      expect(tx.isCredit, isFalse);
    });

    test('parses a daily reward transaction', () {
      final json = {...baseJson, 'amount': 2, 'type': 'daily_reward'};
      final tx = CreditTransaction.fromJson(json);

      expect(tx.type, CreditTxType.dailyReward);
      expect(tx.isCredit, isTrue);
    });

    test('isCredit is true when amount > 0', () {
      final tx = CreditTransaction.fromJson({...baseJson, 'amount': 1});
      expect(tx.isCredit, isTrue);
    });

    test('isDebit is true when amount < 0', () {
      final tx = CreditTransaction.fromJson({...baseJson, 'amount': -1});
      expect(tx.isDebit, isTrue);
    });

    test('isExpired is true when type is expired', () {
      final tx = CreditTransaction.fromJson({...baseJson, 'type': 'expired'});
      expect(tx.isExpired, isTrue);
    });

    test('isExpired is false for other types', () {
      final tx = CreditTransaction.fromJson({...baseJson, 'type': 'topup'});
      expect(tx.isExpired, isFalse);
    });

    test('parses optional date fields', () {
      final json = {
        ...baseJson,
        'expires_at': '2026-08-01T00:00:00Z',
        'consumed_at': '2026-07-15T00:00:00Z',
        'expired_at': null,
        'source_tier': 'plus',
      };
      final tx = CreditTransaction.fromJson(json);

      expect(tx.expiresAt, isNotNull);
      expect(tx.expiresAt!.month, 8);
      expect(tx.consumedAt, isNotNull);
      expect(tx.consumedAt!.month, 7);
      expect(tx.expiredAt, isNull);
      expect(tx.sourceTier, 'plus');
    });
  });

  group('CreditTransaction Equatable', () {
    test('two transactions with same props are equal', () {
      final tx1 = CreditTransaction(
        id: 'tx-1',
        userId: 'user-1',
        amount: 10,
        type: CreditTxType.topup,
        referenceId: 'ref-1',
        createdAt: DateTime.utc(2026, 7, 1),
      );
      final tx2 = CreditTransaction(
        id: 'tx-1',
        userId: 'user-1',
        amount: 10,
        type: CreditTxType.topup,
        referenceId: 'ref-1',
        createdAt: DateTime.utc(2026, 7, 1),
      );
      expect(tx1, equals(tx2));
    });

    test('different type makes transactions not equal', () {
      final tx1 = CreditTransaction(
        id: 'tx-1',
        userId: 'user-1',
        amount: 10,
        type: CreditTxType.topup,
        referenceId: 'ref-1',
        createdAt: DateTime.utc(2026, 7, 1),
      );
      final tx2 = CreditTransaction(
        id: 'tx-1',
        userId: 'user-1',
        amount: 10,
        type: CreditTxType.dailyReward,
        referenceId: 'ref-1',
        createdAt: DateTime.utc(2026, 7, 1),
      );
      expect(tx1, isNot(equals(tx2)));
    });
  });
}
