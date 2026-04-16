import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  String? _selectedAccountId;
  String _selectedTransferType = 'ordinary';

  @override
  void dispose() {
    _beneficiaryNameController.dispose();
    _beneficiaryIbanController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
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

            _beneficiaryNameController.clear();
            _beneficiaryIbanController.clear();
            _descriptionController.clear();
            _amountController.clear();

            setState(() {
              _selectedTransferType = 'ordinary';
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
                  'Effettua un bonifico',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleziona il conto operativo, compila i dati e conferma l’operazione.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                Text(
                  'Conto di partenza',
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
                            selected: {_selectedTransferType},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _selectedTransferType = selection.first;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _beneficiaryNameController,
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
                            controller: _beneficiaryIbanController,
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
                            controller: _descriptionController,
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
                                  : const Icon(Icons.send_outlined),
                              label: Text(
                                state.isSubmitting
                                    ? 'Invio in corso...'
                                    : 'Conferma bonifico',
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