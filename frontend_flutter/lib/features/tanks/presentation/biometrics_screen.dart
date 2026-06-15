import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/tanks/data/biometrics_model.dart';
import 'package:frontend_flutter/features/tanks/providers/biometrics_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/features/feeding_records/providers/feeding_record_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

const Color _kNavyBlue = Color(0xFF003366);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kTeal = Color(0xFF00796B);
const Color _kOrange = Color(0xFFE65100);

class BiometricsScreen extends ConsumerStatefulWidget {
  final String? initialTankId;
  const BiometricsScreen({super.key, this.initialTankId});

  static void showAddBiometricsModal(BuildContext context, String tankId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddBiometricsForm(tankId: tankId),
    );
  }

  @override
  ConsumerState<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends ConsumerState<BiometricsScreen> {
  String? _selectedTankId;

  @override
  void initState() {
    super.initState();
    _selectedTankId = widget.initialTankId;
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);
    final feedingAsync = ref.watch(feedingRecordProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Controle de Biometria',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: tanksAsync.when(
        data: (tanks) {
          final activeTanks = tanks.where((t) => t.status == 'ACTIVE').toList();

          if (activeTanks.isEmpty) {
            return _buildEmptyState(
              context,
              icon: Icons.water_outlined,
              message: 'Não há tanques ativos cadastrados no momento.',
            );
          }

          // If no tank selected or current selection is not in active list, select the first one
          if (_selectedTankId == null || !activeTanks.any((t) => t.id == _selectedTankId)) {
            _selectedTankId = activeTanks.first.id;
          }

          final selectedTank = activeTanks.firstWhere((t) => t.id == _selectedTankId);
          final biometricsAsync = ref.watch(biometricsProvider(_selectedTankId!));

          return Column(
            children: [
              // Tank Selector Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isDark ? const Color(0xFF151D30) : Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.water, color: _kNavyBlue),
                    const SizedBox(width: 12),
                    const Text(
                      'Tanque:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTankId,
                          items: activeTanks.map((t) {
                            return DropdownMenuItem(
                              value: t.id,
                              child: Text(
                                t.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTankId = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content (Dashboard + History)
              Expanded(
                child: biometricsAsync.when(
                  data: (records) {
                    final feedings = feedingAsync.maybeWhen(
                      data: (list) => list.where((f) => f.tankId == _selectedTankId).toList(),
                      orElse: () => [],
                    );

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(biometricsProvider(_selectedTankId!));
                        ref.read(feedingRecordProvider.notifier).refreshRecords();
                        ref.invalidate(tanksProvider);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                        children: [
                          // Statistics Cards
                          _buildBiometricsDashboard(context, selectedTank, records, feedings),
                          
                          const SizedBox(height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Histórico de Pesagens',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : _kNavyBlue,
                                ),
                              ),
                              Text(
                                '${records.length} registros',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (records.isEmpty)
                            _buildEmptyState(
                              context,
                              icon: Icons.monitor_weight_outlined,
                              message: 'Nenhum registro de biometria cadastrado para este tanque.',
                            )
                          else
                            ..._buildHistoryList(context, records),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text(
                      'Erro ao carregar biometrias: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Erro ao carregar tanques: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedTankId == null
            ? null
            : () => _showAddBiometricsModal(context, _selectedTankId!),
        label: const Text('Registrar Peso', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: _kNavyBlue,
      ),
    );
  }

  Widget _buildBiometricsDashboard(
    BuildContext context,
    dynamic tank,
    List<BiometricsRecord> records,
    List<dynamic> feedings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Current metrics
    final currentWeight = tank.averageWeightG;
    final currentStock = tank.fishCapacity - tank.mortalityCount;
    final estimatedBiomassKg = (currentStock * currentWeight) / 1000.0;

    // Weekly Growth calculation
    double weeklyGrowthG = 0.0;
    String weeklyGrowthStr = '--';
    if (records.length >= 2) {
      // Sort records by date to find the interval
      final sorted = List<BiometricsRecord>.from(records)
        ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
      
      final latest = sorted.last;
      final prev = sorted[sorted.length - 2];
      try {
        final dateLatest = DateTime.parse(latest.recordDate);
        final datePrev = DateTime.parse(prev.recordDate);
        final diffDays = dateLatest.difference(datePrev).inDays;
        if (diffDays > 0) {
          final diffWeight = latest.weightG - prev.weightG;
          weeklyGrowthG = (diffWeight / diffDays) * 7.0;
          weeklyGrowthStr = '${weeklyGrowthG.toStringAsFixed(1)}g / sem';
        }
      } catch (_) {}
    } else if (tank.stockingDate != null && tank.initialAverageWeightG != null) {
      try {
        final stocking = DateTime.parse(tank.stockingDate!);
        final diffDays = DateTime.now().difference(stocking).inDays;
        if (diffDays > 0) {
          final diffWeight = tank.averageWeightG - tank.initialAverageWeightG!;
          weeklyGrowthG = (diffWeight / diffDays) * 7.0;
          weeklyGrowthStr = '${weeklyGrowthG.toStringAsFixed(1)}g / sem';
        }
      } catch (_) {}
    }

    // FCR Calculation
    double totalFeedConsumedKg = feedings.fold(0.0, (sum, f) => sum + f.quantity);
    double initialBiomassKg = 0.0;
    if (tank.initialAverageWeightG != null && tank.initialStockingQty != null) {
      initialBiomassKg = (tank.initialStockingQty! * tank.initialAverageWeightG!) / 1000.0;
    } else {
      initialBiomassKg = (tank.fishCapacity * (tank.initialAverageWeightG ?? 0)) / 1000.0;
    }
    double weightGainKg = estimatedBiomassKg - initialBiomassKg;
    
    String fcrStr = '--';
    if (weightGainKg > 0 && totalFeedConsumedKg > 0) {
      final fcr = totalFeedConsumedKg / weightGainKg;
      fcrStr = fcr.toStringAsFixed(2);
    }

    return Column(
      children: [
        // Top overview row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Peso Médio',
                value: '$currentWeight g',
                icon: Icons.monitor_weight,
                color: _kTeal,
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Biomassa Est.',
                value: '${estimatedBiomassKg.toStringAsFixed(1)} kg',
                icon: Icons.scale,
                color: _kNavyBlue,
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Growth + FCR row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Cresc. Semanal',
                value: weeklyGrowthStr,
                icon: Icons.trending_up,
                color: _kGreen,
                context: context,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'C.A. (FCR)',
                value: fcrStr,
                icon: Icons.loop_outlined,
                color: _kOrange,
                context: context,
                helperText: fcrStr != '--' ? 'Ração: ${totalFeedConsumedKg.toStringAsFixed(0)}kg' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
    String? helperText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D30) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF263350)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildHistoryList(BuildContext context, List<BiometricsRecord> records) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFmt = DateFormat('dd/MM/yyyy');
    
    // Sort records newest first for display
    final sortedDisplay = List<BiometricsRecord>.from(records)
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    return List.generate(sortedDisplay.length, (index) {
      final record = sortedDisplay[index];
      
      // Calculate growth difference since the previous chronologically oldest record
      String diffText = '';
      Color diffColor = Colors.grey;
      
      // Look for the next item in sortedDisplay (which is older)
      if (index < sortedDisplay.length - 1) {
        final olderRecord = sortedDisplay[index + 1];
        final diff = record.weightG - olderRecord.weightG;
        if (diff > 0) {
          final pct = (diff / olderRecord.weightG) * 100;
          diffText = '+$diff g (+${pct.toStringAsFixed(1)}%)';
          diffColor = _kGreen;
        } else if (diff < 0) {
          final pct = (diff / olderRecord.weightG) * 100;
          diffText = '$diff g (${pct.toStringAsFixed(1)}%)';
          diffColor = Colors.red;
        } else {
          diffText = 'Estável';
        }
      } else {
        diffText = 'Peso inicial';
      }

      DateTime? dateParsed;
      try {
        dateParsed = DateTime.parse(record.recordDate);
      } catch (_) {}
      final dateStr = dateParsed != null ? timeFmt.format(dateParsed) : record.recordDate;

      return Dismissible(
        key: Key(record.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 12),
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
          final success = await ref
              .read(biometricsProvider(_selectedTankId!).notifier)
              .deleteBiometrics(record.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Registro de biometria excluído com sucesso.'
                      : 'Erro ao excluir biometria.',
                ),
                backgroundColor: success ? _kGreen : Colors.red,
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: isDark ? Border.all(color: const Color(0xFF263350)) : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _kTeal.withOpacity(0.1),
              child: const Icon(Icons.monitor_weight_outlined, color: _kTeal),
            ),
            title: Text(
              '${record.weightG} g',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: diffColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                diffText,
                style: TextStyle(
                  color: diffColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, {required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
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

  void _showAddBiometricsModal(BuildContext context, String tankId) {
    BiometricsScreen.showAddBiometricsModal(context, tankId);
  }
}

class _AddBiometricsForm extends ConsumerStatefulWidget {
  final String tankId;
  const _AddBiometricsForm({required this.tankId});

  @override
  ConsumerState<_AddBiometricsForm> createState() => _AddBiometricsFormState();
}

class _AddBiometricsFormState extends ConsumerState<_AddBiometricsForm> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isDark ? const Border(top: BorderSide(color: Color(0xFF263350), width: 1.5)) : null,
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 24),
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
                  Text(
                    'Registrar Peso Médio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _kNavyBlue,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Weight input
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'Peso Médio dos Peixes (gramas)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.scale),
                  suffixText: 'g',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Digite o peso';
                  final weight = int.tryParse(val);
                  if (weight == null || weight <= 0) {
                    return 'Digite um valor inteiro maior que zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Selector
              InkWell(
                onTap: () => _selectDate(context),
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
                          'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
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

    // Format date as LocalDate compatible string (yyyy-MM-dd)
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final success = await ref
        .read(biometricsProvider(widget.tankId).notifier)
        .logBiometrics(int.parse(_weightController.text), dateStr);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peso médio registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar biometria.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
