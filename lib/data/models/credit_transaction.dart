import 'package:equatable/equatable.dart';

enum CreditTxType {
  topup,
  dailyReward,
  generateSticker,
  refund,
  subscriptionGrant,
  missionReward,
  expired,
  locked,
  unknown,
}

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
    case 'subscription_grant':
      return CreditTxType.subscriptionGrant;
    case 'mission_reward':
      return CreditTxType.missionReward;
    case 'expired':
      return CreditTxType.expired;
    case 'locked':
      return CreditTxType.locked;
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
  final DateTime? expiresAt;
  final DateTime? consumedAt;
  final DateTime? expiredAt;
  final String? sourceTier;

  const CreditTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.referenceId,
    required this.createdAt,
    this.expiresAt,
    this.consumedAt,
    this.expiredAt,
    this.sourceTier,
  });

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;
  bool get isExpired => type == CreditTxType.expired;

  factory CreditTransaction.fromJson(Map<String, dynamic> json) =>
      CreditTransaction(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        amount: json['amount'] as int,
        type: _typeFrom(json['type'] as String),
        referenceId: json['reference_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'] as String)
            : null,
        consumedAt: json['consumed_at'] != null
            ? DateTime.tryParse(json['consumed_at'] as String)
            : null,
        expiredAt: json['expired_at'] != null
            ? DateTime.tryParse(json['expired_at'] as String)
            : null,
        sourceTier: json['source_tier'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    userId,
    amount,
    type,
    referenceId,
    createdAt,
    expiresAt,
    consumedAt,
    expiredAt,
    sourceTier,
  ];
}
