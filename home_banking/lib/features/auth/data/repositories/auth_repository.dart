import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:home_banking/features/auth/data/models/user_model.dart';

class AuthRepository {
  final http.Client client;

  AuthRepository({http.Client? client}) : client = client ?? http.Client();

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.http(
      'localhost:3000',
      '/users',
      {
        'email': email,
      },
    );

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Errore nella chiamata di login: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;

    if (data.isEmpty) {
      throw Exception('Utente non trovato');
    }

    final userJson = data.first as Map<String, dynamic>;

    final savedPassword = userJson['password']?.toString() ?? '';

    if (savedPassword != password) {
      throw Exception('Credenziali non valide');
    }

    return UserModel.fromJson(userJson);
  }
}