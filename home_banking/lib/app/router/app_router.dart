import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:home_banking/app/router/route_names.dart';
import 'package:home_banking/features/accounts/presentation/pages/accounts_page.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/features/auth/presentation/pages/login_page.dart';
import 'package:home_banking/features/cards/presentation/pages/cards_page.dart';
import 'package:home_banking/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:home_banking/features/payments/presentation/pages/payments_page.dart';
import 'package:home_banking/features/profile/presentation/pages/profile_page.dart';
import 'package:home_banking/features/transfers/presentation/pages/transfers_page.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter({required this.authBloc});

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.login,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggedIn = authState is AuthAuthenticated;
      final isGoingToLogin = state.matchedLocation == RouteNames.login;

      if (!isLoggedIn && !isGoingToLogin) {
        return RouteNames.login;
      }

      if (isLoggedIn && isGoingToLogin) {
        return RouteNames.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: RouteNames.accounts,
        builder: (context, state) => const AccountsPage(),
      ),
      GoRoute(
        path: RouteNames.cards,
        builder: (context, state) => const CardsPage(),
      ),
      GoRoute(
        path: RouteNames.transfers,
        builder: (context, state) => const TransfersPage(),
      ),
      GoRoute(
        path: RouteNames.payments,
        builder: (context, state) => const PaymentsPage(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}