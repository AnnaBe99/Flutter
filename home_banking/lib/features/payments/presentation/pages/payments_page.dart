import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/features/payments/data/repositories/payments_repository.dart';
import 'package:home_banking/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:home_banking/features/payments/presentation/bloc/payments_event.dart';
import 'package:home_banking/features/payments/presentation/bloc/payments_state.dart';
import 'package:home_banking/shared/widgets/app_scaffold.dart';

class _PaymentPalette {
  final Color primary;
  final Color secondary;
  final Color softBackground;
  final Color softBorder;

  const _PaymentPalette({
    required this.primary,
    required this.secondary,
    required this.softBackground,
    required this.softBorder,
  });
}

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    return BlocProvider(
      create: (_) => PaymentsBloc(
        repository: PaymentsRepository(),
      )..add(PaymentsLoadRequested(authState.user.id)),
      child: const _PaymentsView(),
    );
  }
}

class _PaymentsView extends StatefulWidget {
  const _PaymentsView();

  @override
  State<_PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<_PaymentsView> {
  final _formKey = GlobalKey<FormState>();
  final _providerController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'it_IT',
    symbol: '€',
  );

  String? _selectedAccountId;
  String _selectedPaymentType = 'bollettino';

  @override
  void initState() {
    super.initState();
    _applyPaymentPreset('bollettino');
  }

  @override
  void dispose() {
    _providerController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  _PaymentPalette _paletteForPaymentType(String type) {
    switch (type) {
      case 'pagopa':
        return const _PaymentPalette(
          primary: Color(0xFF0F766E),
          secondary: Color(0xFF14B8A6),
          softBackground: Color(0xFFE6FFFA),
          softBorder: Color(0xFF14B8A6),
        );
      case 'barcode':
        return const _PaymentPalette(
          primary: Color(0xFF6D28D9),
          secondary: Color(0xFF8B5CF6),
          softBackground: Color(0xFFF3E8FF),
          softBorder: Color(0xFF8B5CF6),
        );
      case 'bollettino':
      default:
        return const _PaymentPalette(
          primary: Color(0xFF123B63),
          secondary: Color(0xFF3E7CB1),
          softBackground: Color(0xFFEAF2FB),
          softBorder: Color(0xFF60A5FA),
        );
    }
  }

  void _applyPaymentPreset(String type) {
    setState(() {
      _selectedPaymentType = type;
    });

    switch (type) {
      case 'bollettino':
        _providerController.text = 'Poste Italiane';
        _codeController.text = '896700000000123456';
        _descriptionController.text = 'Pagamento bollettino';
        break;
      case 'pagopa':
        _providerController.text = 'Comune di Milano';
        _codeController.text = '302000000000987654';
        _descriptionController.text = 'Pagamento avviso PagoPA';
        break;
      case 'barcode':
        _providerController.text = 'Ente convenzionato';
        _codeController.text = 'QR-2026-00123456';
        _descriptionController.text = 'Pagamento da codice simulato';
        break;
    }
  }

  String _paymentTypeLabel(String type) {
    switch (type) {
      case 'pagopa':
        return 'PagoPA';
      case 'barcode':
        return 'QR / Barcode';
      case 'bollettino':
      default:
        return 'Bollettino';
    }
  }

  String _paymentTypeDescription(String type) {
    switch (type) {
      case 'pagopa':
        return 'Pagamento di avvisi verso enti pubblici e amministrazioni.';
      case 'barcode':
        return 'Simulazione di pagamento tramite scansione di codice.';
      case 'bollettino':
      default:
        return 'Pagamento classico di bollettini, utenze e avvisi postali.';
    }
  }

  String _codeFieldLabel(String type) {
    switch (type) {
      case 'pagopa':
        return 'Codice avviso';
      case 'barcode':
        return 'Codice QR / Barcode';
      case 'bollettino':
      default:
        return 'Codice bollettino';
    }
  }

  String _providerFieldLabel(String type) {
    switch (type) {
      case 'pagopa':
        return 'Ente creditore';
      case 'barcode':
        return 'Esercente / ente';
      case 'bollettino':
      default:
        return 'Ente / fornitore';
    }
  }

  double _parsedAmount() {
    return double.tryParse(
          _amountController.text.trim().replaceAll(',', '.'),
        ) ??
        0.0;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona il conto da cui addebitare'),
        ),
      );
      return;
    }

    context.read<PaymentsBloc>().add(
          PaymentSubmitRequested(
            accountId: _selectedAccountId!,
            paymentType: _selectedPaymentType,
            provider: _providerController.text.trim(),
            code: _codeController.text.trim(),
            description: _descriptionController.text.trim(),
            amount: _parsedAmount(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForPaymentType(_selectedPaymentType);

    return AppScaffold(
      title: 'Pagamenti',
      showBackButton: true,
      child: BlocConsumer<PaymentsBloc, PaymentsState>(
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

            _applyPaymentPreset('bollettino');
            _amountController.clear();
            _selectedAccountId = null;
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: _PaymentsLoadingState(),
            );
          }

          if (state.accounts.isEmpty) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: _PaymentsEmptyState(),
            );
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
                _PaymentsHeader(
                  onRefresh: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthAuthenticated) {
                      context
                          .read<PaymentsBloc>()
                          .add(PaymentsLoadRequested(authState.user.id));
                    }
                  },
                ),
                const SizedBox(height: 24),
                _PaymentHeroCard(
                  typeLabel: _paymentTypeLabel(_selectedPaymentType),
                  description: _paymentTypeDescription(_selectedPaymentType),
                  palette: palette,
                ),
                const SizedBox(height: 28),
                Text(
                  'Metodo di pagamento',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scegli la modalità con cui vuoi completare il pagamento.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _PaymentTypeCard(
                      title: 'Bollettino',
                      subtitle: 'Pagamento bollettino postale o utenza',
                      icon: Icons.receipt_long_outlined,
                      isSelected: _selectedPaymentType == 'bollettino',
                      onTap: () => _applyPaymentPreset('bollettino'),
                      palette: _paletteForPaymentType('bollettino'),
                    ),
                    _PaymentTypeCard(
                      title: 'PagoPA',
                      subtitle: 'Avviso verso ente pubblico o comune',
                      icon: Icons.account_balance_outlined,
                      isSelected: _selectedPaymentType == 'pagopa',
                      onTap: () => _applyPaymentPreset('pagopa'),
                      palette: _paletteForPaymentType('pagopa'),
                    ),
                    _PaymentTypeCard(
                      title: 'QR / Barcode',
                      subtitle: 'Simulazione scansione codice pagamento',
                      icon: Icons.qr_code_scanner_outlined,
                      isSelected: _selectedPaymentType == 'barcode',
                      onTap: () => _applyPaymentPreset('barcode'),
                      palette: _paletteForPaymentType('barcode'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Conto di addebito',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleziona il conto da cui desideri addebitare il pagamento.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: state.accounts.map((account) {
                    final isSelected = account.id == _selectedAccountId;

                    return _PaymentAccountCard(
                      account: account,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedAccountId = account.id;
                        });
                      },
                      formatCurrency: _currencyFormat.format,
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
                            child: _PaymentFormCard(
                              formKey: _formKey,
                              providerController: _providerController,
                              codeController: _codeController,
                              descriptionController: _descriptionController,
                              amountController: _amountController,
                              providerLabel:
                                  _providerFieldLabel(_selectedPaymentType),
                              codeLabel: _codeFieldLabel(_selectedPaymentType),
                              selectedPaymentType:
                                  _paymentTypeLabel(_selectedPaymentType),
                              palette: palette,
                              onAmountChanged: (_) => setState(() {}),
                              isSubmitting: state.isSubmitting,
                              onSubmit: _submit,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: _PaymentSummaryCard(
                              paymentTypeLabel:
                                  _paymentTypeLabel(_selectedPaymentType),
                              accountName:
                                  selectedAccount?.name ?? 'Nessun conto selezionato',
                              accountIban: selectedAccount?.iban ?? '--',
                              provider: _providerController.text.trim().isEmpty
                                  ? '--'
                                  : _providerController.text.trim(),
                              code: _codeController.text.trim().isEmpty
                                  ? '--'
                                  : _codeController.text.trim(),
                              description:
                                  _descriptionController.text.trim().isEmpty
                                      ? '--'
                                      : _descriptionController.text.trim(),
                              amount: _parsedAmount(),
                              formatCurrency: _currencyFormat.format,
                              palette: palette,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        _PaymentFormCard(
                          formKey: _formKey,
                          providerController: _providerController,
                          codeController: _codeController,
                          descriptionController: _descriptionController,
                          amountController: _amountController,
                          providerLabel:
                              _providerFieldLabel(_selectedPaymentType),
                          codeLabel: _codeFieldLabel(_selectedPaymentType),
                          selectedPaymentType:
                              _paymentTypeLabel(_selectedPaymentType),
                          palette: palette,
                          onAmountChanged: (_) => setState(() {}),
                          isSubmitting: state.isSubmitting,
                          onSubmit: _submit,
                        ),
                        const SizedBox(height: 20),
                        _PaymentSummaryCard(
                          paymentTypeLabel:
                              _paymentTypeLabel(_selectedPaymentType),
                          accountName:
                              selectedAccount?.name ?? 'Nessun conto selezionato',
                          accountIban: selectedAccount?.iban ?? '--',
                          provider: _providerController.text.trim().isEmpty
                              ? '--'
                              : _providerController.text.trim(),
                          code: _codeController.text.trim().isEmpty
                              ? '--'
                              : _codeController.text.trim(),
                          description:
                              _descriptionController.text.trim().isEmpty
                                  ? '--'
                                  : _descriptionController.text.trim(),
                          amount: _parsedAmount(),
                          formatCurrency: _currencyFormat.format,
                          palette: palette,
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

class _PaymentsHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _PaymentsHeader({
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
                'Effettua un pagamento',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seleziona la modalità di pagamento e completa i dati dell’avviso o del bollettino.',
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

class _PaymentHeroCard extends StatelessWidget {
  final String typeLabel;
  final String description;
  final _PaymentPalette palette;

  const _PaymentHeroCard({
    required this.typeLabel,
    required this.description,
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
            color: palette.primary.withOpacity(0.20),
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
            _HeroBadge(label: typeLabel),
            const SizedBox(height: 22),
            Text(
              'Pagamento selezionato',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
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

class _PaymentTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final _PaymentPalette palette;

  const _PaymentTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SizedBox(
        width: 290,
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? palette.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _PaymentAccountCard extends StatelessWidget {
  final dynamic account;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(num) formatCurrency;

  const _PaymentAccountCard({
    required this.account,
    required this.isSelected,
    required this.onTap,
    required this.formatCurrency,
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

class _PaymentFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController providerController;
  final TextEditingController codeController;
  final TextEditingController descriptionController;
  final TextEditingController amountController;
  final String providerLabel;
  final String codeLabel;
  final String selectedPaymentType;
  final _PaymentPalette palette;
  final ValueChanged<String> onAmountChanged;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _PaymentFormCard({
    required this.formKey,
    required this.providerController,
    required this.codeController,
    required this.descriptionController,
    required this.amountController,
    required this.providerLabel,
    required this.codeLabel,
    required this.selectedPaymentType,
    required this.palette,
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
                'Dati del pagamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Compila i campi richiesti e verifica il codice prima di confermare.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: palette.softBackground,
                  border: Border.all(
                    color: palette.softBorder.withOpacity(0.45),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: palette.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tipo selezionato: $selectedPaymentType',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: providerController,
                onChanged: onAmountChanged,
                decoration: InputDecoration(
                  labelText: providerLabel,
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci il soggetto del pagamento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: codeController,
                onChanged: onAmountChanged,
                decoration: InputDecoration(
                  labelText: codeLabel,
                  prefixIcon: const Icon(Icons.qr_code_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci il codice del pagamento';
                  }
                  if (value.trim().length < 8) {
                    return 'Codice non valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                onChanged: onAmountChanged,
                decoration: const InputDecoration(
                  labelText: 'Descrizione pagamento',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci una descrizione';
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
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    isSubmitting
                        ? 'Pagamento in corso...'
                        : 'Conferma pagamento',
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

class _PaymentSummaryCard extends StatelessWidget {
  final String paymentTypeLabel;
  final String accountName;
  final String accountIban;
  final String provider;
  final String code;
  final String description;
  final double amount;
  final String Function(num) formatCurrency;
  final _PaymentPalette palette;

  const _PaymentSummaryCard({
    required this.paymentTypeLabel,
    required this.accountName,
    required this.accountIban,
    required this.provider,
    required this.code,
    required this.description,
    required this.amount,
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
              'Riepilogo operazione',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Controlla i dati prima di confermare il pagamento.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            _SummaryItem(label: 'Metodo', value: paymentTypeLabel),
            const SizedBox(height: 12),
            _SummaryItem(label: 'Conto di addebito', value: accountName),
            const SizedBox(height: 12),
            _SummaryItem(label: 'IBAN conto', value: accountIban),
            const SizedBox(height: 12),
            _SummaryItem(label: 'Ente / fornitore', value: provider),
            const SizedBox(height: 12),
            _SummaryItem(label: 'Codice', value: code),
            const SizedBox(height: 12),
            _SummaryItem(label: 'Descrizione', value: description),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.softBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: palette.softBorder.withOpacity(0.45),
                ),
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

class _PaymentsLoadingState extends StatelessWidget {
  const _PaymentsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LoadingBox(height: 180),
        SizedBox(height: 20),
        _LoadingBox(height: 170),
        SizedBox(height: 20),
        _LoadingBox(height: 170),
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

class _PaymentsEmptyState extends StatelessWidget {
  const _PaymentsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
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
              'Per effettuare un pagamento è necessario avere almeno un conto operativo disponibile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}