import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/water_quality/providers/water_quality_provider.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:intl/intl.dart';

class WaterQualityScreen extends ConsumerWidget {
  const WaterQualityScreen({super.key});

  void _showAddLogModal(BuildContext context, WidgetRef ref) {
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
        child: const AddWaterQualityForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wqAsyncValue = ref.watch(waterQualityProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState.accountType == 'FARM_OWNER';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Quality'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLogModal(context, ref),
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: wqAsyncValue.when(
        data: (records) {
          if (records.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(waterQualityProvider.notifier).refreshRecords(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                
                Color phColor = Colors.green;
                if (record.ph < 6.5 || record.ph > 8.5) {
                  phColor = Colors.red;
                } else if (record.ph < 7.0 || record.ph > 8.0) {
                  phColor = Colors.orange;
                }

                DateTime date = DateTime.parse(record.measurementTime);
                String formattedDate = DateFormat('MMM dd, yyyy - HH:mm').format(date);

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
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Log'),
                        content: const Text('Are you sure you want to delete this water quality record?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    ref.read(waterQualityProvider.notifier).deleteRecord(record.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tank ID: ${record.tankId.substring(0, 8)}...',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetric('pH Level', record.ph.toStringAsFixed(1), phColor),
                              _buildMetric('Temp', '${record.temperature.toStringAsFixed(1)}°C', Colors.blue),
                              _buildMetric('Oxygen', '${record.dissolvedOxygen.toStringAsFixed(1)} mg/L', Colors.lightBlue),
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
                'Failed to load records:\n${error.toString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(waterQualityProvider.notifier).refreshRecords(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No water quality records found.',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
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
    // Ensure tanks are loaded so user can select one
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
          const SnackBar(content: Text('Please select a tank')),
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
          const SnackBar(content: Text('Failed to save record')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Water Quality',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            tanksAsync.when(
              data: (tanks) {
                if (tanks.isEmpty) return const Text('No tanks available. Create a tank first.');
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Tank', border: OutlineInputBorder()),
                  value: _selectedTankId,
                  items: tanks.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (val) => setState(() => _selectedTankId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => Text('Error loading tanks: $err'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phController,
              decoration: const InputDecoration(labelText: 'pH Level', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Required' : (double.tryParse(v) == null ? 'Invalid number' : null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tempController,
              decoration: const InputDecoration(labelText: 'Temperature (°C)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Required' : (double.tryParse(v) == null ? 'Invalid number' : null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _oxygenController,
              decoration: const InputDecoration(labelText: 'Dissolved Oxygen (mg/L)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Required' : (double.tryParse(v) == null ? 'Invalid number' : null),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }
}
