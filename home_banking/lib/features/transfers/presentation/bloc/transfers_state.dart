import 'package:equatable/equatable.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';

class TransfersState extends Equatable {
  final bool isLoading;
  final bool isSubmitting;
  final List<AccountModel> accounts;
  final String? errorMessage;
  final String? successMessage;

  const TransfersState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.accounts = const [],
    this.errorMessage,
    this.successMessage,
  });

  TransfersState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<AccountModel>? accounts,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TransfersState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      accounts: accounts ?? this.accounts,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSubmitting,
        accounts,
        errorMessage,
        successMessage,
      ];
}