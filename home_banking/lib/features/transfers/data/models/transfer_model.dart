import 'package:equatable/equatable.dart';

class TransferModel extends Equatable {
  final String id;
  final String accountId;
  final String direction;
  final String beneficiaryName;
  final String beneficiaryIban;
  final double amount;
  final String description;
  final String executionDate;
  final String status;
  final String createdAt;
  final String transferType;

  const TransferModel({
    required this.id,
    required this.accountId,
    required this.direction,
    required this.beneficiaryName,
    required this.beneficiaryIban,
    required this.amount,
    required this.description,
    required this.executionDate,
    required this.status,
    required this.createdAt,
    required this.transferType,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'].toString(),
      accountId: json['accountId'].toString(),
      direction: json['direction'] as String? ?? '',
      beneficiaryName: json['beneficiaryName'] as String? ?? '',
      beneficiaryIban: json['beneficiaryIban'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      executionDate: json['executionDate'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      transferType: json['transferType'] as String? ?? 'ordinary',
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        direction,
        beneficiaryName,
        beneficiaryIban,
        amount,
        description,
        executionDate,
        status,
        createdAt,
        transferType,
      ];
}