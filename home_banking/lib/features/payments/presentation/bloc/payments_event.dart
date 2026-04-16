import 'package:equatable/equatable.dart';

abstract class PaymentsEvent extends Equatable {
  const PaymentsEvent();

  @override
  List<Object?> get props => [];
}

class PaymentsLoadRequested extends PaymentsEvent {
  final int userId;

  const PaymentsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class PaymentSubmitRequested extends PaymentsEvent {
  final String accountId;
  final String paymentType;
  final String provider;
  final String code;
  final String description;
  final double amount;

  const PaymentSubmitRequested({
    required this.accountId,
    required this.paymentType,
    required this.provider,
    required this.code,
    required this.description,
    required this.amount,
  });

  @override
  List<Object?> get props => [
        accountId,
        paymentType,
        provider,
        code,
        description,
        amount,
      ];
}