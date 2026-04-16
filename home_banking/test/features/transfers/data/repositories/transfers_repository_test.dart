import 'package:flutter_test/flutter_test.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';
import 'package:home_banking/features/transfers/data/repositories/transfers_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsRepository extends Mock implements AccountsRepository {}

void main() {
  late MockAccountsRepository accountsRepository;
  late TransfersRepository transfersRepository;

  setUp(() {
    accountsRepository = MockAccountsRepository();
    transfersRepository = TransfersRepository(
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

    final result = await transfersRepository.getAccountsByUser(1);

    expect(result.length, 1);
    expect(result.first.type, 'checking');
    expect(result.first.name, 'Conto Principale');
  });

  test('submitTransfer lancia eccezione se il saldo è insufficiente', () async {
    const account = AccountModel(
      id: '1',
      name: 'Conto Principale',
      balance: 100,
      iban: 'IT60X0542811101000000123456',
      type: 'checking',
    );

    expect(
      () => transfersRepository.submitTransfer(
        account: account,
        beneficiaryName: 'Mario Rossi',
        beneficiaryIban: 'IT60X0542811101000000123456',
        description: 'Affitto',
        amount: 500,
        transferType: 'ordinary',
      ),
      throwsA(
        isA<Exception>(),
      ),
    );
  });
}