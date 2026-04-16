import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:home_banking/features/cards/data/models/bank_card_model.dart';
import 'package:home_banking/features/cards/data/models/card_transaction_model.dart';

class CardsRepository {
  final http.Client client;

  CardsRepository({http.Client? client}) : client = client ?? http.Client();

  Future<List<BankCardModel>> getCardsByUser(int userId) async {
    final cardsUri = Uri.http(
      'localhost:3000',
      '/cards',
      {
        'userId': userId.toString(),
      },
    );

    final cardsResponse = await client.get(cardsUri);

    if (cardsResponse.statusCode != 200) {
      throw Exception('Errore nel recupero carte');
    }

    final List<dynamic> cardsData =
        jsonDecode(cardsResponse.body) as List<dynamic>;

    final List<BankCardModel> cards = [];

    for (final cardJson in cardsData) {
      final card = BankCardModel.fromJson(cardJson);

      final transactionsUri = Uri.http(
        'localhost:3000',
        '/card_transactions',
        {
          'cardId': card.id,
        },
      );

      final transactionsResponse = await client.get(transactionsUri);

      if (transactionsResponse.statusCode != 200) {
        throw Exception('Errore nel recupero movimenti carta');
      }

      final List<dynamic> transactionsData =
          jsonDecode(transactionsResponse.body) as List<dynamic>;

      final transactions = transactionsData
          .map((e) => CardTransactionModel.fromJson(e))
          .toList();

      cards.add(card.copyWith(transactions: transactions));
    }

    return cards;
  }
}