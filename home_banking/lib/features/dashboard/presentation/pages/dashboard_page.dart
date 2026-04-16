import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:home_banking/app/router/route_names.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/shared/widgets/app_scaffold.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AccountsRepository _accountsRepository;
  Future<List<AccountModel>>? _accountsFuture;

  @override
  void initState() {
    super.initState();
    _accountsRepository = AccountsRepository();
    _reloadData();
  }

  void _reloadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        _accountsFuture =
            _accountsRepository.getAccountsByUser(authState.user.id);
      });
    } else {
      setState(() {
        _accountsFuture = Future.value([]);
      });
    }
  }

  double _calculateMonthlySpent(AccountModel account) {
    final now = DateTime.now();

    return account.transactions
        .where((transaction) {
          final date = DateTime.tryParse(transaction.date);
          if (date == null) return false;

          return transaction.isDebit &&
              date.year == now.year &&
              date.month == now.month;
        })
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    String userName = 'Utente';
    if (authState is AuthAuthenticated) {
      userName = authState.user.firstName;
    }

    return AppScaffold(
      title: 'Dashboard',
      child: FutureBuilder<List<AccountModel>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];
          final hasAccount = accounts.isNotEmpty;
          final mainAccount = hasAccount ? accounts.first : null;
          final monthlySpent =
              hasAccount ? _calculateMonthlySpent(mainAccount!) : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bentornata, $userName',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Controlla il riepilogo del tuo conto e accedi rapidamente ai servizi principali.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Aggiorna dati',
                      onPressed: _reloadData,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _CompactSummaryCard(
                      title: 'Saldo disponibile',
                      value: hasAccount
                          ? '€ ${mainAccount!.balance.toStringAsFixed(2)}'
                          : '--',
                      subtitle:
                          hasAccount ? mainAccount!.name : 'Nessun conto attivo',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    _CompactSummaryCard(
                      title: 'Spesa del mese',
                      value: '€ ${monthlySpent.toStringAsFixed(2)}',
                      subtitle: 'Uscite registrate nel mese corrente',
                      icon: Icons.trending_down_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Operazioni rapide',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1200
                        ? 3
                        : constraints.maxWidth > 750
                            ? 2
                            : 1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.35,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ActionCard(
                          title: 'Conto e movimenti',
                          subtitle:
                              'Consulta saldo, movimenti recenti e dettaglio conto',
                          icon: Icons.account_balance_outlined,
                          onTap: () => context.go(RouteNames.accounts),
                        ),
                        _ActionCard(
                          title: 'Bonifico',
                          subtitle:
                              'Esegui un bonifico e gestisci la transazione',
                          icon: Icons.swap_horiz_outlined,
                          onTap: () => context.go(RouteNames.transfers),
                        ),
                        _ActionCard(
                          title: 'Pagamento',
                          subtitle:
                              'Paga bollettini, pagoPA o codici simulati',
                          icon: Icons.qr_code_scanner_outlined,
                          onTap: () => context.go(RouteNames.payments),
                        ),
                        _ActionCard(
                          title: 'Carte',
                          subtitle: 'Visualizza carte e movimenti associati',
                          icon: Icons.credit_card_outlined,
                          onTap: () => context.go(RouteNames.cards),
                        ),
                        _ActionCard(
                          title: 'Profilo',
                          subtitle:
                              'Gestisci dati personali e preferenze tema',
                          icon: Icons.person_outline,
                          onTap: () => context.go(RouteNames.profile),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _CompactSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              const Align(
                alignment: Alignment.bottomRight,
                child: Icon(Icons.arrow_forward_ios, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}