import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';

class TransfersRepository {
  final http.Client client;
  final AccountsRepository accountsRepository;

  TransfersRepository({
    http.Client? client,
    AccountsRepository? accountsRepository,
  })  : client = client ?? http.Client(),
        accountsRepository = accountsRepository ?? AccountsRepository();

  Future<List<AccountModel>> getAccountsByUser(int userId) async {
    final accounts = await accountsRepository.getAccountsByUser(userId);

    return accounts.where((account) => account.type == 'checking').toList();
  }

  Future<void> submitTransfer({
    required AccountModel account,
    required String beneficiaryName,
    required String beneficiaryIban,
    required String description,
    required double amount,
    required String transferType,
  }) async {
    if (amount <= 0) {
      throw Exception('Inserisci un importo valido');
    }

    if (account.balance < amount) {
      throw Exception('Saldo insufficiente per completare il bonifico');
    }

    final now = DateTime.now();
    final executionDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final createdAt = now.toIso8601String();
    final newBalance = account.balance - amount;

    final transferUri = Uri.http('localhost:3000', '/transfers');
    final transferResponse = await client.post(
      transferUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accountId': int.parse(account.id),
        'direction': 'outgoing',
        'beneficiaryName': beneficiaryName,
        'beneficiaryIban': beneficiaryIban,
        'amount': amount,
        'description': description,
        'executionDate': executionDate,
        'status': 'completed',
        'createdAt': createdAt,
        'transferType': transferType,
      }),
    );

    if (transferResponse.statusCode != 201) {
      throw Exception('Errore nella creazione del bonifico');
    }

    final transactionUri = Uri.http('localhost:3000', '/account_transactions');
    final transactionResponse = await client.post(
      transactionUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'accountId': int.parse(account.id),
        'type': 'debit',
        'category': 'bonifico',
        'amount': amount,
        'description': description.isEmpty ? 'Bonifico' : description,
        'counterparty': beneficiaryName,
        'date': createdAt,
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