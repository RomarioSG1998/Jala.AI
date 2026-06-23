import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/finances/providers/transaction_provider.dart';
import 'package:frontend_flutter/features/finances/data/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

class FinancesScreen extends ConsumerWidget {
  const FinancesScreen({super.key});

  static const _kNavyBlue = Color(0xFF003366);
  static const _kGreen = Color(0xFF13A538);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionProvider);
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final searchQuery = ref.watch(globalSearchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Finanças', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionProvider.notifier).refreshTransactions(),
        child: transactionsAsync.when(
          data: (transactions) {
            final filtered = transactions.where((tx) {
              if (searchQuery.isEmpty) return true;
              final query = searchQuery.toLowerCase();
              final typeMatch = tx.type.toLowerCase().contains(query);
              final typePtMatch = (tx.type.toLowerCase() == 'income' ? 'receita' : 'despesa').contains(query);
              final amountMatch = tx.amount.toString().contains(query);
              final amountFormattedMatch = currencyFmt.format(tx.amount).toLowerCase().contains(query);
              return typeMatch || typePtMatch || amountMatch || amountFormattedMatch;
            }).toList();

            double totalIncome = 0;
            double totalExpense = 0;

            for (final tx in filtered) {
              if (tx.type.toLowerCase() == 'income') {
                totalIncome += tx.amount;
              } else {
                totalExpense += tx.amount;
              }
            }

            final netBalance = totalIncome - totalExpense;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                // Summary Cards
                _buildSummaryCards(context, totalIncome, totalExpense, netBalance, currencyFmt),
                const SizedBox(height: 28),
                Text(
                  'Transações Recentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  _buildEmptyState(context, message: searchQuery.isNotEmpty ? 'Nenhuma transação encontrada para "$searchQuery"' : 'Nenhuma transação registrada')
                else
                  Column(
                    children: filtered
                        .map((tx) => _buildTransactionItem(context, ref, tx, currencyFmt))
                        .toList(),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Erro ao carregar finanças: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildSummaryCards(BuildContext context, double income, double expense, double balance, NumberFormat fmt) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kNavyBlue, Color(0xFF004488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Saldo Líquido / Lucro Estimado', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                fmt.format(balance),
                style: TextStyle(
                  color: balance >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniCard(context, 'Receita / Entrada', fmt.format(income), Icons.arrow_upward, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniCard(context, 'Despesas', fmt.format(expense), Icons.arrow_downward, Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, WidgetRef ref, FinancialTransaction tx, NumberFormat fmt) {
    final isIncome = tx.type.toLowerCase() == 'income';
    final date = DateTime.tryParse(tx.transactionDate) ?? DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(date);

    final categoryText = tx.category != null && tx.category!.isNotEmpty
        ? tx.category!
        : (isIncome ? 'Receita / Entrada' : 'Despesa');

    final details = <String>[];
    if (isIncome) {
      if (tx.clientName != null && tx.clientName!.isNotEmpty) {
        details.add('Cli: ${tx.clientName}');
      }
      if (tx.fishSpecies != null && tx.fishSpecies!.isNotEmpty) {
        final qtyStr = tx.quantityKg != null ? '${tx.quantityKg}kg ' : '';
        details.add('$qtyStr${tx.fishSpecies}');
      }
    }
    final detailsText = details.isNotEmpty ? details.join(' • ') : '';

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await PasswordConfirmationDialog.confirm(context, ref);
      },
      onDismissed: (_) {
        ref.read(transactionProvider.notifier).deleteTransaction(tx.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação excluída')),
        );
      },
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: _EditTransactionForm(transaction: tx),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isIncome ? Colors.green.shade50 : Colors.red.shade50,
                radius: 20,
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryText,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                    ),
                    if (detailsText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detailsText,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                isIncome ? '+ ${fmt.format(tx.amount)}' : '- ${fmt.format(tx.amount)}',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String message = 'Nenhuma transação registrada'}) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (message == 'Nenhuma transação registrada') ...[
            const SizedBox(height: 4),
            const Text(
              'Adicione uma nova transação financeira clicando no botão +',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static void showAddTransactionModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _AddTransactionForm(),
      ),
    );
  }
}

class _AddTransactionForm extends ConsumerStatefulWidget {
  const _AddTransactionForm();

  @override
  ConsumerState<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends ConsumerState<_AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _customSpeciesController = TextEditingController();
  
  String _selectedType = 'Income';
  String? _selectedCategory;
  String? _selectedSpecies;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _incomeCategories = [
    'Venda de Alevino',
    'Venda de Tilápia',
    'Venda de Tambaqui',
    'Venda de Pacu',
    'Outros'
  ];

  final List<String> _expenseCategories = [
    'Compra de Alevinos',
    'Gastos com ração',
    'Energia',
    'Mão de obra',
    'Medicamentos',
    'Combustível',
    'Outros'
  ];

  final List<String> _fishSpeciesList = [
    'Tilápia',
    'Tambaqui',
    'Arapaima (Pirarucu)',
    'Pacu',
    'Pintado',
    'Outra'
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _clientNameController.dispose();
    _quantityController.dispose();
    _customCategoryController.dispose();
    _customSpeciesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    
    String? category = _selectedCategory;
    if (category == 'Outros') {
      category = _customCategoryController.text.trim();
    }

    String? species = _selectedSpecies;
    if (species == 'Outra') {
      species = _customSpeciesController.text.trim();
    }

    final clientName = _selectedType == 'Income' ? _clientNameController.text.trim() : null;
    final quantity = _selectedType == 'Income' ? double.tryParse(_quantityController.text.trim()) : null;

    final success = await ref.read(transactionProvider.notifier).createTransaction(
          type: _selectedType,
          amount: amount,
          category: category == null || category.isEmpty ? null : category,
          clientName: clientName == null || clientName.isEmpty ? null : clientName,
          fishSpecies: species == null || species.isEmpty ? null : species,
          quantityKg: quantity,
          transactionDate: _selectedDate.toIso8601String(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao adicionar transação')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _selectedType == 'Income';
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nova Transação',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Transação',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Income', child: Text('Receita (Entrada)')),
                  DropdownMenuItem(value: 'Expense', child: Text('Despesa (Saída)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      _selectedCategory = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedCategory = val);
                },
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              if (_selectedCategory == 'Outros') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Digite a Categoria Personalizada',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  if (double.tryParse(v) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (isIncome) ...[
                const Divider(height: 32, thickness: 1),
                Text(
                  'Detalhes da Venda',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Comprador / Cliente (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  decoration: const InputDecoration(
                    labelText: 'Espécie do Peixe (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _fishSpeciesList
                      .map((sp) => DropdownMenuItem(value: sp, child: Text(sp)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedSpecies = val);
                  },
                ),
                if (_selectedSpecies == 'Outra') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customSpeciesController,
                    decoration: const InputDecoration(
                      labelText: 'Digite a Espécie',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  ),
                ],
                const SizedBox(height: 16),

                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade Vendida (kg) (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                      return 'Valor inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              const Divider(height: 32, thickness: 1),
              
              InkWell(
                onTap: () => _selectDateTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data e Hora da Transação',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateStr, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13A538),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
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

class _EditTransactionForm extends ConsumerStatefulWidget {
  final FinancialTransaction transaction;
  const _EditTransactionForm({required this.transaction});

  @override
  ConsumerState<_EditTransactionForm> createState() => _EditTransactionFormState();
}

class _EditTransactionFormState extends ConsumerState<_EditTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _clientNameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _customSpeciesController;
  late String _selectedType;
  String? _selectedCategory;
  String? _selectedSpecies;
  late DateTime _selectedDate;
  bool _isLoading = false;

  final List<String> _incomeCategories = [
    'Venda de Alevino',
    'Venda de Tilápia',
    'Venda de Tambaqui',
    'Venda de Pacu',
    'Outros'
  ];

  final List<String> _expenseCategories = [
    'Compra de Alevinos',
    'Gastos com ração',
    'Energia',
    'Mão de obra',
    'Medicamentos',
    'Combustível',
    'Outros'
  ];

  final List<String> _fishSpeciesList = [
    'Tilápia',
    'Tambaqui',
    'Arapaima (Pirarucu)',
    'Pacu',
    'Pintado',
    'Outra'
  ];

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _amountController = TextEditingController(text: tx.amount.toString());
    _selectedType = tx.type;
    _clientNameController = TextEditingController(text: tx.clientName ?? '');
    _quantityController = TextEditingController(text: tx.quantityKg?.toString() ?? '');
    
    final categories = _selectedType == 'Income' ? _incomeCategories : _expenseCategories;
    if (tx.category != null && tx.category!.isNotEmpty) {
      if (categories.contains(tx.category)) {
        _selectedCategory = tx.category;
        _customCategoryController = TextEditingController();
      } else {
        _selectedCategory = 'Outros';
        _customCategoryController = TextEditingController(text: tx.category);
      }
    } else {
      _selectedCategory = null;
      _customCategoryController = TextEditingController();
    }

    if (tx.fishSpecies != null && tx.fishSpecies!.isNotEmpty) {
      if (_fishSpeciesList.contains(tx.fishSpecies)) {
        _selectedSpecies = tx.fishSpecies;
        _customSpeciesController = TextEditingController();
      } else {
        _selectedSpecies = 'Outra';
        _customSpeciesController = TextEditingController(text: tx.fishSpecies);
      }
    } else {
      _selectedSpecies = null;
      _customSpeciesController = TextEditingController();
    }

    _selectedDate = DateTime.tryParse(tx.transactionDate) ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _clientNameController.dispose();
    _quantityController.dispose();
    _customCategoryController.dispose();
    _customSpeciesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    
    String? category = _selectedCategory;
    if (category == 'Outros') {
      category = _customCategoryController.text.trim();
    }

    String? species = _selectedSpecies;
    if (species == 'Outra') {
      species = _customSpeciesController.text.trim();
    }

    final clientName = _selectedType == 'Income' ? _clientNameController.text.trim() : null;
    final quantity = _selectedType == 'Income' ? double.tryParse(_quantityController.text.trim()) : null;

    final success = await ref.read(transactionProvider.notifier).updateTransaction(
          id: widget.transaction.id,
          type: _selectedType,
          amount: amount,
          category: category == null || category.isEmpty ? null : category,
          clientName: clientName == null || clientName.isEmpty ? null : clientName,
          fishSpecies: species == null || species.isEmpty ? null : species,
          quantityKg: quantity,
          transactionDate: _selectedDate.toIso8601String(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao atualizar transação')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _selectedType == 'Income';
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Editar Transação',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Transação',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Income', child: Text('Receita (Entrada)')),
                  DropdownMenuItem(value: 'Expense', child: Text('Despesa (Saída)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      _selectedCategory = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedCategory = val);
                },
                validator: (v) => v == null ? 'Obrigatório' : null,
              ),
              if (_selectedCategory == 'Outros') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Digite a Categoria Personalizada',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                ),
              ],
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Obrigatório';
                  if (double.tryParse(v) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (isIncome) ...[
                const Divider(height: 32, thickness: 1),
                Text(
                  'Detalhes da Venda',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Comprador / Cliente (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  decoration: const InputDecoration(
                    labelText: 'Espécie do Peixe (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _fishSpeciesList
                      .map((sp) => DropdownMenuItem(value: sp, child: Text(sp)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedSpecies = val);
                  },
                ),
                if (_selectedSpecies == 'Outra') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customSpeciesController,
                    decoration: const InputDecoration(
                      labelText: 'Digite a Espécie',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
                  ),
                ],
                const SizedBox(height: 16),

                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade Vendida (kg) (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                      return 'Valor inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              const Divider(height: 32, thickness: 1),
              
              InkWell(
                onTap: () => _selectDateTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data e Hora da Transação',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(dateStr, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13A538),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
