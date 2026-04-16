import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_banking/app/router/route_names.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_event.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBackButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    String userName = 'Utente';

    if (authState is AuthAuthenticated) {
      userName = authState.user.fullName;
    }

    return Scaffold(
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                tooltip: 'Torna alla dashboard',
                onPressed: () => context.go(RouteNames.dashboard),
                icon: const Icon(Icons.arrow_back_ios_new),
              )
            : null,
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(userName),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go(RouteNames.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Home Banking',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.dashboard);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Conti'),
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.accounts);
              },
            ),
            ListTile(
              leading: const Icon(Icons.credit_card_outlined),
              title: const Text('Carte'),
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.cards);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_outlined),
              title: const Text('Bonifici'),
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.transfers);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner_outlined),
              title: const Text('Pagamenti'),
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.payments);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profilo'),
              onTap: () {
                Navigator.pop(context);
                context.go(RouteNames.profile);
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}