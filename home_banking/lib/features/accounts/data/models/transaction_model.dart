import 'package:equatable/equatable.dart';

class TransactionModel extends Equatable {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String date;
  final String category;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
  });

  bool get isDebit => type == 'debit';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        description,
        date,
        category,
      ];
}