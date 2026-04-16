import 'package:equatable/equatable.dart';
import 'card_transaction_model.dart';

class BankCardModel extends Equatable {
  final String id;
  final String userId;
  final String accountId;
  final String name;
  final String type;
  final String circuit;
  final String maskedNumber;
  final String holderName;
  final String expiry;
  final String status;
  final double limit;
  final double availableLimit;
  final String color;
  final List<CardTransactionModel> transactions;

  const BankCardModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.name,
    required this.type,
    required this.circuit,
    required this.maskedNumber,
    required this.holderName,
    required this.expiry,
    required this.status,
    required this.limit,
    required this.availableLimit,
    required this.color,
    this.transactions = const [],
  });

  bool get isCreditCard => type == 'credit';

  BankCardModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? name,
    String? type,
    String? circuit,
    String? maskedNumber,
    String? holderName,
    String? expiry,
    String? status,
    double? limit,
    double? availableLimit,
    String? color,
    List<CardTransactionModel>? transactions,
  }) {
    return BankCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      type: type ?? this.type,
      circuit: circuit ?? this.circuit,
      maskedNumber: maskedNumber ?? this.maskedNumber,
      holderName: holderName ?? this.holderName,
      expiry: expiry ?? this.expiry,
      status: status ?? this.status,
      limit: limit ?? this.limit,
      availableLimit: availableLimit ?? this.availableLimit,
      color: color ?? this.color,
      transactions: transactions ?? this.transactions,
    );
  }

  factory BankCardModel.fromJson(Map<String, dynamic> json) {
    return BankCardModel(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      accountId: json['accountId'].toString(),
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      circuit: json['circuit'] as String? ?? '',
      maskedNumber: json['maskedNumber'] as String? ?? '',
      holderName: json['holderName'] as String? ?? '',
      expiry: json['expiry'] as String? ?? '',
      status: json['status'] as String? ?? '',
      limit: (json['limit'] as num?)?.toDouble() ?? 0.0,
      availableLimit: (json['availableLimit'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String? ?? 'blue',
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        accountId,
        name,
        type,
        circuit,
        maskedNumber,
        holderName,
        expiry,
        status,
        limit,
        availableLimit,
        color,
        transactions,
      ];
}