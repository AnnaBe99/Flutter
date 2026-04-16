import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:home_banking/features/auth/data/models/user_model.dart';

class ProfileRepository {
  final http.Client client;

  ProfileRepository({http.Client? client}) : client = client ?? http.Client();

  Future<UserModel> getUserById(int userId) async {
    final uri = Uri.http('localhost:3000', '/users/$userId');

    final response = await client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Errore nel recupero profilo utente');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return UserModel.fromJson(data);
  }

  Future<UserModel> updateUserProfile({
    required int userId,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
  }) async {
    final uri = Uri.http('localhost:3000', '/users/$userId');

    final response = await client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore nel salvataggio del profilo');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return UserModel.fromJson(data);
  }
}