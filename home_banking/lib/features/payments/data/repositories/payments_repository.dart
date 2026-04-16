import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';

class PaymentsRepository {
  final http.Client client;
  final AccountsRepository accountsRepository;

  PaymentsRepository({
    http.Client? client,
    AccountsRepository? accountsRepository,
  })  : client = client ?? http.Client(),
        accountsRepository = accountsRepository ?? AccountsRepository();

  Future<List<AccountModel>> getAccountsByUser(int userId) async {
    final accounts = await accountsRepository.getAccountsByUser(userId);

    return accounts.where((account) => account.type == 'checking').toList();
  }

  Future<void> submitPayment({
    required AccountModel account,
    required String paymentType,
    required String provider,
    required String code,
    required String description,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw Exception('Inserisci un importo valido');
    }

    if (account.balance < amount) {
      throw Exception('Saldo insufficiente per completare il pagamento');
    }

    final now = DateTime.now().toIso8601String();
    final newBalance = account.balance - amount;

    final paymentUri = Uri.http('localhost:3000', '/payments');
    final paymentResponse = await client.post(
      paymentUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accountId': int.parse(account.id),
        'type': paymentType,
        'provider': provider,
        'amount': amount,
        'description': description,
        'code': code,
        'date': now,
        'status': 'completed',
      }),
    );

    if (paymentResponse.statusCode != 201) {
      throw Exception('Errore nella registrazione del pagamento');
    }

    final transactionUri = Uri.http('localhost:3000', '/account_transactions');
    final transactionResponse = await client.post(
      transactionUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accountId': int.parse(account.id),
        'type': 'debit',
        'category': 'pagamento',
        'amount': amount,
        'description': description,
        'counterparty': provider,
        'date': now,
        'status': 'booked',
      }),
    );

    if (transactionResponse.statusCode != 201) {
      throw Exception('Errore nella registrazione del movimento conto');
    }

    final updateAccountUri =
        Uri.http('localhost:3000', '/accounts/${account.id}');
    final updateAccountResponse = await client.patch(
      updateAccountUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'balance': newBalance,
        'availableBalance': newBalance,
      }),
    );

    if (updateAccountResponse.statusCode != 200) {
      throw Exception('Errore nell’aggiornamento del saldo conto');
    }
  }
}