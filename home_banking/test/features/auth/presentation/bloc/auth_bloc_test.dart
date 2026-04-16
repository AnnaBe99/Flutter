import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_banking/features/auth/data/models/user_model.dart';
import 'package:home_banking/features/auth/data/repositories/auth_repository.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_event.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late UserModel testUser;

  setUp(() {
    authRepository = MockAuthRepository();

    testUser = const UserModel(
      id: 1,
      email: 'marco.rossi@gmail.com',
      password: '123456',
      username: 'mrossi',
      firstName: 'Marco',
      lastName: 'Rossi',
      phone: '+39 333 1234567',
      fiscalCode: 'RSSMRC85M01F205X',
      birthDate: '1985-08-01',
      theme: 'light',
      customerCode: 'CLI0001',
    );
  });

  blocTest<AuthBloc, AuthState>(
    'emette [AuthLoading, AuthAuthenticated] quando il login riesce',
    build: () {
      when(
        () => authRepository.login(
          email: 'marco.rossi@gmail.com',
          password: '123456',
        ),
      ).thenAnswer((_) async => testUser);

      return AuthBloc(authRepository: authRepository);
    },
    act: (bloc) => bloc.add(
      const AuthLoginRequested(
        email: 'marco.rossi@gmail.com',
        password: '123456',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      AuthAuthenticated(testUser),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emette [AuthLoading, AuthError] quando il login fallisce',
    build: () {
      when(
        () => authRepository.login(
          email: 'marco.rossi@gmail.com',
          password: 'wrong',
        ),
      ).thenThrow(Exception('Credenziali non valide'));

      return AuthBloc(authRepository: authRepository);
    },
    act: (bloc) => bloc.add(
      const AuthLoginRequested(
        email: 'marco.rossi@gmail.com',
        password: 'wrong',
      ),
    ),
    expect: () => [
      const AuthLoading(),
      const AuthError('Credenziali non valide'),
    ],
  );
}