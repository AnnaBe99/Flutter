import 'package:equatable/equatable.dart';

abstract class TransfersEvent extends Equatable {
  const TransfersEvent();

  @override
  List<Object?> get props => [];
}

class TransfersLoadRequested extends TransfersEvent {
  final int userId;

  const TransfersLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class TransferSubmitRequested extends TransfersEvent {
  final String accountId;
  final String beneficiaryName;
  final String beneficiaryIban;
  final String description;
  final double amount;
  final String transferType;

  const TransferSubmitRequested({
    required this.accountId,
    required this.beneficiaryName,
    required this.beneficiaryIban,
    required this.description,
    required this.amount,
    required this.transferType,
  });

  @override
  List<Object?> get props => [
        accountId,
        beneficiaryName,
        beneficiaryIban,
        description,
        amount,
        transferType,
      ];
}