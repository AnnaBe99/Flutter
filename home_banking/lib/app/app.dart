import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_banking/app/router/app_router.dart';
import 'package:home_banking/core/theme/app_theme.dart';
import 'package:home_banking/core/theme/theme_cubit.dart';
import 'package:home_banking/core/theme/theme_state.dart';
import 'package:home_banking/features/auth/data/repositories/auth_repository.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';

class HomeBankingApp extends StatelessWidget {
  const HomeBankingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final authBloc = AuthBloc(authRepository: authRepository);
    final appRouter = AppRouter(authBloc: authBloc);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: authRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(
            value: authBloc,
          ),
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit()..loadTheme(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Home Banking',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeState.themeMode,
              routerConfig: appRouter.router,
            );
          },
        ),
      ),
    );
  }
}