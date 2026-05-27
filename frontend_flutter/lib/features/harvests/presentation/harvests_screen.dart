import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/harvests/data/harvest_model.dart';
import 'package:frontend_flutter/features/harvests/providers/harvest_provider.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:intl/intl.dart';

class HarvestsScreen extends ConsumerWidget {
  const HarvestsScreen({super.key});

  static void showLogHarvestModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const LogHarvestForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final harvestsAsync = ref.watch(harvestProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState.accountType == 'FARM_OWNER' || authState.accountType == 'CLIENT';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: harvestsAsync.when(
        data: (harvests) {
          if (harvests.isEmpty) return _buildEmptyState();
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(harvestProvider.notifier).refreshHarvests(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: harvests.length,
              itemBuilder: (context, index) {
                final harvest = harvests[index];

                // Parse and format the date
                DateTime date;
                try {
                  date = DateTime.parse(harvest.date);
                } catch (_) {
                  date = DateTime.now();
                }
                final formattedDate =
                    DateFormat('dd/MM/yyyy').format(date);

                return Dismissible(
                  key: Key(harvest.id),
                  direction: isOwner
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
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
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Excluir Registro de Despesca'),
                        content: Text(
                            'Deseja excluir a despesca de ${harvest.quantityKg} kg registrada em $formattedDate?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancelar')),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Excluir',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) {
                    ref
                        .read(harvestProvider.notifier)
                        .deleteHarvest(harvest.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        backgroundColor:
                            Colors.green.shade100,
                        radius: 26,
                        child: Icon(Icons.agriculture,
                            color: Colors.green.shade700, size: 26),
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: EditHarvestForm(harvest: harvest),
                          ),
                        );
                      },
                      title: Text(
                        '${harvest.quantityKg} kg',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.green.shade800),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(formattedDate,
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('Destino: ${harvest.destination}',
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Falha ao carregar despescas:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(harvestProvider.notifier).refreshHarvests(),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.agriculture, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Nenhuma despesca registrada ainda.',
              style:
                  TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          const Text('Clique no botão + para registrar sua primeira despesca.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Log Harvest Form ─────────────────────────────────────────────────────────

class LogHarvestForm extends ConsumerStatefulWidget {
  const LogHarvestForm({super.key});

  @override
  ConsumerState<LogHarvestForm> createState() => _LogHarvestFormState();
}

class _LogHarvestFormState extends ConsumerState<LogHarvestForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTankId;
  DateTime _selectedDate = DateTime.now();
  final _quantityController = TextEditingController();
  final _destinationController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ref.read(tanksProvider.notifier).refreshTanks();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedTankId == null) {
      if (_selectedTankId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione um tanque')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final success = await ref.read(harvestProvider.notifier).logHarvest(
          _selectedTankId!,
          dateStr,
          double.parse(_quantityController.text.trim()),
          _destinationController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao registrar despesca')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Registrar Despesca',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Tank Dropdown
              tanksAsync.when(
                data: (tanks) {
                  if (tanks.isEmpty) {
                    return const Text(
                        'Nenhum tanque disponível. Crie um tanque primeiro.');
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Selecionar Tanque',
                        border: OutlineInputBorder()),
                    value: _selectedTankId,
                    items: tanks
                        .map((t) => DropdownMenuItem(
                            value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedTankId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Erro ao carregar tanques: $err'),
              ),
              const SizedBox(height: 16),
              // Date Picker
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Data da Despesca',
                      hintText: formattedDate,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(text: formattedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                    labelText: 'Quantidade (kg)',
                    border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty
                    ? 'Obrigatório'
                    : (double.tryParse(v) == null ? 'Número inválido' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                    labelText: 'Destino (ex: Mercado Local)',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13A538),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Registrar Despesca'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditHarvestForm extends ConsumerStatefulWidget {
  final Harvest harvest;
  const EditHarvestForm({super.key, required this.harvest});

  @override
  ConsumerState<EditHarvestForm> createState() => _EditHarvestFormState();
}

class _EditHarvestFormState extends ConsumerState<EditHarvestForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyController;
  late final TextEditingController _destinationController;
  late DateTime _harvestDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.harvest.quantityKg.toString());
    _destinationController = TextEditingController(text: widget.harvest.destination);
    _harvestDate = DateTime.tryParse(widget.harvest.date) ?? DateTime.now();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _harvestDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_harvestDate);

    final success = await ref.read(harvestProvider.notifier).updateHarvest(
          widget.harvest.id,
          widget.harvest.tankId,
          dateStr,
          double.parse(_qtyController.text.trim()),
          _destinationController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao atualizar despesca')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(_harvestDate);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Editar Despesca',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(
                    labelText: 'Quantidade (kg)', border: OutlineInputBorder()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty
                    ? 'Obrigatório'
                    : (double.tryParse(v) == null ? 'Número inválido' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                    labelText: 'Destino',
                    hintText: 'ex: Mercado Local',
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data da Despesca',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller:
                        TextEditingController(text: formattedDate),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13A538),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Salvar Alterações'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
