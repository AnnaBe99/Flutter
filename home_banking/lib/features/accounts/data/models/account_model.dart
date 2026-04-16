import 'package:equatable/equatable.dart';
import 'transaction_model.dart';

class AccountModel extends Equatable {
  final String id;
  final String name;
  final double balance;
  final String iban;
  final String type;
  final List<TransactionModel> transactions;

  const AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.iban,
    required this.type,
    this.transactions = const [],
  });

  AccountModel copyWith({
    String? id,
    String? name,
    double? balance,
    String? iban,
    String? type,
    List<TransactionModel>? transactions,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      iban: iban ?? this.iban,
      type: type ?? this.type,
      transactions: transactions ?? this.transactions,
    );
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      iban: json['iban'] as String? ?? '',
      type: json['type'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, balance, iban, type, transactions];
}