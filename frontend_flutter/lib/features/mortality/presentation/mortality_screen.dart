import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/mortality/data/mortality_model.dart';
import 'package:frontend_flutter/features/mortality/providers/mortality_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

const Color _kNavyBlue = Color(0xFF003366);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kRed = Color(0xFFC62828);

class MortalityScreen extends ConsumerWidget {
  const MortalityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(mortalityProvider);
    final tanksAsync = ref.watch(tanksProvider);
    final searchQuery = ref.watch(globalSearchQueryProvider);

    final tankMap = tanksAsync.maybeWhen(
      data: (list) => {for (var t in list) t.id: t.name},
      orElse: () => <String, String>{},
    );

    final tankCapacityMap = tanksAsync.maybeWhen(
      data: (list) => {for (var t in list) t.id: t.fishCapacity},
      orElse: () => <String, int>{},
    );

    final timeFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Registro de Mortalidade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(mortalityProvider.notifier).refreshRecords(),
        child: recordsAsync.when(
          data: (records) {
            final filtered = records.where((record) {
              if (searchQuery.isEmpty) return true;
              final tankName = (tankMap[record.tankId] ?? '').toLowerCase();
              final cause = (record.cause ?? '').toLowerCase();
              final query = searchQuery.toLowerCase();
              return tankName.contains(query) || cause.contains(query);
            }).toList();

            // Stats calculations for premium look
            int totalDeaths = 0;
            final Map<String, int> causeCounts = {};
            for (var r in filtered) {
              totalDeaths += r.quantity;
              final cause = r.cause ?? 'Desconhecida';
              causeCounts[cause] = (causeCounts[cause] ?? 0) + r.quantity;
            }

            String topCause = 'Nenhuma';
            int maxCauseCount = 0;
            causeCounts.forEach((cause, count) {
              if (count > maxCauseCount) {
                maxCauseCount = count;
                topCause = cause;
              }
            });

            if (filtered.isEmpty) {
              return searchQuery.isNotEmpty
                  ? _buildEmptyState(context, message: 'Nenhuma mortalidade encontrada para "$searchQuery"')
                  : _buildEmptyState(context);
            }

            // Show newest records first
            final sortedRecords = List.from(filtered)
              ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

            return Column(
              children: [
                _buildStatsHeader(context, totalDeaths, topCause, maxCauseCount),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    itemCount: sortedRecords.length,
                    itemBuilder: (context, index) {
                      final record = sortedRecords[index];
                      final tankName = tankMap[record.tankId] ?? 'Tanque Desconhecido';
                      final initialCapacity = tankCapacityMap[record.tankId] ?? 0;
                      
                      // Calculate mortality rate for this single event or context
                      final rateStr = initialCapacity > 0
                          ? '${((record.quantity / initialCapacity) * 100).toStringAsFixed(1)}%'
                          : '--';

                      DateTime? timeParsed;
                      try {
                        timeParsed = DateTime.parse(record.recordDate);
                      } catch (_) {}
                      final formattedTime = timeParsed != null
                          ? timeFmt.format(timeParsed)
                          : record.recordDate;

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
                              .read(mortalityProvider.notifier)
                              .deleteRecord(record.id);
                          if (context.mounted) {
                            if (err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao excluir registro: $err'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              ref.read(mortalityProvider.notifier).refreshRecords();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Registro de mortalidade removido com sucesso.'),
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
                            border: Theme.of(context).brightness == Brightness.dark
                                ? Border.all(color: const Color(0xFF263350), width: 1)
                                : null,
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
                              backgroundColor: _kRed.withOpacity(0.1),
                              child: const Icon(Icons.warning_amber_rounded, color: _kRed),
                            ),
                            title: Text(
                              tankName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.group, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Quantidade: ',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '${record.quantity} peixes',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.analytics_outlined, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Taxa: ',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      rateStr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: _kRed,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.help_outline, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Causa: ',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        record.cause ?? 'Não informada',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                              onPressed: () => _showEditModal(context, ref, record),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Erro ao carregar registros: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddModal(context, ref),
        label: const Text('Registrar Morte', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: _kNavyBlue,
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, int totalDeaths, String topCause, int topCauseCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF263350)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total de Perdas',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalDeaths peixes',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kRed,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? const Color(0xFF263350) : Colors.grey.shade200,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Causa Principal',
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  topCause,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String message = 'Nenhum registro de mortalidade cadastrado.'}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 72,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static void showAddMortalityModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddMortalityRecordForm(),
    );
  }

  void _showAddModal(BuildContext context, WidgetRef ref) {
    showAddMortalityModal(context, ref);
  }

  void _showEditModal(BuildContext context, WidgetRef ref, MortalityRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditMortalityRecordForm(record: record),
    );
  }
}

class _AddMortalityRecordForm extends ConsumerStatefulWidget {
  const _AddMortalityRecordForm();

  @override
  ConsumerState<_AddMortalityRecordForm> createState() => _AddMortalityRecordFormState();
}

class _AddMortalityRecordFormState extends ConsumerState<_AddMortalityRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _customCauseController = TextEditingController();
  
  String? _selectedTankId;
  String _selectedCause = 'Falta de Oxigênio';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _causes = [
    'Falta de Oxigênio',
    'Variação de Temperatura',
    'PH inadequado',
    'Predador',
    'Doença/Parasita',
    'Desconhecida',
    'Outro',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    _customCauseController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate != null) {
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

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);
    final tanks = tanksAsync.maybeWhen(
      data: (list) => list.where((t) => t.status == 'ACTIVE').toList(),
      orElse: () => [],
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: Color(0xFF263350), width: 1.5)) : null,
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Registrar Mortalidade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : _kNavyBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tank Dropdown
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
                    child: Text('${t.name} (${t.fishCapacity - t.mortalityCount} peixes)'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTankId = val),
                validator: (val) => val == null ? 'Selecione o tanque' : null,
              ),
              const SizedBox(height: 16),

              // Quantity Input
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantidade de Peixes Mortos',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.group),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Digite a quantidade';
                  final numVal = int.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'Digite um número inteiro maior que zero';
                  if (_selectedTankId != null) {
                    final selectedTank = tanks.firstWhere((t) => t.id == _selectedTankId);
                    final currentStock = selectedTank.fishCapacity - selectedTank.mortalityCount;
                    if (numVal > currentStock) {
                      return 'Quantidade maior que o estoque atual ($currentStock)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cause Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Causa Provável',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.help_outline),
                ),
                value: _selectedCause,
                items: _causes.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCause = val ?? 'Falta de Oxigênio'),
              ),
              const SizedBox(height: 16),

              // Custom Cause text field (visible if "Outro" is selected)
              if (_selectedCause == 'Outro') ...[
                TextFormField(
                  controller: _customCauseController,
                  decoration: InputDecoration(
                    labelText: 'Especifique a Causa',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.edit_note),
                  ),
                  validator: (val) {
                    if (_selectedCause == 'Outro' && (val == null || val.trim().isEmpty)) {
                      return 'Descreva a causa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Date/Time Selection
              InkWell(
                onTap: () => _selectDateTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Data/Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Text(
                        'Alterar',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                          : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final causeText = _selectedCause == 'Outro' ? _customCauseController.text : _selectedCause;

    final err = await ref.read(mortalityProvider.notifier).createRecord(
          _selectedTankId!,
          int.parse(_quantityController.text),
          causeText,
          recordDate: _selectedDate.toIso8601String(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $err'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mortalidade registrada com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }
}

class _EditMortalityRecordForm extends ConsumerStatefulWidget {
  final MortalityRecord record;
  const _EditMortalityRecordForm({required this.record});

  @override
  ConsumerState<_EditMortalityRecordForm> createState() => _EditMortalityRecordFormState();
}

class _EditMortalityRecordFormState extends ConsumerState<_EditMortalityRecordForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _customCauseController;
  
  String? _selectedTankId;
  String _selectedCause = 'Falta de Oxigênio';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _causes = [
    'Falta de Oxigênio',
    'Variação de Temperatura',
    'PH inadequado',
    'Predador',
    'Doença/Parasita',
    'Desconhecida',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.record.quantity.toString());
    _selectedTankId = widget.record.tankId;
    
    if (_causes.contains(widget.record.cause)) {
      _selectedCause = widget.record.cause!;
      _customCauseController = TextEditingController();
    } else {
      _selectedCause = 'Outro';
      _customCauseController = TextEditingController(text: widget.record.cause);
    }

    try {
      _selectedDate = DateTime.parse(widget.record.recordDate);
    } catch (_) {}
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customCauseController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate != null) {
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

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);
    final tanks = tanksAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: Color(0xFF263350), width: 1.5)) : null,
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Editar Registro de Mortalidade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : _kNavyBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tank Dropdown (Disabled during edit to ensure inventory/balance consistency)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Tanque',
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
                onChanged: null, // Disabled
              ),
              const SizedBox(height: 16),

              // Quantity Input
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantidade de Peixes Mortos',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.group),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Digite a quantidade';
                  final numVal = int.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'Digite um número inteiro maior que zero';
                  if (_selectedTankId != null) {
                    final selectedTank = tanks.firstWhere((t) => t.id == _selectedTankId);
                    // Stock check: allowed stock is (capacity - current mortalityCount + original mortality registered)
                    final currentStock = selectedTank.fishCapacity - selectedTank.mortalityCount;
                    final allowedMax = currentStock + widget.record.quantity;
                    if (numVal > allowedMax) {
                      return 'Quantidade maior que o limite máximo disponível ($allowedMax)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cause Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Causa Provável',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.help_outline),
                ),
                value: _selectedCause,
                items: _causes.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCause = val ?? 'Falta de Oxigênio'),
              ),
              const SizedBox(height: 16),

              // Custom Cause text field (visible if "Outro" is selected)
              if (_selectedCause == 'Outro') ...[
                TextFormField(
                  controller: _customCauseController,
                  decoration: InputDecoration(
                    labelText: 'Especifique a Causa',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.edit_note),
                  ),
                  validator: (val) {
                    if (_selectedCause == 'Outro' && (val == null || val.trim().isEmpty)) {
                      return 'Descreva a causa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Date/Time Selection
              InkWell(
                onTap: () => _selectDateTime(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Data/Hora: ${DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const Text(
                        'Alterar',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
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
                          : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final causeText = _selectedCause == 'Outro' ? _customCauseController.text : _selectedCause;

    final err = await ref.read(mortalityProvider.notifier).updateRecord(
          widget.record.id,
          _selectedTankId!,
          int.parse(_quantityController.text),
          causeText,
          recordDate: _selectedDate.toIso8601String(),
        );

    if (mounted) {
      setState(() => _isSaving = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $err'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro de mortalidade atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }
}
