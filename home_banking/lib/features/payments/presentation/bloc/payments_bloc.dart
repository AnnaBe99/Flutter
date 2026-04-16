import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_banking/features/payments/data/repositories/payments_repository.dart';
import 'package:home_banking/features/payments/presentation/bloc/payments_event.dart';
import 'package:home_banking/features/payments/presentation/bloc/payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final PaymentsRepository repository;
  int? _currentUserId;

  PaymentsBloc({
    required this.repository,
  }) : super(const PaymentsState()) {
    on<PaymentsLoadRequested>(_onLoadRequested);
    on<PaymentSubmitRequested>(_onSubmitRequested);
  }

  Future<void> _onLoadRequested(
    PaymentsLoadRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    _currentUserId = event.userId;

    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    try {
      final accounts = await repository.getAccountsByUser(event.userId);

      emit(
        state.copyWith(
          isLoading: false,
          accounts: accounts,
          clearError: true,
          clearSuccess: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          clearSuccess: true,
        ),
      );
    }
  }

  Future<void> _onSubmitRequested(
    PaymentSubmitRequested event,
    Emitter<PaymentsState> emit,
  ) async {
    try {
      final selectedAccount = state.accounts.firstWhere(
        (account) => account.id == event.accountId,
      );

      emit(
        state.copyWith(
          isSubmitting: true,
          clearError: true,
          clearSuccess: true,
        ),
      );

      await repository.submitPayment(
        account: selectedAccount,
        paymentType: event.paymentType,
        provider: event.provider,
        code: event.code,
        description: event.description,
        amount: event.amount,
      );

      final refreshedAccounts = _currentUserId != null
          ? await repository.getAccountsByUser(_currentUserId!)
          : state.accounts;

      emit(
        state.copyWith(
          isSubmitting: false,
          accounts: refreshedAccounts,
          successMessage: 'Pagamento eseguito con successo',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          clearSuccess: true,
        ),
      );
    }
  }
}