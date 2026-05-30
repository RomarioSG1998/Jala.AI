import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/dashboard/providers/farm_summary_provider.dart';
import 'package:intl/intl.dart';

class TenantSummaryCard extends ConsumerWidget {
  final FarmTenant tenant;

  const TenantSummaryCard({super.key, required this.tenant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(farmSummaryByIdProvider(tenant.id));

    String formattedDate = '';
    try {
      final dt = DateTime.parse(tenant.createdAt);
      formattedDate = DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      formattedDate = tenant.createdAt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF263350) : Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Logo, Name, status, date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF003366).withOpacity(0.1),
                radius: 22,
                child: const Icon(Icons.business, color: Color(0xFF003366), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (tenant.cnpj.isNotEmpty)
                      Text(
                        'CNPJ: ${tenant.cnpj}',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ativo',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (formattedDate.isNotEmpty)
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Operational metrics overview
          summaryAsync.when(
            data: (summary) {
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _buildMetricCell(
                    context,
                    label: 'Tanques',
                    value: '${summary.totalTanks} total',
                    subValue: '${summary.activeTanks} ativos',
                    icon: Icons.water_drop,
                    iconColor: Colors.blue,
                  ),
                  _buildMetricCell(
                    context,
                    label: 'Capacidade',
                    value: '${summary.totalFishCapacity}',
                    subValue: 'peixes estocados',
                    icon: Icons.grid_view_rounded,
                    iconColor: Colors.purple,
                  ),
                  _buildMetricCell(
                    context,
                    label: 'Alimentação Hoje',
                    value: '${summary.feedingTodayKg.toStringAsFixed(1)} kg',
                    subValue: 'ração distribuída',
                    icon: Icons.restaurant,
                    iconColor: Colors.orange,
                  ),
                  _buildMetricCell(
                    context,
                    label: 'Manutenção',
                    value: '${summary.pendingMaintenanceTasks}',
                    subValue: 'tarefas pendentes',
                    icon: Icons.build_circle,
                    iconColor: summary.pendingMaintenanceTasks > 0 ? Colors.red : Colors.green,
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Text(
              'Erro ao carregar dados operacionais da fazenda',
              style: TextStyle(color: Colors.red.shade400, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCell(
    BuildContext context, {
    required String label,
    required String value,
    required String subValue,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3B52).withOpacity(0.5) : Colors.grey.shade200,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subValue,
                  style: TextStyle(
                    fontSize: 8,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
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
}
