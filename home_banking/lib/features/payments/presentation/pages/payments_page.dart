import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:home_banking/features/auth/presentation/bloc/auth_state.dart';
import 'package:home_banking/features/payments/data/repositories/payments_repository.dart';
import 'package:home_banking/features/payments/presentation/bloc/payments_bloc.dart';
import 'package:home_banking/features/payments/presentation/bloc/payments_event.dart';
import 'package:home_banking/features/payments/presentation/bloc/payments_state.dart';
import 'package:home_banking/shared/widgets/app_scaffold.dart';

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

  String? _selectedAccountId;
  String _selectedPaymentType = 'bollettino';

  @override
  void dispose() {
    _providerController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
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
            amount: double.tryParse(
                  _amountController.text.trim().replaceAll(',', '.'),
                ) ??
                0,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
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

            _providerController.clear();
            _codeController.clear();
            _descriptionController.clear();
            _amountController.clear();

            setState(() {
              _selectedPaymentType = 'bollettino';
            });
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Effettua un pagamento',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleziona la modalità di pagamento e completa i dati dell’avviso o del bollettino.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                Text(
                  'Metodo di pagamento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

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
                    ),
                    _PaymentTypeCard(
                      title: 'PagoPA',
                      subtitle: 'Avviso verso ente pubblico o comune',
                      icon: Icons.account_balance_outlined,
                      isSelected: _selectedPaymentType == 'pagopa',
                      onTap: () => _applyPaymentPreset('pagopa'),
                    ),
                    _PaymentTypeCard(
                      title: 'QR / Barcode',
                      subtitle: 'Simulazione scansione codice pagamento',
                      icon: Icons.qr_code_scanner_outlined,
                      isSelected: _selectedPaymentType == 'barcode',
                      onTap: () => _applyPaymentPreset('barcode'),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Text(
                  'Conto di addebito',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: state.accounts.map((account) {
                    final isSelected = account.id == _selectedAccountId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAccountId = account.id;
                        });
                      },
                      child: SizedBox(
                        width: 320,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(account.iban),
                                const SizedBox(height: 12),
                                Text(
                                  'Saldo: € ${account.balance.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.08),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tipo selezionato: ${_paymentTypeLabel(_selectedPaymentType)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _providerController,
                            decoration: InputDecoration(
                              labelText:
                                  _providerFieldLabel(_selectedPaymentType),
                              prefixIcon:
                                  const Icon(Icons.business_outlined),
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
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText:
                                  _codeFieldLabel(_selectedPaymentType),
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
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descrizione pagamento',
                              prefixIcon:
                                  Icon(Icons.description_outlined),
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
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
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
                              onPressed: state.isSubmitting ? null : _submit,
                              icon: state.isSubmitting
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
                                state.isSubmitting
                                    ? 'Pagamento in corso...'
                                    : 'Conferma pagamento',
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _PaymentTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 280,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}