import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_banking/features/accounts/data/models/account_model.dart';
import 'package:home_banking/features/accounts/data/repositories/accounts_repository.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/features/cards/data/models/bank_card_model.dart';
import 'package:home_banking/features/cards/data/repositories/cards_repository.dart';
import 'package:home_banking/shared/widgets/app_scaffold.dart';

class CardsPage extends StatefulWidget {
  const CardsPage({super.key});

  @override
  State<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends State<CardsPage> {
  late final CardsRepository _cardsRepository;
  late final AccountsRepository _accountsRepository;
  late Future<_CardsPageData> _pageDataFuture;

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

  Color _cardColor(String colorName) {
    switch (colorName) {
      case 'gold':
        return const Color(0xFFC9A227);
      case 'black':
        return const Color(0xFF1F2937);
      case 'green':
        return const Color(0xFF166534);
      case 'blue':
      default:
        return const Color(0xFF1D4ED8);
    }
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Errore: ${snapshot.error}'),
            );
          }

          final pageData = snapshot.data ??
              const _CardsPageData(
                cards: [],
                accounts: [],
              );

          final cards = pageData.cards;
          final accounts = pageData.accounts;

          if (cards.isEmpty) {
            return const Center(
              child: Text('Nessuna carta trovata'),
            );
          }

          if (_selectedCardIndex >= cards.length) {
            _selectedCardIndex = 0;
          }

          final selectedCard = cards[_selectedCardIndex];
          final spent = _calculateSpent(selectedCard);
          final linkedAccount = _findLinkedAccount(selectedCard, accounts);
          final realAvailable =
              selectedCard.isCreditCard ? (selectedCard.limit - spent) : 0.0;

          return LayoutBuilder(
            builder: (context, constraints) {
              final movementsHeight =
                  constraints.maxHeight < 850 ? 260.0 : 360.0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Le tue carte',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seleziona una carta per visualizzare dettagli e movimenti.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final card = cards[index];
                          final isSelected = index == _selectedCardIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCardIndex = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 330,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _cardColor(card.color),
                                borderRadius: BorderRadius.circular(24),
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        width: 3,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 14,
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${card.circuit} • ${card.type == 'credit' ? 'Credito' : 'Debito'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    card.maskedNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          card.holderName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        card.expiry,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _CardInfoBox(
                          title: 'Tipo',
                          value:
                              selectedCard.isCreditCard ? 'Credito' : 'Debito',
                        ),
                        _CardInfoBox(
                          title: 'Stato',
                          value: selectedCard.status,
                        ),
                        _CardInfoBox(
                          title: 'Speso con questa carta',
                          value: '€ ${spent.toStringAsFixed(2)}',
                        ),
                        if (selectedCard.isCreditCard) ...[
                          _CardInfoBox(
                            title: 'Limite mensile',
                            value:
                                '€ ${selectedCard.limit.toStringAsFixed(2)}',
                          ),
                          _CardInfoBox(
                            title: 'Disponibilità residua',
                            value: '€ ${realAvailable.toStringAsFixed(2)}',
                          ),
                        ] else ...[
                          _CardInfoBox(
                            title: 'Saldo conto collegato',
                            value: linkedAccount != null
                                ? '€ ${linkedAccount.balance.toStringAsFixed(2)}'
                                : '--',
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Movimenti carta selezionata',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: movementsHeight,
                      child: Card(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(8),
                          itemCount: selectedCard.transactions.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final transaction =
                                selectedCard.transactions[index];

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.credit_card),
                              ),
                              title: Text(transaction.description),
                              subtitle: Text(
                                '${transaction.merchant} • ${transaction.date}',
                              ),
                              trailing: Text(
                                '- € ${transaction.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
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
          );
        },
      ),
    );
  }
}

class _CardInfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _CardInfoBox({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _CardsPageData {
  final List<BankCardModel> cards;
  final List<AccountModel> accounts;

  const _CardsPageData({
    required this.cards,
    required this.accounts,
  });
}