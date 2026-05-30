import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/feeding_records/data/feeding_record_model.dart';
import 'package:frontend_flutter/features/feeding_records/providers/feeding_record_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/features/inventory/providers/inventory_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

const Color _kNavyBlue = Color(0xFF003366);
const Color _kGreen = Color(0xFF2E7D32);

class FeedingRecordsScreen extends ConsumerWidget {
  const FeedingRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(feedingRecordProvider);
    final tanksAsync = ref.watch(tanksProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    final searchQuery = ref.watch(globalSearchQueryProvider);

    final tankMap = tanksAsync.maybeWhen(
      data: (list) => {for (var t in list) t.id: t.name},
      orElse: () => <String, String>{},
    );

    final feedMap = inventoryAsync.maybeWhen(
      data: (list) => {for (var i in list) i.id: i.itemName},
      orElse: () => <String, String>{},
    );

    final feedUnitMap = inventoryAsync.maybeWhen(
      data: (list) => {for (var i in list) i.id: i.unit},
      orElse: () => <String, String>{},
    );

    final timeFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Registro de Alimentação',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedingRecordProvider.notifier).refreshRecords(),
        child: recordsAsync.when(
          data: (records) {
            final filtered = records.where((record) {
              if (searchQuery.isEmpty) return true;
              final tankName = (tankMap[record.tankId] ?? '').toLowerCase();
              final feedName = (feedMap[record.feedId] ?? '').toLowerCase();
              final query = searchQuery.toLowerCase();
              return tankName.contains(query) || feedName.contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return searchQuery.isNotEmpty
                  ? _buildEmptyState(context, message: 'Nenhum trato encontrado para "$searchQuery"')
                  : _buildEmptyState(context);
            }

            // Show newest records first
            final sortedRecords = List.from(filtered)
              ..sort((a, b) => b.feedingTime.compareTo(a.feedingTime));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: sortedRecords.length,
              itemBuilder: (context, index) {
                final record = sortedRecords[index];
                final tankName = tankMap[record.tankId] ?? 'Tanque Desconhecido';
                final feedName = feedMap[record.feedId] ?? 'Ração Desconhecida';
                final unit = feedUnitMap[record.feedId] ?? 'kg';

                DateTime? timeParsed;
                try {
                  timeParsed = DateTime.parse(record.feedingTime);
                } catch (_) {}
                final formattedTime = timeParsed != null
                    ? timeFmt.format(timeParsed)
                    : record.feedingTime;

                return Dismissible(
                  key: Key(record.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                   confirmDismiss: (_) async {
                    return await PasswordConfirmationDialog.confirm(context, ref);
                  },
                  onDismissed: (_) async {
                    final err = await ref
                        .read(feedingRecordProvider.notifier)
                        .deleteRecord(record.id);
                    if (context.mounted) {
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao excluir trato: $err'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        ref.read(feedingRecordProvider.notifier).refreshRecords();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Trato removido com sucesso.'),
                            backgroundColor: _kGreen,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.1),
                        child: const Icon(Icons.restaurant, color: Colors.purple),
                      ),
                      title: Text(
                        tankName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.rice_bowl_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$feedName: ${record.quantity} $unit',
                                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                  formattedTime,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: _EditFeedingRecordForm(record: record),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Erro ao carregar registros: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String message = 'Nenhum trato registrado'}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54),
              textAlign: TextAlign.center,
            ),
            if (message == 'Nenhum trato registrado') ...[
              const SizedBox(height: 8),
              const Text(
                'Clique no botão central "+" para registrar a alimentação diária de seus peixes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void showAddFeedingRecordModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddFeedingRecordForm(),
    );
  }
}

class _AddFeedingRecordForm extends ConsumerStatefulWidget {
  const _AddFeedingRecordForm();

  @override
  ConsumerState<_AddFeedingRecordForm> createState() => _AddFeedingRecordFormState();
}

class _AddFeedingRecordFormState extends ConsumerState<_AddFeedingRecordForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTankId;
  String? _selectedFeedId;
  final _quantityController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    final tanks = tanksAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const [],
    );

    // Filter inventory to only show Feed items
    final feeds = inventoryAsync.maybeWhen(
      data: (list) => list.where((item) => item.type.toLowerCase() == 'feed').toList(),
      orElse: () => const [],
    );

    final selectedFeed = _selectedFeedId != null
        ? feeds.firstWhere((f) => f.id == _selectedFeedId)
        : null;

    final unit = selectedFeed?.unit ?? 'kg';
    final availableQuantity = selectedFeed?.quantity ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                    'Registrar Trato / Alimentação',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kNavyBlue),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
  
              // Dropdown Tanque
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Selecione o Tanque',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.water),
                ),
                value: _selectedTankId,
                items: tanks.map((t) {
                  return DropdownMenuItem<String>(
                    value: t.id,
                    child: Text(t.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTankId = val),
                validator: (val) => val == null ? 'Selecione o tanque' : null,
              ),
              const SizedBox(height: 16),
  
              // Dropdown Ração
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Selecione a Ração',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.rice_bowl),
                ),
                value: _selectedFeedId,
                items: feeds.map((f) {
                  return DropdownMenuItem<String>(
                    value: f.id,
                    child: Text('${f.itemName} (Disp: ${f.quantity} ${f.unit})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() {
                  _selectedFeedId = val;
                }),
                validator: (val) => val == null ? 'Selecione a ração' : null,
              ),
              const SizedBox(height: 16),
  
              // Quantidade
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantidade',
                  suffixText: unit,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.scale),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Digite a quantidade';
                  final numVal = double.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'Digite um número maior que zero';
                  if (numVal > availableQuantity) {
                    return 'Quantidade maior que o disponível em estoque ($availableQuantity $unit)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
  
              // Botão Salvar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavyBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveForm,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Registrar Trato', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final err = await ref.read(feedingRecordProvider.notifier).createRecord(
          _selectedTankId!,
          _selectedFeedId!,
          double.parse(_quantityController.text),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $err'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trato registrado com sucesso!'), backgroundColor: _kGreen),
        );
        Navigator.pop(context);
      }
    }
  }
}

class _EditFeedingRecordForm extends ConsumerStatefulWidget {
  final FeedingRecord record;
  const _EditFeedingRecordForm({required this.record});

  @override
  ConsumerState<_EditFeedingRecordForm> createState() => _EditFeedingRecordFormState();
}

class _EditFeedingRecordFormState extends ConsumerState<_EditFeedingRecordForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  String? _selectedTankId;
  String? _selectedFeedId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.record.quantity.toString());
    _selectedTankId = widget.record.tankId;
    _selectedFeedId = widget.record.feedId;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    final tanks = tanksAsync.value ?? [];
    final feeds = (inventoryAsync.value ?? []).where((i) => i.type.toLowerCase() == 'feed').toList();

    // Determine unit
    final selectedFeed = feeds.where((f) => f.id == _selectedFeedId).firstOrNull;
    final unit = selectedFeed?.unit ?? 'kg';
    final currentQuantity = selectedFeed?.quantity ?? 0.0;
    // Limit available quantity to current quantity + what was already registered in this record (so we don't block them if they decrease or slightly increase)
    final availableQuantity = currentQuantity + (widget.record.feedId == _selectedFeedId ? widget.record.quantity : 0.0);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
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
                    'Editar Trato / Alimentação',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
  
              // Dropdown Tanque
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Selecione o Tanque',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.water),
                ),
                value: _selectedTankId,
                items: tanks.map((t) {
                  return DropdownMenuItem<String>(
                    value: t.id,
                    child: Text(t.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTankId = val),
                validator: (val) => val == null ? 'Selecione o tanque' : null,
              ),
              const SizedBox(height: 16),
  
              // Dropdown Ração
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Selecione a Ração',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.rice_bowl),
                ),
                value: _selectedFeedId,
                items: feeds.map((f) {
                  final dispQty = f.quantity + (widget.record.feedId == f.id ? widget.record.quantity : 0.0);
                  return DropdownMenuItem<String>(
                    value: f.id,
                    child: Text('${f.itemName} (Disp: $dispQty ${f.unit})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() {
                  _selectedFeedId = val;
                }),
                validator: (val) => val == null ? 'Selecione a ração' : null,
              ),
              const SizedBox(height: 16),
  
              // Quantidade
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantidade',
                  suffixText: unit,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.scale),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Digite a quantidade';
                  final numVal = double.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'Digite um número maior que zero';
                  if (numVal > availableQuantity) {
                    return 'Quantidade maior que o disponível em estoque ($availableQuantity $unit)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
  
              // Botão Salvar
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveForm,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final err = await ref.read(feedingRecordProvider.notifier).updateRecord(
          widget.record.id,
          _selectedTankId!,
          _selectedFeedId!,
          double.parse(_quantityController.text),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $err'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trato atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }
}
