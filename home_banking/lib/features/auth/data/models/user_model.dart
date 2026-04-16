import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String email;
  final String password;
  final String username;
  final String firstName;
  final String lastName;
  final String phone;
  final String fiscalCode;
  final String birthDate;
  final String theme;
  final String customerCode;

  const UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.fiscalCode,
    required this.birthDate,
    required this.theme,
    required this.customerCode,
  });

  String get fullName => '$firstName $lastName';

  UserModel copyWith({
    int? id,
    String? email,
    String? password,
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    String? fiscalCode,
    String? birthDate,
    String? theme,
    String? customerCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      fiscalCode: fiscalCode ?? this.fiscalCode,
      birthDate: birthDate ?? this.birthDate,
      theme: theme ?? this.theme,
      customerCode: customerCode ?? this.customerCode,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fiscalCode: json['fiscalCode'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      theme: json['theme'] as String? ?? 'light',
      customerCode: json['customerCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'fiscalCode': fiscalCode,
      'birthDate': birthDate,
      'theme': theme,
      'customerCode': customerCode,
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        password,
        username,
        firstName,
        lastName,
        phone,
        fiscalCode,
        birthDate,
        theme,
        customerCode,
      ];
}