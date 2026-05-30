import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/water_quality/providers/water_quality_provider.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

class WaterQualityScreen extends ConsumerWidget {
  const WaterQualityScreen({super.key});

  static void showAddLogModal(BuildContext context, WidgetRef ref) {
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
        child: const AddWaterQualityForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wqAsyncValue = ref.watch(waterQualityProvider);
    final tanksAsync = ref.watch(tanksProvider);
    final tankMap = tanksAsync.maybeWhen(
      data: (list) => {for (var t in list) t.id: t.name},
      orElse: () => <String, String>{},
    );
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState.accountType == 'FARM_OWNER' || authState.accountType == 'CLIENT';

    final searchQuery = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: wqAsyncValue.when(
        data: (records) {
          final filtered = records.where((record) {
            if (searchQuery.isEmpty) return true;
            final tankName = (tankMap[record.tankId] ?? '').toLowerCase();
            final query = searchQuery.toLowerCase();
            final phMatch = record.ph.toString().contains(query);
            final tempMatch = record.temperature.toString().contains(query);
            final oxygenMatch = record.dissolvedOxygen.toString().contains(query);
            return tankName.contains(query) || phMatch || tempMatch || oxygenMatch;
          }).toList();

          if (filtered.isEmpty) {
            return searchQuery.isNotEmpty
                ? _buildEmptyState(context, message: 'Nenhum registro encontrado para "$searchQuery"')
                : _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(waterQualityProvider.notifier).refreshRecords(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final record = filtered[index];
                
                Color phColor = Colors.green;
                if (record.ph < 6.5 || record.ph > 8.5) {
                  phColor = Colors.red;
                } else if (record.ph < 7.0 || record.ph > 8.0) {
                  phColor = Colors.orange;
                }

                DateTime date = DateTime.parse(record.measurementTime);
                String formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(date);

                return Dismissible(
                  key: Key(record.id),
                  direction: isOwner ? DismissDirection.endToStart : DismissDirection.none,
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
                    return await PasswordConfirmationDialog.confirm(context, ref);
                  },
                  onDismissed: (direction) {
                    ref.read(waterQualityProvider.notifier).deleteRecord(record.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.transparent, width: 1.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tankMap[record.tankId] ?? 'Tanque Desconhecido',
                                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade300 : const Color(0xFF003366), fontSize: 16),
                              ),
                              Row(
                                children: [
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => showModalBottomSheet(
                                      context: context,
                                      useRootNavigator: true,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                      ),
                                      builder: (ctx) => Padding(
                                        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                                        child: EditWaterQualityForm(record: record),
                                      ),
                                    ),
                                    child: Icon(Icons.edit_outlined, size: 18, color: isDark ? Colors.blue.shade300 : const Color(0xFF003366)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetric(context, 'pH', record.ph.toStringAsFixed(1), phColor),
                              _buildMetric(context, 'Temp', '${record.temperature.toStringAsFixed(1)}°C', Colors.blue),
                              _buildMetric(context, 'Oxigênio', '${record.dissolvedOxygen.toStringAsFixed(1)} mg/L', Colors.lightBlue),
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
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Falha ao carregar registros:\n${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(waterQualityProvider.notifier).refreshRecords(),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.black54),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, {String message = 'Nenhum registro de qualidade da água encontrado.'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AddWaterQualityForm extends ConsumerStatefulWidget {
  const AddWaterQualityForm({super.key});

  @override
  ConsumerState<AddWaterQualityForm> createState() => _AddWaterQualityFormState();
}

class _AddWaterQualityFormState extends ConsumerState<AddWaterQualityForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTankId;
  final _phController = TextEditingController();
  final _tempController = TextEditingController();
  final _oxygenController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ref.read(tanksProvider.notifier).refreshTanks();
  }

  @override
  void dispose() {
    _phController.dispose();
    _tempController.dispose();
    _oxygenController.dispose();
    super.dispose();
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

    final success = await ref.read(waterQualityProvider.notifier).createRecord(
          _selectedTankId!,
          double.parse(_phController.text.trim()),
          double.parse(_tempController.text.trim()),
          double.parse(_oxygenController.text.trim()),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao salvar registro')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);

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
                'Registrar Qualidade da Água',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              tanksAsync.when(
                data: (tanks) {
                  if (tanks.isEmpty) return const Text('Nenhum tanque disponível. Crie um tanque primeiro.');
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Selecionar Tanque', border: OutlineInputBorder()),
                    value: _selectedTankId,
                    items: tanks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (val) => setState(() => _selectedTankId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Erro ao carregar tanques: $err'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phController,
                decoration: const InputDecoration(labelText: 'Nível de pH', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Número inválido' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tempController,
                decoration: const InputDecoration(labelText: 'Temperatura (°C)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Número inválido' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _oxygenController,
                decoration: const InputDecoration(labelText: 'Oxigênio Dissolvido (mg/L)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Número inválido' : null),
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
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Salvar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditWaterQualityForm extends ConsumerStatefulWidget {
  final dynamic record;
  const EditWaterQualityForm({super.key, required this.record});

  @override
  ConsumerState<EditWaterQualityForm> createState() => _EditWaterQualityFormState();
}

class _EditWaterQualityFormState extends ConsumerState<EditWaterQualityForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phController;
  late final TextEditingController _tempController;
  late final TextEditingController _oxygenController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phController = TextEditingController(text: widget.record.ph.toString());
    _tempController = TextEditingController(text: widget.record.temperature.toString());
    _oxygenController = TextEditingController(text: widget.record.dissolvedOxygen.toString());
  }

  @override
  void dispose() {
    _phController.dispose();
    _tempController.dispose();
    _oxygenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = await ref.read(waterQualityProvider.notifier).updateRecord(
          widget.record.id,
          widget.record.tankId,
          double.parse(_phController.text.trim()),
          double.parse(_tempController.text.trim()),
          double.parse(_oxygenController.text.trim()),
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro atualizado com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar registro.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Editar Qualidade da Água',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phController,
                decoration: const InputDecoration(labelText: 'Nível de pH', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Número inválido' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tempController,
                decoration: const InputDecoration(labelText: 'Temperatura (°C)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Número inválido' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _oxygenController,
                decoration: const InputDecoration(labelText: 'Oxigênio Dissolvido (mg/L)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Número inválido' : null),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
