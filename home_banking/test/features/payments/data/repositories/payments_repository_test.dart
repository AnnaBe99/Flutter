import 'package:flutter_test/flutter_test.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';
import 'package:home_banking/features/payments/data/repositories/payments_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsRepository extends Mock implements AccountsRepository {}

void main() {
  late MockAccountsRepository accountsRepository;
  late PaymentsRepository paymentsRepository;

  setUp(() {
    accountsRepository = MockAccountsRepository();
    paymentsRepository = PaymentsRepository(
      accountsRepository: accountsRepository,
    );
  });

  test('getAccountsByUser restituisce solo conti checking', () async {
    when(() => accountsRepository.getAccountsByUser(1)).thenAnswer(
      (_) async => const [
        AccountModel(
          id: '1',
          name: 'Conto Principale',
          balance: 3200,
          iban: 'IT60X0542811101000000123456',
          type: 'checking',
        ),
        AccountModel(
          id: '2',
          name: 'Conto Risparmio',
          balance: 12000,
          iban: 'IT18Y0542811101000000987654',
          type: 'savings',
        ),
      ],
    );

    final result = await paymentsRepository.getAccountsByUser(1);

    expect(result.length, 1);
    expect(result.first.type, 'checking');
    expect(result.first.name, 'Conto Principale');
  });

  test('submitPayment lancia eccezione se il saldo è insufficiente', () async {
    const account = AccountModel(
      id: '1',
      name: 'Conto Principale',
      balance: 50,
      iban: 'IT60X0542811101000000123456',
      type: 'checking',
    );

    expect(
      () => paymentsRepository.submitPayment(
        account: account,
        paymentType: 'bollettino',
        provider: 'Poste Italiane',
        code: '896700000000123456',
        description: 'Bollettino luce',
        amount: 150,
      ),
      throwsA(
        isA<Exception>(),
      ),
    );
  });
}