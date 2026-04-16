import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/models/transaction_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/shared/widgets/app_scaffold.dart';

class _AccountPalette {
  final Color primary;
  final Color secondary;
  final Color softBackground;
  final Color softIconBackground;
  final Color selectedBorder;
  final Color selectedFill;

  const _AccountPalette({
    required this.primary,
    required this.secondary,
    required this.softBackground,
    required this.softIconBackground,
    required this.selectedBorder,
    required this.selectedFill,
  });
}

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  late final AccountsRepository _repository;
  Future<List<AccountModel>>? _accountsFuture;
  final TextEditingController _searchController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
  );

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  String? _selectedAccountId;
  String _selectedFilter = 'all';

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

  _AccountPalette _paletteForAccount(AccountModel account) {
    final type = account.type.toLowerCase();
    final name = account.name.toLowerCase();

    final isSavings = type.contains('savings') || name.contains('risparmio');
    final isSmart = name.contains('smart');
    final isPersonal = name.contains('personale');

    if (isSavings) {
      return const _AccountPalette(
        primary: Color(0xFF0F766E),
        secondary: Color(0xFF14B8A6),
        softBackground: Color(0xFFE6FFFA),
        softIconBackground: Color(0xFFCCFBF1),
        selectedBorder: Color(0xFF0F766E),
        selectedFill: Color(0xFFE6FFFA),
      );
    }

    if (isSmart) {
      return const _AccountPalette(
        primary: Color(0xFF6D28D9),
        secondary: Color(0xFF8B5CF6),
        softBackground: Color(0xFFF3E8FF),
        softIconBackground: Color(0xFFE9D5FF),
        selectedBorder: Color(0xFF6D28D9),
        selectedFill: Color(0xFFF3E8FF),
      );
    }

    if (isPersonal) {
      return const _AccountPalette(
        primary: Color(0xFF1D4ED8),
        secondary: Color(0xFF60A5FA),
        softBackground: Color(0xFFEFF6FF),
        softIconBackground: Color(0xFFDBEAFE),
        selectedBorder: Color(0xFF1D4ED8),
        selectedFill: Color(0xFFEFF6FF),
      );
    }

    return const _AccountPalette(
      primary: Color(0xFF123B63),
      secondary: Color(0xFF3E7CB1),
      softBackground: Color(0xFFEAF2FB),
      softIconBackground: Color(0xFFD9E8F6),
      selectedBorder: Color(0xFF123B63),
      selectedFill: Color(0xFFEAF2FB),
    );
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

  List<TransactionModel> _sortTransactions(List<TransactionModel> items) {
    final transactions = List<TransactionModel>.from(items);
    transactions.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return transactions;
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> items) {
    final query = _searchController.text.trim().toLowerCase();

    return items.where((transaction) {
      final matchesQuery = query.isEmpty ||
          transaction.description.toLowerCase().contains(query) ||
          transaction.category.toLowerCase().contains(query) ||
          transaction.date.toLowerCase().contains(query);

      final matchesType = switch (_selectedFilter) {
        'debit' => transaction.isDebit,
        'credit' => !transaction.isDebit,
        _ => true,
      };

      return matchesQuery && matchesType;
    }).toList();
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

    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    return AppScaffold(
      title: 'Conti',
      showBackButton: true,
      child: FutureBuilder<List<AccountModel>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final accounts = snapshot.data ?? [];

          if (!isLoading &&
              accounts.isNotEmpty &&
              (_selectedAccountId == null ||
                  !accounts.any((a) => a.id == _selectedAccountId))) {
            _selectedAccountId = accounts.first.id;
          }

          final selectedAccount = accounts.isEmpty
              ? null
              : accounts.firstWhere(
                  (account) => account.id == _selectedAccountId,
                  orElse: () => accounts.first,
                );

          final monthlySpent = selectedAccount == null
              ? 0.0
              : _calculateMonthlySpent(selectedAccount);

          final filteredTransactions = selectedAccount == null
              ? <TransactionModel>[]
              : _filterTransactions(
                  _sortTransactions(selectedAccount.transactions),
                );

          final selectedPalette = selectedAccount == null
              ? const _AccountPalette(
                  primary: Color(0xFF123B63),
                  secondary: Color(0xFF3E7CB1),
                  softBackground: Color(0xFFEAF2FB),
                  softIconBackground: Color(0xFFD9E8F6),
                  selectedBorder: Color(0xFF123B63),
                  selectedFill: Color(0xFFEAF2FB),
                )
              : _paletteForAccount(selectedAccount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AccountsHeader(
                  accountCount: accounts.length,
                  onRefresh: _reloadData,
                ),
                const SizedBox(height: 24),
                if (isLoading) ...[
                  const _AccountsLoadingState(),
                ] else if (hasError) ...[
                  _AccountsErrorState(onRetry: _reloadData),
                ] else if (accounts.isEmpty) ...[
                  const _AccountsEmptyState(),
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
                              child: _AccountHeroCard(
                                account: selectedAccount!,
                                monthlySpent: monthlySpent,
                                formatCurrency: _formatCurrency,
                                palette: selectedPalette,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: _AccountSelectorCard(
                                accounts: accounts,
                                selectedAccountId: _selectedAccountId!,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAccountId = value;
                                  });
                                },
                                formatCurrency: _formatCurrency,
                                paletteForAccount: _paletteForAccount,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _AccountHeroCard(
                            account: selectedAccount!,
                            monthlySpent: monthlySpent,
                            formatCurrency: _formatCurrency,
                            palette: selectedPalette,
                          ),
                          const SizedBox(height: 20),
                          _AccountSelectorCard(
                            accounts: accounts,
                            selectedAccountId: _selectedAccountId!,
                            onChanged: (value) {
                              setState(() {
                                _selectedAccountId = value;
                              });
                            },
                            formatCurrency: _formatCurrency,
                            paletteForAccount: _paletteForAccount,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _InfoCard(
                        title: 'Saldo disponibile',
                        value: _formatCurrency(selectedAccount!.balance),
                        subtitle: selectedAccount.name,
                        icon: Icons.account_balance_wallet_outlined,
                        palette: selectedPalette,
                      ),
                      _InfoCard(
                        title: 'Spesa del mese',
                        value: _formatCurrency(monthlySpent),
                        subtitle: 'Addebiti del mese corrente',
                        icon: Icons.trending_down_rounded,
                        palette: selectedPalette,
                      ),
                      _InfoCard(
                        title: 'IBAN',
                        value: selectedAccount.iban,
                        subtitle: 'Conto operativo',
                        icon: Icons.numbers_rounded,
                        compactValue: true,
                        palette: selectedPalette,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _TransactionsSection(
                    controller: _searchController,
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (value) {
                      setState(() {
                        _selectedFilter = value;
                      });
                    },
                    onSearchChanged: (_) => setState(() {}),
                    transactions: filteredTransactions,
                    formatCurrency: _formatCurrency,
                    formatDate: _formatDate,
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

class _AccountsHeader extends StatelessWidget {
  final int accountCount;
  final VoidCallback onRefresh;

  const _AccountsHeader({
    required this.accountCount,
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
                'Conti e movimenti',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                accountCount > 1
                    ? 'Consulta i tuoi conti, confronta saldi e controlla i movimenti più recenti.'
                    : 'Consulta saldo, IBAN e movimenti del tuo conto principale.',
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

class _AccountHeroCard extends StatelessWidget {
  final AccountModel account;
  final double monthlySpent;
  final String Function(double) formatCurrency;
  final _AccountPalette palette;

  const _AccountHeroCard({
    required this.account,
    required this.monthlySpent,
    required this.formatCurrency,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.primary,
            palette.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withOpacity(0.18),
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
              children: [
                _HeroBadge(label: 'Conto selezionato'),
                _HeroBadge(label: account.type.toUpperCase()),
              ],
            ),
            const SizedBox(height: 22),
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
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo disponibile',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _HeroInfoItem(label: 'IBAN', value: account.iban),
                _HeroInfoItem(
                  label: 'Spesa del mese',
                  value: formatCurrency(monthlySpent),
                ),
                _HeroInfoItem(
                  label: 'Movimenti',
                  value: '${account.transactions.length}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
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

class _AccountSelectorCard extends StatelessWidget {
  final List<AccountModel> accounts;
  final String selectedAccountId;
  final ValueChanged<String> onChanged;
  final String Function(double) formatCurrency;
  final _AccountPalette Function(AccountModel account) paletteForAccount;

  const _AccountSelectorCard({
    required this.accounts,
    required this.selectedAccountId,
    required this.onChanged,
    required this.formatCurrency,
    required this.paletteForAccount,
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
            Text(
              'Seleziona conto',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scegli il conto da visualizzare per consultare saldo e movimenti.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ...accounts.map(
              (account) {
                final isSelected = account.id == selectedAccountId;
                final palette = paletteForAccount(account);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onChanged(account.id),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.selectedFill
                            : theme.colorScheme.surfaceContainerHighest
                                .withOpacity(0.35),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? palette.selectedBorder
                              : theme.colorScheme.outline.withOpacity(0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.softIconBackground
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: isSelected
                                  ? palette.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${account.type.toUpperCase()} • ${account.iban}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatCurrency(account.balance),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool compactValue;
  final _AccountPalette palette;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.compactValue = false,
    required this.palette,
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
                  color: palette.softBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: palette.primary,
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

class _TransactionsSection extends StatelessWidget {
  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final List<TransactionModel> transactions;
  final String Function(double) formatCurrency;
  final String Function(String) formatDate;

  const _TransactionsSection({
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.transactions,
    required this.formatCurrency,
    required this.formatDate,
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
            Text(
              'Movimenti',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cerca, filtra e consulta le operazioni registrate sul conto selezionato.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: controller,
                          onChanged: onSearchChanged,
                          decoration: const InputDecoration(
                            labelText: 'Cerca un movimento',
                            hintText: 'Es. bonifico, ATM, bolletta...',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: selectedFilter,
                          onChanged: (value) {
                            if (value != null) onFilterChanged(value);
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text('Tutti i movimenti'),
                            ),
                            DropdownMenuItem(
                              value: 'debit',
                              child: Text('Solo addebiti'),
                            ),
                            DropdownMenuItem(
                              value: 'credit',
                              child: Text('Solo accrediti'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Filtro',
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    TextField(
                      controller: controller,
                      onChanged: onSearchChanged,
                      decoration: const InputDecoration(
                        labelText: 'Cerca un movimento',
                        hintText: 'Es. bonifico, ATM, bolletta...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFilter,
                      onChanged: (value) {
                        if (value != null) onFilterChanged(value);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Tutti i movimenti'),
                        ),
                        DropdownMenuItem(
                          value: 'debit',
                          child: Text('Solo addebiti'),
                        ),
                        DropdownMenuItem(
                          value: 'credit',
                          child: Text('Solo accrediti'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Filtro',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Nessun movimento trovato con i filtri selezionati.',
                  style: theme.textTheme.bodyMedium,
                ),
              )
            else
              ListView.separated(
                itemCount: transactions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _TransactionTile(
                    transaction: transaction,
                    formatCurrency: formatCurrency,
                    formatDate: formatDate,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final String Function(double) formatCurrency;
  final String Function(String) formatDate;

  const _TransactionTile({
    required this.transaction,
    required this.formatCurrency,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDebit = transaction.isDebit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDebit
                  ? Colors.red.withOpacity(0.10)
                  : Colors.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
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

class _AccountsLoadingState extends StatelessWidget {
  const _AccountsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _LoadingBox(height: 230),
        const SizedBox(height: 20),
        Row(
          children: const [
            Expanded(child: _LoadingBox(height: 130)),
            SizedBox(width: 16),
            Expanded(child: _LoadingBox(height: 130)),
          ],
        ),
        const SizedBox(height: 20),
        const _LoadingBox(height: 420),
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

class _AccountsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _AccountsErrorState({
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
              'Impossibile caricare i conti',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Si è verificato un problema durante il recupero dei dati. Riprova tra qualche istante.',
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

class _AccountsEmptyState extends StatelessWidget {
  const _AccountsEmptyState();

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
              'Nessun conto trovato',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Non risultano conti associati al profilo corrente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}