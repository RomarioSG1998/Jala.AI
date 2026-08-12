import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/tenants_screen.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/widgets/tenant_summary_card.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class SaasDashboardScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const SaasDashboardScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SaasDashboardScreen> createState() => _SaasDashboardScreenState();
}

class _SaasDashboardScreenState extends ConsumerState<SaasDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final masterOverviewAsync = ref.watch(masterOverviewProvider);
    final tenantsAsync = ref.watch(tenantsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              title: const Text('Visão Geral do Admin Master',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(masterOverviewProvider);
          ref.invalidate(tenantsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Banner Boas-Vindas Admin Master ──────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF003366), Color(0xFF0055A5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003366).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Painel do Administrador Master',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gerencie clientes, monitoramento de saúde do ecossistema e planos SaaS em tempo real.',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── KPIs Globais do Sistema ─────────────────────────────────
            Text(
              'MÉTRICAS GLOBAIS DA PLATAFORMA',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            masterOverviewAsync.when(
              data: (overview) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _summaryKpiCard(
                                  context,
                                  title: 'Total de Tenants',
                                  value: '${overview.totalFarms}',
                                  icon: Icons.business_rounded,
                                  color: Colors.indigo,
                                  subtitle: '${overview.upToDateTenantsCount} ativos',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _summaryKpiCard(
                                  context,
                                  title: 'Clientes em Dia',
                                  value: '${overview.upToDateTenantsCount}',
                                  icon: Icons.check_circle_rounded,
                                  color: const Color(0xFF13A538),
                                  subtitle: 'Sem pendências',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _summaryKpiCard(
                                  context,
                                  title: 'Em Atraso',
                                  value: '${overview.pastDueTenantsCount}',
                                  icon: Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  subtitle: 'Inadimplentes',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _summaryKpiCard(
                                  context,
                                  title: 'Planos Free',
                                  value: '${overview.freeTenantsCount}',
                                  icon: Icons.card_giftcard_rounded,
                                  color: Colors.purple,
                                  subtitle: 'Degustação',
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _summaryKpiCard(
                            context,
                            title: 'Total de Tenants',
                            value: '${overview.totalFarms}',
                            icon: Icons.business_rounded,
                            color: Colors.indigo,
                            subtitle: '${overview.upToDateTenantsCount} ativos',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryKpiCard(
                            context,
                            title: 'Clientes em Dia',
                            value: '${overview.upToDateTenantsCount}',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF13A538),
                            subtitle: 'Sem pendências',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryKpiCard(
                            context,
                            title: 'Em Atraso',
                            value: '${overview.pastDueTenantsCount}',
                            icon: Icons.warning_amber_rounded,
                            color: Colors.orange,
                            subtitle: 'Inadimplentes',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryKpiCard(
                            context,
                            title: 'Planos Free',
                            value: '${overview.freeTenantsCount}',
                            icon: Icons.card_giftcard_rounded,
                            color: Colors.purple,
                            subtitle: 'Degustação',
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF13A538)))),
              error: (e, _) => Text('Erro ao carregar KPIs: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 24),

            // ── Atalhos Rápidos de Gestão ─────────────────────────────
            Text(
              'AÇÕES RÁPIDAS DE GESTÃO',
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                if (isMobile) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _quickActionButton(
                              context,
                              icon: Icons.add_business_rounded,
                              label: 'Novo Tenant',
                              color: const Color(0xFF13A538),
                              onTap: () => TenantsScreen.showAddTenantModal(context, ref),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _quickActionButton(
                              context,
                              icon: Icons.analytics_rounded,
                              label: 'Dashboard Financeiro',
                              color: Colors.teal,
                              onTap: () => context.go('/saas-dashboard'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _quickActionButton(
                              context,
                              icon: Icons.group_work_rounded,
                              label: 'Clientes / Tenants',
                              color: Colors.indigo,
                              onTap: () => context.go('/tenants'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _quickActionButton(
                              context,
                              icon: Icons.layers_rounded,
                              label: 'Planos & Preços',
                              color: Colors.purple,
                              onTap: () => context.go('/plans'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _quickActionButton(
                        context,
                        icon: Icons.add_business_rounded,
                        label: 'Novo Tenant',
                        color: const Color(0xFF13A538),
                        onTap: () => TenantsScreen.showAddTenantModal(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickActionButton(
                        context,
                        icon: Icons.analytics_rounded,
                        label: 'Dashboard Financeiro',
                        color: Colors.teal,
                        onTap: () => context.go('/saas-dashboard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickActionButton(
                        context,
                        icon: Icons.group_work_rounded,
                        label: 'Clientes / Tenants',
                        color: Colors.indigo,
                        onTap: () => context.go('/tenants'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickActionButton(
                        context,
                        icon: Icons.layers_rounded,
                        label: 'Planos & Preços',
                        color: Colors.purple,
                        onTap: () => context.go('/plans'),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // ── Clientes Recentes ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clientes Recentes',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go('/tenants'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF13A538)),
                  label: const Text('Ver Todos', style: TextStyle(color: Color(0xFF13A538), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            tenantsAsync.when(
              data: (tenants) {
                if (tenants.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.business_center_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum cliente cadastrado no momento.',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                        ),
                      ],
                    ),
                  );
                }

                // Show up to 4 recent tenants
                final recentTenants = tenants.take(4).toList();

                return Column(
                  children: recentTenants.map((t) => TenantSummaryCard(tenant: t)).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF13A538)))),
              error: (e, _) => Text('Erro ao carregar tenants: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _summaryKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF263350) : color.withOpacity(0.2)),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: color.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.black54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF263350) : Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
