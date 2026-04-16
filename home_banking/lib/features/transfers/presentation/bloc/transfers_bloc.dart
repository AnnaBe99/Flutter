import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_banking/features/transfers/data/repositories/transfers_repository.dart';
import 'package:home_banking/features/transfers/presentation/bloc/transfers_event.dart';
import 'package:home_banking/features/transfers/presentation/bloc/transfers_state.dart';

class TransfersBloc extends Bloc<TransfersEvent, TransfersState> {
  final TransfersRepository repository;
  int? _currentUserId;

  TransfersBloc({
    required this.repository,
  }) : super(const TransfersState()) {
    on<TransfersLoadRequested>(_onLoadRequested);
    on<TransferSubmitRequested>(_onSubmitRequested);
  }

  Future<void> _onLoadRequested(
    TransfersLoadRequested event,
    Emitter<TransfersState> emit,
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
    TransferSubmitRequested event,
    Emitter<TransfersState> emit,
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

      await repository.submitTransfer(
        account: selectedAccount,
        beneficiaryName: event.beneficiaryName,
        beneficiaryIban: event.beneficiaryIban,
        description: event.description,
        amount: event.amount,
        transferType: event.transferType,
      );

      final refreshedAccounts = _currentUserId != null
          ? await repository.getAccountsByUser(_currentUserId!)
          : state.accounts;

      emit(
        state.copyWith(
          isSubmitting: false,
          accounts: refreshedAccounts,
          successMessage: event.transferType == 'instant'
              ? 'Bonifico istantaneo eseguito con successo'
              : 'Bonifico ordinario eseguito con successo',
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