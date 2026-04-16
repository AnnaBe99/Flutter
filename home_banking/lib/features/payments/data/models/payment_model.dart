import 'package:equatable/equatable.dart';

class PaymentModel extends Equatable {
  final String id;
  final String accountId;
  final String type;
  final String provider;
  final double amount;
  final String description;
  final String code;
  final String date;
  final String status;

  const PaymentModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.provider,
    required this.amount,
    required this.description,
    required this.code,
    required this.date,
    required this.status,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'].toString(),
      accountId: json['accountId'].toString(),
      type: json['type'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      code: json['code'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        type,
        provider,
        amount,
        description,
        code,
        date,
        status,
      ];
}