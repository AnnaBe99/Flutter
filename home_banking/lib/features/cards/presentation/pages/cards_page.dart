import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/features/cards/data/models/bank_card_model.dart';
import 'package:home_banking/features/cards/data/models/card_transaction_model.dart';
import 'package:home_banking/features/cards/data/repositories/cards_repository.dart';
import 'package:home_banking/shared/widgets/app_scaffold.dart';

class _CardPalette {
  final Color primary;
  final Color secondary;
  final Color softBackground;
  final Color softBorder;
  final Color textOnCard;

  const _CardPalette({
    required this.primary,
    required this.secondary,
    required this.softBackground,
    required this.softBorder,
    required this.textOnCard,
  });
}

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  late final CardsRepository _cardsRepository;
  late final AccountsRepository _accountsRepository;
  late Future<_CardsPageData> _pageDataFuture;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
  );

  int _selectedCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _cardsRepository = CardsRepository();
    _accountsRepository = AccountsRepository();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _pageDataFuture = _loadPageData(authState.user.id);
    } else {
      _pageDataFuture = Future.value(
        const _CardsPageData(
          cards: [],
          accounts: [],
        ),
      );
    }
  }

  Future<_CardsPageData> _loadPageData(int userId) async {
    final cards = await _cardsRepository.getCardsByUser(userId);
    final accounts = await _accountsRepository.getAccountsByUser(userId);

    return _CardsPageData(
      cards: cards,
      accounts: accounts,
    );
  }

  void _reloadData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      setState(() {
        _pageDataFuture = _loadPageData(authState.user.id);
      });
    }
  }

  double _calculateSpent(BankCardModel card) {
    return card.transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  AccountModel? _findLinkedAccount(
    BankCardModel card,
    List<AccountModel> accounts,
  ) {
    try {
      return accounts.firstWhere((account) => account.id == card.accountId);
    } catch (_) {
      return null;
    }
  }

  List<CardTransactionModel> _sortedTransactions(BankCardModel card) {
    final transactions = List<CardTransactionModel>.from(card.transactions);
    transactions.sort((a, b) {
      final dateA = DateTime.tryParse(a.date) ?? DateTime(1970);
      final dateB = DateTime.tryParse(b.date) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return transactions;
  }

  String _formatCurrency(double value) {
    return _currencyFormat.format(value);
  }

  _CardPalette _paletteForCard(BankCardModel card) {
    final colorName = card.color.toLowerCase();
    final type = card.type.toLowerCase();

    if (colorName == 'gold') {
      return const _CardPalette(
        primary: Color(0xFFB8871B),
        secondary: Color(0xFFE7C35A),
        softBackground: Color(0xFFFFF7E0),
        softBorder: Color(0xFFE7C35A),
        textOnCard: Colors.white,
      );
    }

    if (colorName == 'black') {
      return const _CardPalette(
        primary: Color(0xFF111827),
        secondary: Color(0xFF374151),
        softBackground: Color(0xFFF3F4F6),
        softBorder: Color(0xFF6B7280),
        textOnCard: Colors.white,
      );
    }

    if (colorName == 'green') {
      return const _CardPalette(
        primary: Color(0xFF0F766E),
        secondary: Color(0xFF14B8A6),
        softBackground: Color(0xFFE6FFFA),
        softBorder: Color(0xFF14B8A6),
        textOnCard: Colors.white,
      );
    }

    if (type == 'credit') {
      return const _CardPalette(
        primary: Color(0xFF4C1D95),
        secondary: Color(0xFF7C3AED),
        softBackground: Color(0xFFF3E8FF),
        softBorder: Color(0xFF8B5CF6),
        textOnCard: Colors.white,
      );
    }

    return const _CardPalette(
      primary: Color(0xFF123B63),
      secondary: Color(0xFF3E7CB1),
      softBackground: Color(0xFFEAF2FB),
      softBorder: Color(0xFF60A5FA),
      textOnCard: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    return AppScaffold(
      title: 'Carte',
      showBackButton: true,
      child: FutureBuilder<_CardsPageData>(
        future: _pageDataFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final hasError = snapshot.hasError;
          final pageData = snapshot.data ??
              const _CardsPageData(
                cards: [],
                accounts: [],
              );

          final cards = pageData.cards;
          final accounts = pageData.accounts;

          if (!isLoading && cards.isNotEmpty && _selectedCardIndex >= cards.length) {
            _selectedCardIndex = 0;
          }

          if (isLoading) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: _CardsLoadingState(),
            );
          }

          if (hasError) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _CardsErrorState(onRetry: _reloadData),
            );
          }

          if (cards.isEmpty) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: _CardsEmptyState(),
            );
          }

          final selectedCard = cards[_selectedCardIndex];
          final palette = _paletteForCard(selectedCard);
          final spent = _calculateSpent(selectedCard);
          final linkedAccount = _findLinkedAccount(selectedCard, accounts);
          final double availableAmount = selectedCard.isCreditCard
              ? (selectedCard.limit - spent).clamp(0, selectedCard.limit)
              : (linkedAccount?.balance ?? 0.0);
          final sortedTransactions = _sortedTransactions(selectedCard);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardsHeader(
                  cardsCount: cards.length,
                  onRefresh: _reloadData,
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _SelectedCardHero(
                              card: selectedCard,
                              palette: palette,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: _CardMetricsPanel(
                              selectedCard: selectedCard,
                              linkedAccount: linkedAccount,
                              spent: spent,
                              availableAmount: availableAmount,
                              formatCurrency: _formatCurrency,
                              palette: palette,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _SelectedCardHero(
                          card: selectedCard,
                          palette: palette,
                        ),
                        const SizedBox(height: 20),
                        _CardMetricsPanel(
                          selectedCard: selectedCard,
                          linkedAccount: linkedAccount,
                          spent: spent,
                          availableAmount: availableAmount,
                          formatCurrency: _formatCurrency,
                          palette: palette,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'Le tue carte',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleziona una carta per visualizzare dettagli, disponibilità e movimenti.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isSelected = index == _selectedCardIndex;
                      final cardPalette = _paletteForCard(card);

                      return _SelectableMiniCard(
                        card: card,
                        palette: cardPalette,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedCardIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                _CardInfoGrid(
                  selectedCard: selectedCard,
                  linkedAccount: linkedAccount,
                  spent: spent,
                  availableAmount: availableAmount,
                  formatCurrency: _formatCurrency,
                  palette: palette,
                ),
                const SizedBox(height: 32),
                _CardTransactionsSection(
                  transactions: sortedTransactions,
                  formatCurrency: _formatCurrency,
                  palette: palette,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardsHeader extends StatelessWidget {
  final int cardsCount;
  final VoidCallback onRefresh;

  const _CardsHeader({
    required this.cardsCount,
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
                'Carte e movimenti',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cardsCount > 1
                    ? 'Controlla tutte le tue carte, confronta disponibilità e verifica i movimenti recenti.'
                    : 'Controlla i dettagli della tua carta e i relativi movimenti.',
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

class _SelectedCardHero extends StatelessWidget {
  final BankCardModel card;
  final _CardPalette palette;

  const _SelectedCardHero({
    required this.card,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.primary, palette.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withOpacity(0.22),
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
                _CardHeroBadge(
                  label: card.isCreditCard ? 'Carta di credito' : 'Carta di debito',
                ),
                _CardHeroBadge(label: card.circuit),
                _CardHeroBadge(label: card.status),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              card.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: palette.textOnCard.withOpacity(0.95),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              card.maskedNumber,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: palette.textOnCard,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 32,
              runSpacing: 14,
              children: [
                _CardHeroInfoItem(
                  label: 'Intestatario',
                  value: card.holderName,
                ),
                _CardHeroInfoItem(
                  label: 'Scadenza',
                  value: card.expiry,
                ),
                _CardHeroInfoItem(
                  label: 'Tipologia',
                  value: card.isCreditCard ? 'Credito' : 'Debito',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeroBadge extends StatelessWidget {
  final String label;

  const _CardHeroBadge({
    required this.label,
  });

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

class _CardHeroInfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _CardHeroInfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 260),
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

class _CardMetricsPanel extends StatelessWidget {
  final BankCardModel selectedCard;
  final AccountModel? linkedAccount;
  final double spent;
  final double availableAmount;
  final String Function(double) formatCurrency;
  final _CardPalette palette;

  const _CardMetricsPanel({
    required this.selectedCard,
    required this.linkedAccount,
    required this.spent,
    required this.availableAmount,
    required this.formatCurrency,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panoramica carta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dati principali della carta selezionata.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            _MetricRow(
              title: 'Tipo',
              value: selectedCard.isCreditCard ? 'Credito' : 'Debito',
              palette: palette,
            ),
            const SizedBox(height: 12),
            _MetricRow(
              title: 'Stato',
              value: selectedCard.status,
              palette: palette,
            ),
            const SizedBox(height: 12),
            _MetricRow(
              title: 'Spese del mese',
              value: formatCurrency(spent),
              palette: palette,
            ),
            const SizedBox(height: 12),
            if (selectedCard.isCreditCard) ...[
              _MetricRow(
                title: 'Limite mensile',
                value: formatCurrency(selectedCard.limit),
                palette: palette,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                title: 'Disponibilità residua',
                value: formatCurrency(availableAmount),
                palette: palette,
              ),
            ] else ...[
              _MetricRow(
                title: 'Conto collegato',
                value: linkedAccount?.name ?? '--',
                palette: palette,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                title: 'Saldo conto collegato',
                value: linkedAccount != null
                    ? formatCurrency(linkedAccount!.balance)
                    : '--',
                palette: palette,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String title;
  final String value;
  final _CardPalette palette;

  const _MetricRow({
    required this.title,
    required this.value,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.softBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.softBorder.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _SelectableMiniCard extends StatelessWidget {
  final BankCardModel card;
  final _CardPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableMiniCard({
    required this.card,
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 320,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.primary, palette.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? palette.softBorder : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(isSelected ? 0.22 : 0.14),
              blurRadius: isSelected ? 18 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${card.circuit} • ${card.isCreditCard ? 'Credito' : 'Debito'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              card.maskedNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.holderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  card.expiry,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardInfoGrid extends StatelessWidget {
  final BankCardModel selectedCard;
  final AccountModel? linkedAccount;
  final double spent;
  final double availableAmount;
  final String Function(double) formatCurrency;
  final _CardPalette palette;

  const _CardInfoGrid({
    required this.selectedCard,
    required this.linkedAccount,
    required this.spent,
    required this.availableAmount,
    required this.formatCurrency,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _CardInfoBox(
          title: 'Tipo',
          value: selectedCard.isCreditCard ? 'Credito' : 'Debito',
          palette: palette,
          icon: Icons.credit_card_outlined,
        ),
        _CardInfoBox(
          title: 'Stato',
          value: selectedCard.status,
          palette: palette,
          icon: Icons.verified_user_outlined,
        ),
        _CardInfoBox(
          title: 'Spese del mese',
          value: formatCurrency(spent),
          palette: palette,
          icon: Icons.trending_down_rounded,
        ),
        if (selectedCard.isCreditCard) ...[
          _CardInfoBox(
            title: 'Limite mensile',
            value: formatCurrency(selectedCard.limit),
            palette: palette,
            icon: Icons.speed_outlined,
          ),
          _CardInfoBox(
            title: 'Disponibilità residua',
            value: formatCurrency(availableAmount),
            palette: palette,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ] else ...[
          _CardInfoBox(
            title: 'Conto collegato',
            value: linkedAccount?.name ?? '--',
            palette: palette,
            icon: Icons.link_rounded,
          ),
          _CardInfoBox(
            title: 'Saldo conto collegato',
            value: linkedAccount != null
                ? formatCurrency(linkedAccount!.balance)
                : '--',
            palette: palette,
            icon: Icons.savings_outlined,
          ),
        ],
      ],
    );
  }
}

class _CardInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final _CardPalette palette;
  final IconData icon;

  const _CardInfoBox({
    required this.title,
    required this.value,
    required this.palette,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.softBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 14),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
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

class _CardTransactionsSection extends StatelessWidget {
  final List<CardTransactionModel> transactions;
  final String Function(double) formatCurrency;
  final _CardPalette palette;

  const _CardTransactionsSection({
    required this.transactions,
    required this.formatCurrency,
    required this.palette,
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
              'Movimenti carta selezionata',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Consulta le operazioni più recenti eseguite con la carta selezionata.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Non ci sono ancora movimenti registrati per questa carta.',
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
                  return _CardTransactionTile(
                    transaction: transaction,
                    formatCurrency: formatCurrency,
                    palette: palette,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CardTransactionTile extends StatelessWidget {
  final CardTransactionModel transaction;
  final String Function(double) formatCurrency;
  final _CardPalette palette;

  const _CardTransactionTile({
    required this.transaction,
    required this.formatCurrency,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.softBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.credit_card_rounded,
              color: palette.primary,
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
                  '${transaction.merchant} • ${transaction.date}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '- ${formatCurrency(transaction.amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardsLoadingState extends StatelessWidget {
  const _CardsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LoadingBox(height: 240),
        SizedBox(height: 20),
        _LoadingBox(height: 210),
        SizedBox(height: 20),
        _LoadingBox(height: 160),
        SizedBox(height: 20),
        _LoadingBox(height: 420),
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

class _CardsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _CardsErrorState({
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
              'Impossibile caricare le carte',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Si è verificato un problema durante il recupero delle carte e dei relativi movimenti.',
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

class _CardsEmptyState extends StatelessWidget {
  const _CardsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Nessuna carta trovata',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Non risultano carte associate al profilo corrente.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardsPageData {
  final List<BankCardModel> cards;
  final List<AccountModel> accounts;

  const _CardsPageData({
    required this.cards,
    required this.accounts,
  });
}