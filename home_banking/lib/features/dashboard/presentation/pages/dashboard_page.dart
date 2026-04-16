import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:home_banking/app/router/route_names.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/models/transaction_model.dart';
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

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
  );

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

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
        .fold<double>(0.0, (sum, transaction) => sum + transaction.amount);
  }

  List<TransactionModel> _recentTransactions(AccountModel account) {
    final transactions = List<TransactionModel>.from(account.transactions);
    transactions.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return transactions.take(3).toList();
  }

  String _formatCurrency(double value) {
    return _currencyFormat.format(value);
  }

  String _formatDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return _dateFormat.format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userName = 'Utente';

    if (authState is AuthAuthenticated) {
      userName = authState.user.firstName;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      title: 'Dashboard',
      child: FutureBuilder<List<AccountModel>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final accounts = snapshot.data ?? [];
          final hasAccount = accounts.isNotEmpty;
          final mainAccount = hasAccount ? accounts.first : null;
          final monthlySpent =
              hasAccount ? _calculateMonthlySpent(mainAccount!) : 0.0;
          final recentTransactions =
              hasAccount ? _recentTransactions(mainAccount!) : <TransactionModel>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  userName: userName,
                  onRefresh: _reloadData,
                ),
                const SizedBox(height: 24),
                if (isLoading) ...[
                  const _DashboardLoadingState(),
                ] else if (hasError) ...[
                  _DashboardErrorState(
                    onRetry: _reloadData,
                  ),
                ] else if (!hasAccount) ...[
                  _DashboardEmptyState(
                    onGoToAccounts: () => context.go(RouteNames.accounts),
                  ),
                ] else ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 980;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _MainAccountHeroCard(
                                account: mainAccount!,
                                monthlySpent: monthlySpent,
                                formatCurrency: _formatCurrency,
                                onViewTransactions: () =>
                                    context.go(RouteNames.accounts),
                                onNewTransfer: () =>
                                    context.go(RouteNames.transfers),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: _RecentTransactionsCard(
                                transactions: recentTransactions,
                                formatCurrency: _formatCurrency,
                                formatDate: _formatDate,
                                onSeeAll: () => context.go(RouteNames.accounts),
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _MainAccountHeroCard(
                            account: mainAccount!,
                            monthlySpent: monthlySpent,
                            formatCurrency: _formatCurrency,
                            onViewTransactions: () =>
                                context.go(RouteNames.accounts),
                            onNewTransfer: () =>
                                context.go(RouteNames.transfers),
                          ),
                          const SizedBox(height: 20),
                          _RecentTransactionsCard(
                            transactions: recentTransactions,
                            formatCurrency: _formatCurrency,
                            formatDate: _formatDate,
                            onSeeAll: () => context.go(RouteNames.accounts),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Panoramica veloce',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _KpiCard(
                        title: 'Saldo disponibile',
                        value: _formatCurrency(mainAccount!.balance),
                        subtitle: mainAccount.name,
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _KpiCard(
                        title: 'Spesa del mese',
                        value: _formatCurrency(monthlySpent),
                        subtitle: 'Addebiti del mese corrente',
                        icon: Icons.trending_down_rounded,
                      ),
                      _KpiCard(
                        title: 'IBAN',
                        value: mainAccount.iban,
                        subtitle: 'Conto operativo',
                        icon: Icons.numbers_rounded,
                        compactValue: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Operazioni rapide',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accedi rapidamente ai servizi più usati del tuo home banking.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1250
                          ? 3
                          : constraints.maxWidth > 760
                              ? 2
                              : 1;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.34,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _QuickActionCard(
                            title: 'Conti e movimenti',
                            subtitle:
                                'Consulta saldo, movimenti e dettaglio del conto.',
                            icon: Icons.account_balance_outlined,
                            tag: 'Dettaglio',
                            onTap: () => context.go(RouteNames.accounts),
                          ),
                          _QuickActionCard(
                            title: 'Bonifico',
                            subtitle:
                                'Esegui un bonifico ordinario o istantaneo.',
                            icon: Icons.swap_horiz_rounded,
                            tag: 'Nuovo',
                            onTap: () => context.go(RouteNames.transfers),
                          ),
                          _QuickActionCard(
                            title: 'Pagamento',
                            subtitle:
                                'Gestisci bollettini, PagoPA e codici simulati.',
                            icon: Icons.qr_code_scanner_outlined,
                            tag: 'Operativo',
                            onTap: () => context.go(RouteNames.payments),
                          ),
                          _QuickActionCard(
                            title: 'Carte',
                            subtitle:
                                'Visualizza carte, plafond e movimenti associati.',
                            icon: Icons.credit_card_outlined,
                            tag: 'Carte',
                            onTap: () => context.go(RouteNames.cards),
                          ),
                          _QuickActionCard(
                            title: 'Profilo',
                            subtitle:
                                'Aggiorna dati anagrafici e preferenze tema.',
                            icon: Icons.person_outline_rounded,
                            tag: 'Utente',
                            onTap: () => context.go(RouteNames.profile),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onRefresh;

  const _DashboardHeader({
    required this.userName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bentornato/a, $userName',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ecco una vista aggiornata del tuo conto e delle operazioni più frequenti.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.tonalIcon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Aggiorna'),
        ),
      ],
    );
  }
}

class _MainAccountHeroCard extends StatelessWidget {
  final AccountModel account;
  final double monthlySpent;
  final String Function(double) formatCurrency;
  final VoidCallback onViewTransactions;
  final VoidCallback onNewTransfer;

  const _MainAccountHeroCard({
    required this.account,
    required this.monthlySpent,
    required this.formatCurrency,
    required this.onViewTransactions,
    required this.onNewTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Conto principale',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Operativo',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              account.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              formatCurrency(account.balance),
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo disponibile',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.86),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _HeroInfoItem(
                  label: 'IBAN',
                  value: account.iban,
                ),
                _HeroInfoItem(
                  label: 'Spesa del mese',
                  value: formatCurrency(monthlySpent),
                ),
                _HeroInfoItem(
                  label: 'Tipologia',
                  value: account.type.toUpperCase(),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onViewTransactions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Vedi movimenti'),
                ),
                OutlinedButton.icon(
                  onPressed: onNewTransfer,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.48),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Nuovo bonifico'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _HeroInfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 170, maxWidth: 260),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.70),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String Function(double) formatCurrency;
  final String Function(String) formatDate;
  final VoidCallback onSeeAll;

  const _RecentTransactionsCard({
    required this.transactions,
    required this.formatCurrency,
    required this.formatDate,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ultimi movimenti',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('Vedi tutti'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Le operazioni più recenti del conto principale.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Non ci sono ancora movimenti recenti su questo conto.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              Column(
                children: transactions
                    .map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TransactionRow(
                          transaction: transaction,
                          formatCurrency: formatCurrency,
                          formatDate: formatDate,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final String Function(double) formatCurrency;
  final String Function(String) formatDate;

  const _TransactionRow({
    required this.transaction,
    required this.formatCurrency,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebit = transaction.isDebit;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.42),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDebit
                  ? Colors.red.withOpacity(0.10)
                  : Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isDebit
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: isDebit ? Colors.red.shade400 : Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.category} • ${formatDate(transaction.date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isDebit ? '-' : '+'}${formatCurrency(transaction.amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDebit ? Colors.red.shade400 : Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool compactValue;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.compactValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: (compactValue
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
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

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'Apri sezione',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _LoadingBox(height: 240),
        const SizedBox(height: 20),
        Row(
          children: const [
            Expanded(child: _LoadingBox(height: 130)),
            SizedBox(width: 16),
            Expanded(child: _LoadingBox(height: 130)),
          ],
        ),
        const SizedBox(height: 24),
        const _LoadingBox(height: 300),
      ],
    );
  }
}

class _LoadingBox extends StatelessWidget {
  final double height;

  const _LoadingBox({
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardErrorState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              'Impossibile caricare la dashboard',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Si è verificato un problema nel recupero dei dati del conto. Riprova tra qualche istante.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  final VoidCallback onGoToAccounts;

  const _DashboardEmptyState({
    required this.onGoToAccounts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Nessun conto disponibile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Non risultano conti associati al profilo corrente. Apri la sezione conti per verificare i dati disponibili.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: onGoToAccounts,
              child: const Text('Vai ai conti'),
            ),
          ],
        ),
      ),
    );
  }
}