import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String userId;
  final int balance;
  final DateTime updatedAt;

  const Wallet({
    required this.userId,
    required this.balance,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        userId: json['user_id'] as String,
        balance: json['balance'] as int,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  @override
  List<Object?> get props => [userId, balance, updatedAt];
}
