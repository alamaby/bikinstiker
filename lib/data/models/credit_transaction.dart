import 'package:equatable/equatable.dart';

enum CreditTxType { topup, dailyReward, generateSticker, refund, unknown }

CreditTxType _typeFrom(String raw) {
  switch (raw) {
    case 'topup':
      return CreditTxType.topup;
    case 'daily_reward':
      return CreditTxType.dailyReward;
    case 'generate_sticker':
      return CreditTxType.generateSticker;
    case 'refund':
      return CreditTxType.refund;
    default:
      return CreditTxType.unknown;
  }
}

class CreditTransaction extends Equatable {
  final String id;
  final String userId;
  final int amount;
  final CreditTxType type;
  final String? referenceId;
  final DateTime createdAt;

  const CreditTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.referenceId,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) =>
      CreditTransaction(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        amount: json['amount'] as int,
        type: _typeFrom(json['type'] as String),
        referenceId: json['reference_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, userId, amount, type, referenceId, createdAt];
}
