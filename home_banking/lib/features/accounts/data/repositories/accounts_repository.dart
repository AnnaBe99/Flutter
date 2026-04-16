import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/models/transaction_model.dart';

class AccountsRepository {
  final http.Client client;

  AccountsRepository({http.Client? client}) : client = client ?? http.Client();

  Future<List<AccountModel>> getAccountsByUser(int userId) async {
    final accountsUri = Uri.http(
      'localhost:3000',
      '/accounts',
      {
        'userId': userId.toString(),
      },
    );

    final accountsResponse = await client.get(accountsUri);

    if (accountsResponse.statusCode != 200) {
      throw Exception('Errore nel recupero conti');
    }

    final List<dynamic> accountsData =
        jsonDecode(accountsResponse.body) as List<dynamic>;

    final List<AccountModel> accounts = [];

    for (final accountJson in accountsData) {
      final account = AccountModel.fromJson(accountJson);

      final transactionsUri = Uri.http(
        'localhost:3000',
        '/account_transactions',
        {
          'accountId': account.id,
        },
      );

      final transactionsResponse = await client.get(transactionsUri);

      if (transactionsResponse.statusCode != 200) {
        throw Exception('Errore nel recupero movimenti conto');
      }

      final List<dynamic> transactionsData =
          jsonDecode(transactionsResponse.body) as List<dynamic>;

      final transactions = transactionsData
          .map((e) => TransactionModel.fromJson(e))
          .toList()
        ..sort((a, b) {
          final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
          final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

      accounts.add(
        account.copyWith(transactions: transactions),
      );
    }

    return accounts;
  }
}