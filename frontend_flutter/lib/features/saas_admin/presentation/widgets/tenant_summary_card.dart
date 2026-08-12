import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_repository.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:frontend_flutter/features/dashboard/providers/farm_summary_provider.dart';
import 'package:intl/intl.dart';

class TenantSummaryCard extends ConsumerStatefulWidget {
  final FarmTenant tenant;

  const TenantSummaryCard({super.key, required this.tenant});

  @override
  ConsumerState<TenantSummaryCard> createState() => _TenantSummaryCardState();
}

class _TenantSummaryCardState extends ConsumerState<TenantSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summaryAsync = ref.watch(farmSummaryByIdProvider(tenant.id));

    String formattedDate = '';
    try {
      final dt = DateTime.parse(tenant.createdAt);
      formattedDate = DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      formattedDate = tenant.createdAt;
    }

    final statusColor = tenant.userActive ? const Color(0xFF13A538) : Colors.redAccent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tenant.userActive 
              ? (isDark ? const Color(0xFF263350) : Colors.grey.shade200)
              : Colors.redAccent.withOpacity(0.4),
          width: tenant.userActive ? 1.0 : 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Header Row (Always visible)
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.12),
                      radius: 18,
                      child: Icon(
                        tenant.userActive ? Icons.business_rounded : Icons.block_rounded,
                        color: statusColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tenant.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  tenant.userActive ? 'Ativo' : 'Desativado',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tenant.ownerEmail.isNotEmpty && tenant.ownerEmail != 'N/A'
                                ? '${tenant.ownerName} • ${tenant.ownerEmail}'
                                : (tenant.cnpj.isNotEmpty ? 'CNPJ: ${tenant.cnpj}' : 'Cliente SaaS'),
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.black54,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      size: 22,
                    ),
                  ],
                ),

                // Expanded Section
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // User Action Toggle Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              tenant.userActive ? Icons.check_circle_rounded : Icons.block_rounded,
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tenant.userActive ? 'Conta de Usuário: Ativa' : 'Conta de Usuário: Desativada',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final targetId = tenant.ownerId.isNotEmpty ? tenant.ownerId : tenant.id;
                            final success = await ref.read(saasAdminRepositoryProvider).toggleUserActiveStatus(targetId);
                            if (success) {
                              ref.invalidate(tenantsProvider);
                              ref.invalidate(tenantsFinancialReportProvider);
                              ref.invalidate(masterOverviewProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tenant.userActive ? 'Status do cliente ${tenant.name} desativado.' : 'Status do cliente ${tenant.name} reativado.'),
                                    backgroundColor: tenant.userActive ? Colors.redAccent : const Color(0xFF13A538),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tenant.userActive ? Colors.redAccent : const Color(0xFF13A538),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: Icon(
                            tenant.userActive ? Icons.person_off_rounded : Icons.person_add_alt_1_rounded,
                            size: 14,
                          ),
                          label: Text(
                            tenant.userActive ? 'Desativar' : 'Ativar',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Operational metrics overview
                  summaryAsync.when(
                    data: (summary) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 3.0,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
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
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Erro ao carregar dados operacionais da fazenda',
                      style: TextStyle(color: Colors.red.shade400, fontSize: 10),
                    ),
                  ),
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Cadastrado em: $formattedDate',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2E3B52).withOpacity(0.5) : Colors.grey.shade200,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
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
}
