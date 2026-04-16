import 'package:equatable/equatable.dart';

class CardTransactionModel extends Equatable {
  final String id;
  final String type;
  final String category;
  final double amount;
  final String description;
  final String merchant;
  final String date;
  final String status;

  const CardTransactionModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.merchant,
    required this.date,
    required this.status,
  });

  factory CardTransactionModel.fromJson(Map<String, dynamic> json) {
    return CardTransactionModel(
      id: json['id'].toString(),
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      merchant: json['merchant'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        category,
        amount,
        description,
        merchant,
        date,
        status,
      ];
}