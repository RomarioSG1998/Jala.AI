import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/water_quality/providers/water_quality_provider.dart';
import 'package:intl/intl.dart';

class WaterQualityScreen extends ConsumerWidget {
  const WaterQualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wqAsyncValue = ref.watch(waterQualityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Quality'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Future: Open Log New Record Modal
        },
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
                
                // Visual Indicator for pH Level
                Color phColor = Colors.green;
                if (record.phLevel < 6.5 || record.phLevel > 8.5) {
                  phColor = Colors.red;
                } else if (record.phLevel < 7.0 || record.phLevel > 8.0) {
                  phColor = Colors.orange;
                }

                // Format the Date
                DateTime date = DateTime.parse(record.recordedAt);
                String formattedDate = DateFormat('MMM dd, yyyy - HH:mm').format(date);

                return Card(
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
                            _buildMetric('pH Level', record.phLevel.toStringAsFixed(1), phColor),
                            _buildMetric('Temp', '${record.temperature.toStringAsFixed(1)}°C', Colors.blue),
                            _buildMetric('Oxygen', '${record.dissolvedOxygen.toStringAsFixed(1)} mg/L', Colors.lightBlue),
                          ],
                        ),
                      ],
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
