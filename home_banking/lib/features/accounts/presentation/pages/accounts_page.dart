import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/models/transaction_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/shared/widgets/app_scaffold.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  late final AccountsRepository _repository;
  Future<List<AccountModel>>? _accountsFuture;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = AccountsRepository();
    _reloadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        _accountsFuture = _repository.getAccountsByUser(authState.user.id);
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

  List<TransactionModel> _filterTransactions(List<TransactionModel> items) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return items;

    return items.where((transaction) {
      return transaction.description.toLowerCase().contains(query) ||
          transaction.category.toLowerCase().contains(query) ||
          transaction.date.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    return AppScaffold(
      title: 'Conti',
      showBackButton: true,
      child: FutureBuilder<List<AccountModel>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Errore: ${snapshot.error}',
              ),
            );
          }

          final accounts = snapshot.data ?? [];

          if (accounts.isEmpty) {
            return const Center(
              child: Text('Nessun conto trovato'),
            );
          }

          final account = accounts.first;
          final monthlySpent = _calculateMonthlySpent(account);
          final filteredTransactions = _filterTransactions(account.transactions);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _InfoCard(
                            title: 'Saldo disponibile',
                            value: '€ ${account.balance.toStringAsFixed(2)}',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          _InfoCard(
                            title: 'Spesa del mese',
                            value: '€ ${monthlySpent.toStringAsFixed(2)}',
                            icon: Icons.trending_down_outlined,
                          ),
                          _InfoCard(
                            title: 'IBAN',
                            value: account.iban,
                            icon: Icons.numbers_outlined,
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
                const SizedBox(height: 28),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Cerca un movimento',
                    hintText: 'Es. bonifico, ATM, bolletta...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Movimenti recenti',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: filteredTransactions.isEmpty
                        ? const Center(
                            child: Text('Nessun movimento trovato'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: filteredTransactions.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final transaction = filteredTransactions[index];

                              return ListTile(
                                leading: CircleAvatar(
                                  child: Icon(
                                    transaction.isDebit
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                  ),
                                ),
                                title: Text(transaction.description),
                                subtitle: Text(
                                  '${transaction.category} • ${transaction.date}',
                                ),
                                trailing: Text(
                                  '${transaction.isDebit ? '-' : '+'} € ${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: transaction.isDebit
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}