import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/features/transfers/data/repositories/transfers_repository.dart';
import 'package:home_banking/features/transfers/presentation/bloc/transfers_bloc.dart';
import 'package:home_banking/features/transfers/presentation/bloc/transfers_event.dart';
import 'package:home_banking/features/transfers/presentation/bloc/transfers_state.dart';
import 'package:home_banking/shared/widgets/app_scaffold.dart';

class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (_) => TransfersBloc(
        repository: TransfersRepository(),
      )..add(TransfersLoadRequested(authState.user.id)),
      child: const _TransfersView(),
    );
  }
}

class _TransfersView extends StatefulWidget {
  const _TransfersView();

  @override
  State<_TransfersView> createState() => _TransfersViewState();
}

class _TransfersViewState extends State<_TransfersView> {
  final _formKey = GlobalKey<FormState>();
  final _beneficiaryNameController = TextEditingController();
  final _beneficiaryIbanController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
  );

  String? _selectedAccountId;
  String _selectedTransferType = 'ordinary';

  @override
  void initState() {
    super.initState();
    _applyTransferPreset('ordinary');
  }

  @override
  void dispose() {
    _beneficiaryNameController.dispose();
    _beneficiaryIbanController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyTransferPreset(String type) {
    setState(() {
      _selectedTransferType = type;
    });

    switch (type) {
      case 'instant':
        _beneficiaryNameController.text = 'Luca Bianchi';
        _beneficiaryIbanController.text = 'IT60X0542811101000000123456';
        _descriptionController.text = 'Bonifico istantaneo demo';
        _amountController.text = '75.00';
        break;
      case 'ordinary':
      default:
        _beneficiaryNameController.text = 'Giulia Rossi';
        _beneficiaryIbanController.text = 'IT40S0306909606100000123456';
        _descriptionController.text = 'Bonifico ordinario demo';
        _amountController.text = '120.00';
        break;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona il conto da cui partire'),
        ),
      );
      return;
    }

    context.read<TransfersBloc>().add(
          TransferSubmitRequested(
            accountId: _selectedAccountId!,
            beneficiaryName: _beneficiaryNameController.text.trim(),
            beneficiaryIban: _beneficiaryIbanController.text.trim(),
            description: _descriptionController.text.trim(),
            amount: double.tryParse(
                  _amountController.text.trim().replaceAll(',', '.'),
                ) ??
                0,
            transferType: _selectedTransferType,
          ),
        );
  }

  double _parsedAmount() {
    return double.tryParse(
          _amountController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Bonifici',
      showBackButton: true,
      child: BlocConsumer<TransfersBloc, TransfersState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );
          }

          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
              ),
            );
            _applyTransferPreset('ordinary');
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: _TransfersLoadingState(),
            );
          }

          if (state.accounts.isEmpty) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: _TransfersEmptyState(),
            );
          }

          if (_selectedAccountId == null && state.accounts.isNotEmpty) {
            _selectedAccountId = state.accounts.first.id;
          }

          final selectedAccount = _selectedAccountId == null
              ? null
              : state.accounts.where((a) => a.id == _selectedAccountId).isNotEmpty
                  ? state.accounts.firstWhere((a) => a.id == _selectedAccountId)
                  : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TransfersHeader(
                  onRefresh: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      context
                          .read<TransfersBloc>()
                          .add(TransfersLoadRequested(authState.user.id));
                    }
                  },
                ),
                const SizedBox(height: 24),
                _TransferHeroCard(
                  transferType: _selectedTransferType,
                  amountText: _amountController.text.trim(),
                ),
                const SizedBox(height: 28),
                Text(
                  'Conto di partenza',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleziona il conto operativo da cui desideri inviare il bonifico.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: state.accounts.map((account) {
                    final isSelected = account.id == _selectedAccountId;

                    return _TransferAccountCard(
                      account: account,
                      isSelected: isSelected,
                      formatCurrency: _currencyFormat.format,
                      onTap: () {
                        setState(() {
                          _selectedAccountId = account.id;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _TransferFormCard(
                              formKey: _formKey,
                              beneficiaryNameController:
                                  _beneficiaryNameController,
                              beneficiaryIbanController:
                                  _beneficiaryIbanController,
                              descriptionController: _descriptionController,
                              amountController: _amountController,
                              selectedTransferType: _selectedTransferType,
                              onTransferTypeChanged: _applyTransferPreset,
                              onAmountChanged: (_) => setState(() {}),
                              isSubmitting: state.isSubmitting,
                              onSubmit: _submit,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: _TransferSummaryCard(
                              selectedAccountName:
                                  selectedAccount?.name ?? 'Nessun conto selezionato',
                              selectedAccountIban: selectedAccount?.iban ?? '--',
                              selectedTransferType: _selectedTransferType,
                              beneficiaryName:
                                  _beneficiaryNameController.text.trim().isEmpty
                                      ? '--'
                                      : _beneficiaryNameController.text.trim(),
                              beneficiaryIban:
                                  _beneficiaryIbanController.text.trim().isEmpty
                                      ? '--'
                                      : _beneficiaryIbanController.text.trim(),
                              description:
                                  _descriptionController.text.trim().isEmpty
                                      ? '--'
                                      : _descriptionController.text.trim(),
                              amount: _parsedAmount(),
                              formatCurrency: _currencyFormat.format,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _TransferFormCard(
                          formKey: _formKey,
                          beneficiaryNameController: _beneficiaryNameController,
                          beneficiaryIbanController: _beneficiaryIbanController,
                          descriptionController: _descriptionController,
                          amountController: _amountController,
                          selectedTransferType: _selectedTransferType,
                          onTransferTypeChanged: _applyTransferPreset,
                          onAmountChanged: (_) => setState(() {}),
                          isSubmitting: state.isSubmitting,
                          onSubmit: _submit,
                        ),
                        const SizedBox(height: 20),
                        _TransferSummaryCard(
                          selectedAccountName:
                              selectedAccount?.name ?? 'Nessun conto selezionato',
                          selectedAccountIban: selectedAccount?.iban ?? '--',
                          selectedTransferType: _selectedTransferType,
                          beneficiaryName:
                              _beneficiaryNameController.text.trim().isEmpty
                                  ? '--'
                                  : _beneficiaryNameController.text.trim(),
                          beneficiaryIban:
                              _beneficiaryIbanController.text.trim().isEmpty
                                  ? '--'
                                  : _beneficiaryIbanController.text.trim(),
                          description:
                              _descriptionController.text.trim().isEmpty
                                  ? '--'
                                  : _descriptionController.text.trim(),
                          amount: _parsedAmount(),
                          formatCurrency: _currencyFormat.format,
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

class _TransfersHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _TransfersHeader({
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
                'Effettua un bonifico',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Compila i dati del beneficiario, scegli il conto operativo e conferma l’operazione.',
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

class _TransferHeroCard extends StatelessWidget {
  final String transferType;
  final String amountText;

  const _TransferHeroCard({
    required this.transferType,
    required this.amountText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInstant = transferType == 'instant';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isInstant
              ? const [Color(0xFF4C1D95), Color(0xFF7C3AED)]
              : const [Color(0xFF123B63), Color(0xFF3E7CB1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isInstant
                    ? const Color(0xFF4C1D95)
                    : const Color(0xFF123B63))
                .withOpacity(0.20),
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
                _HeroBadge(
                  label: isInstant ? 'Bonifico istantaneo' : 'Bonifico ordinario',
                ),
                _HeroBadge(
                  label: amountText.isEmpty ? 'Importo da definire' : 'Importo inserito',
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              isInstant
                  ? 'Invio immediato del denaro'
                  : 'Trasferimento bancario standard',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isInstant
                  ? 'Ideale per operazioni urgenti con accredito rapido.'
                  : 'Perfetto per disposizioni pianificate e operazioni standard.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({
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

class _TransferAccountCard extends StatelessWidget {
  final dynamic account;
  final bool isSelected;
  final String Function(num) formatCurrency;
  final VoidCallback onTap;

  const _TransferAccountCard({
    required this.account,
    required this.isSelected,
    required this.formatCurrency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SizedBox(
        width: 320,
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.28),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          account.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Selezionato',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    account.iban,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.40),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined),
                        const SizedBox(width: 10),
                        Text(
                          'Saldo disponibile: ${formatCurrency(account.balance)}',
                          style: theme.textTheme.titleSmall?.copyWith(
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
        ),
      ),
    );
  }
}

class _TransferFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController beneficiaryNameController;
  final TextEditingController beneficiaryIbanController;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final String selectedTransferType;
  final ValueChanged<String> onTransferTypeChanged;
  final ValueChanged<String> onAmountChanged;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _TransferFormCard({
    required this.formKey,
    required this.beneficiaryNameController,
    required this.beneficiaryIbanController,
    required this.descriptionController,
    required this.amountController,
    required this.selectedTransferType,
    required this.onTransferTypeChanged,
    required this.onAmountChanged,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dati del bonifico',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Compila tutti i campi richiesti per eseguire l’operazione.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'ordinary',
                    label: Text('Ordinario'),
                    icon: Icon(Icons.schedule_outlined),
                  ),
                  ButtonSegment<String>(
                    value: 'instant',
                    label: Text('Istantaneo'),
                    icon: Icon(Icons.flash_on_outlined),
                  ),
                ],
                selected: {selectedTransferType},
                onSelectionChanged: (selection) {
                  onTransferTypeChanged(selection.first);
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: beneficiaryNameController,
                onChanged: onAmountChanged,
                decoration: const InputDecoration(
                  labelText: 'Nome beneficiario',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci il nome del beneficiario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: beneficiaryIbanController,
                onChanged: onAmountChanged,
                decoration: const InputDecoration(
                  labelText: 'IBAN beneficiario',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci l’IBAN';
                  }
                  if (value.trim().length < 15) {
                    return 'IBAN non valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                onChanged: onAmountChanged,
                decoration: const InputDecoration(
                  labelText: 'Causale',
                  prefixIcon: Icon(Icons.edit_note_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci una causale';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: onAmountChanged,
                decoration: const InputDecoration(
                  labelText: 'Importo',
                  prefixIcon: Icon(Icons.euro_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci l’importo';
                  }
                  final parsed = double.tryParse(
                    value.trim().replaceAll(',', '.'),
                  );
                  if (parsed == null || parsed <= 0) {
                    return 'Importo non valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    isSubmitting ? 'Invio in corso...' : 'Conferma bonifico',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferSummaryCard extends StatelessWidget {
  final String selectedAccountName;
  final String selectedAccountIban;
  final String selectedTransferType;
  final String beneficiaryName;
  final String beneficiaryIban;
  final String description;
  final double amount;
  final String Function(num) formatCurrency;

  const _TransferSummaryCard({
    required this.selectedAccountName,
    required this.selectedAccountIban,
    required this.selectedTransferType,
    required this.beneficiaryName,
    required this.beneficiaryIban,
    required this.description,
    required this.amount,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final isInstant = selectedTransferType == 'instant';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riepilogo operazione',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Controlla i dati prima di confermare il bonifico.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            _SummaryItem(
              label: 'Tipologia',
              value: isInstant ? 'Istantaneo' : 'Ordinario',
            ),
            const SizedBox(height: 12),
            _SummaryItem(
              label: 'Conto di partenza',
              value: selectedAccountName,
            ),
            const SizedBox(height: 12),
            _SummaryItem(
              label: 'IBAN conto',
              value: selectedAccountIban,
            ),
            const SizedBox(height: 12),
            _SummaryItem(
              label: 'Beneficiario',
              value: beneficiaryName,
            ),
            const SizedBox(height: 12),
            _SummaryItem(
              label: 'IBAN beneficiario',
              value: beneficiaryIban,
            ),
            const SizedBox(height: 12),
            _SummaryItem(
              label: 'Causale',
              value: description,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.40),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Importo',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amount > 0 ? formatCurrency(amount) : '--',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.28),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransfersLoadingState extends StatelessWidget {
  const _TransfersLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LoadingBox(height: 180),
        SizedBox(height: 20),
        _LoadingBox(height: 180),
        SizedBox(height: 20),
        _LoadingBox(height: 520),
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

class _TransfersEmptyState extends StatelessWidget {
  const _TransfersEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.swap_horiz_rounded,
              size: 44,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Nessun conto operativo disponibile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Per effettuare un bonifico è necessario avere almeno un conto operativo disponibile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}