import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String userId;
  final int balance;
  final String tierNow;
  final DateTime? lastGrantAt;
  final DateTime updatedAt;

  const Wallet({
    required this.userId,
    required this.balance,
    required this.tierNow,
    this.lastGrantAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    userId: json['user_id'] as String,
    balance: json['balance'] as int,
    tierNow: json['tier_now'] as String? ?? 'free',
    lastGrantAt: json['last_grant_at'] != null
        ? DateTime.parse(json['last_grant_at'] as String)
        : null,
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  @override
  List<Object?> get props => [userId, balance, tierNow, lastGrantAt, updatedAt];
}
