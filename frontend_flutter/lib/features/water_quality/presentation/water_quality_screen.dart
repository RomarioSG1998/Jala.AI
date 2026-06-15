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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
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
                          const Divider(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildMetricCard(context, 'pH', record.ph.toStringAsFixed(1), phColor, Icons.science),
                              _buildMetricCard(context, 'Temp', '${record.temperature.toStringAsFixed(1)}°C', Colors.blue, Icons.thermostat),
                              _buildMetricCard(context, 'Oxigênio', '${record.dissolvedOxygen.toStringAsFixed(1)} mg/L', Colors.lightBlue, Icons.bubble_chart),
                              if (record.ammonia != null)
                                _buildMetricCard(context, 'Amônia', '${record.ammonia!.toStringAsFixed(2)} mg/L', Colors.teal, Icons.opacity),
                              if (record.nitrite != null)
                                _buildMetricCard(context, 'Nitrito', '${record.nitrite!.toStringAsFixed(2)} mg/L', Colors.indigo, Icons.biotech),
                              if (record.alkalinity != null)
                                _buildMetricCard(context, 'Alcalinidade', '${record.alkalinity!.toStringAsFixed(1)} mg/L', Colors.deepOrange, Icons.gradient),
                              if (record.hardness != null)
                                _buildMetricCard(context, 'Dureza', '${record.hardness!.toStringAsFixed(1)} mg/L', Colors.purple, Icons.layers),
                              if (record.solids != null)
                                _buildMetricCard(context, 'Sólidos', '${record.solids!.toStringAsFixed(1)} mg/L', Colors.brown, Icons.grain),
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

  Widget _buildMetricCard(BuildContext context, String label, String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
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
  final _ammoniaController = TextEditingController();
  final _nitriteController = TextEditingController();
  final _alkalinityController = TextEditingController();
  final _hardnessController = TextEditingController();
  final _solidsController = TextEditingController();
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
    _ammoniaController.dispose();
    _nitriteController.dispose();
    _alkalinityController.dispose();
    _hardnessController.dispose();
    _solidsController.dispose();
    super.dispose();
  }

  double? _parseOptionalDouble(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
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
          ammonia: _parseOptionalDouble(_ammoniaController),
          nitrite: _parseOptionalDouble(_nitriteController),
          alkalinity: _parseOptionalDouble(_alkalinityController),
          hardness: _parseOptionalDouble(_hardnessController),
          solids: _parseOptionalDouble(_solidsController),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kit de Análise de Água',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF003366),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 20),
                Text(
                  'Parâmetros Básicos',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade300 : const Color(0xFF003366)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phController,
                        decoration: const InputDecoration(labelText: 'pH', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Inválido' : null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tempController,
                        decoration: const InputDecoration(labelText: 'Temp (°C)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Inválido' : null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _oxygenController,
                  decoration: const InputDecoration(labelText: 'Oxigênio Dissolvido (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Inválido' : null),
                ),
                const SizedBox(height: 20),
                Text(
                  'Parâmetros Químicos (Opcionais)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade300 : const Color(0xFF003366)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ammoniaController,
                        decoration: const InputDecoration(labelText: 'Amônia (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nitriteController,
                        decoration: const InputDecoration(labelText: 'Nitrito (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _alkalinityController,
                        decoration: const InputDecoration(labelText: 'Alcalinidade (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _hardnessController,
                        decoration: const InputDecoration(labelText: 'Dureza Total (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _solidsController,
                  decoration: const InputDecoration(labelText: 'Sólidos (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
  late final TextEditingController _ammoniaController;
  late final TextEditingController _nitriteController;
  late final TextEditingController _alkalinityController;
  late final TextEditingController _hardnessController;
  late final TextEditingController _solidsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phController = TextEditingController(text: widget.record.ph.toString());
    _tempController = TextEditingController(text: widget.record.temperature.toString());
    _oxygenController = TextEditingController(text: widget.record.dissolvedOxygen.toString());
    _ammoniaController = TextEditingController(text: widget.record.ammonia?.toString() ?? '');
    _nitriteController = TextEditingController(text: widget.record.nitrite?.toString() ?? '');
    _alkalinityController = TextEditingController(text: widget.record.alkalinity?.toString() ?? '');
    _hardnessController = TextEditingController(text: widget.record.hardness?.toString() ?? '');
    _solidsController = TextEditingController(text: widget.record.solids?.toString() ?? '');
  }

  @override
  void dispose() {
    _phController.dispose();
    _tempController.dispose();
    _oxygenController.dispose();
    _ammoniaController.dispose();
    _nitriteController.dispose();
    _alkalinityController.dispose();
    _hardnessController.dispose();
    _solidsController.dispose();
    super.dispose();
  }

  double? _parseOptionalDouble(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
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
          ammonia: _parseOptionalDouble(_ammoniaController),
          nitrite: _parseOptionalDouble(_nitriteController),
          alkalinity: _parseOptionalDouble(_alkalinityController),
          hardness: _parseOptionalDouble(_hardnessController),
          solids: _parseOptionalDouble(_solidsController),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Editar Kit de Análise',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF003366),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Parâmetros Básicos',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade300 : const Color(0xFF003366)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phController,
                        decoration: const InputDecoration(labelText: 'pH', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Inválido' : null),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tempController,
                        decoration: const InputDecoration(labelText: 'Temp (°C)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Inválido' : null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _oxygenController,
                  decoration: const InputDecoration(labelText: 'Oxigênio Dissolvido (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : (double.tryParse(v) == null ? 'Inválido' : null),
                ),
                const SizedBox(height: 20),
                Text(
                  'Parâmetros Químicos (Opcionais)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue.shade300 : const Color(0xFF003366)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ammoniaController,
                        decoration: const InputDecoration(labelText: 'Amônia (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nitriteController,
                        decoration: const InputDecoration(labelText: 'Nitrito (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _alkalinityController,
                        decoration: const InputDecoration(labelText: 'Alcalinidade (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _hardnessController,
                        decoration: const InputDecoration(labelText: 'Dureza Total (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _solidsController,
                  decoration: const InputDecoration(labelText: 'Sólidos (mg/L)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => v!.isNotEmpty && double.tryParse(v) == null ? 'Inválido' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
