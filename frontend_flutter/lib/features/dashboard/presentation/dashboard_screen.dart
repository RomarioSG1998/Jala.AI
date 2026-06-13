import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/widgets/tenant_summary_card.dart';
import 'package:frontend_flutter/core/api/server_ping_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/features/water_quality/providers/water_quality_provider.dart';
import 'package:frontend_flutter/features/dashboard/providers/farm_summary_provider.dart';
import 'dart:convert';
import 'package:frontend_flutter/features/profile/providers/profile_image_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/features/tanks/presentation/tanks_screen.dart';
import 'package:frontend_flutter/features/water_quality/presentation/water_quality_screen.dart';
import 'package:frontend_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:frontend_flutter/features/harvests/presentation/harvests_screen.dart';
import 'package:frontend_flutter/features/maintenance/presentation/maintenance_screen.dart';
import 'package:frontend_flutter/features/finances/presentation/finances_screen.dart';
import 'package:frontend_flutter/features/suppliers/presentation/suppliers_screen.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/tenants_screen.dart';
import 'package:frontend_flutter/features/feeding_records/presentation/feeding_records_screen.dart';
import 'package:frontend_flutter/features/employees/presentation/employees_screen.dart';
import 'package:frontend_flutter/features/employees/providers/employee_permissions_provider.dart';
import 'package:frontend_flutter/features/maintenance/providers/maintenance_provider.dart';
import 'package:frontend_flutter/features/maintenance/data/maintenance_model.dart';
import 'package:frontend_flutter/features/tanks/data/tank_model.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';
import 'dart:convert';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/core/navigation/app_shell.dart';






// ─── FarmDashboardBody – Conteúdo do Início ─────────────────────────────────

class FarmDashboardBody extends ConsumerWidget {
  const FarmDashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authNotifierProvider);
    final role = authState.accountType ?? '';

    if (role == 'SAAS_ADMIN') return const SaasAdminBody();

    final tanksAsync = ref.watch(tanksProvider);
    final wqAsync = ref.watch(waterQualityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tanksProvider);
        ref.invalidate(waterQualityProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Consumer(
            builder: (context, ref, child) {
              final serverStatus = ref.watch(serverPingProvider);
              if (serverStatus == ServerStatus.sleeping) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF1E293B) 
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark 
                          ? Colors.orange.shade800.withOpacity(0.5) 
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? const Color(0xFF00FF66) : const Color(0xFF13A538)
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Acordando servidor no Render... Por favor, aguarde os dados carregarem.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Welcome banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003366), Color(0xFF13A538)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Bem-vindo de volta! 👋',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Seu painel operacional',
                      style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Dados em tempo real dos seus tanques.',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.water, color: Colors.white24, size: 52),
            ]),
          ),

          const SizedBox(height: 24),

          // KPIs
          Text('VISÃO GERAL',
              style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          tanksAsync.when(
            data: (tanks) => Row(children: [
              Expanded(child: _kpi(context, 'Tanques', '${tanks.length}', Icons.water, Colors.blue)),
              const SizedBox(width: 12),
              wqAsync.when(
                data: (recs) =>
                    Expanded(child: _kpi(context, 'Leituras pH', '${recs.length}', Icons.science, Colors.teal)),
                loading: () =>
                    Expanded(child: _kpi(context, 'Leituras pH', '…', Icons.science, Colors.teal)),
                error: (_, __) => Expanded(child: _kpi(context, 'Erro', '!', Icons.science, Colors.red)),
              ),
            ]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Tanks preview
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Tanques',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go('/tanks'),
              child: const Text('Ver todos →',
                  style: TextStyle(color: Color(0xFF13A538))),
            ),
          ]),
          const SizedBox(height: 8),
          tanksAsync.when(
            data: (tanks) {
              if (tanks.isEmpty) return _emptyHint(context, 'Nenhum tanque cadastrado.', Icons.water);
              return Column(
                children: tanks
                    .take(3)
                    .map((tank) => GestureDetector(
                          onTap: () => context.go('/tanks'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor: isDark ? const Color(0xFF263350) : Colors.blue.shade50,
                                radius: 20,
                                child: Icon(Icons.water, color: isDark ? Colors.blue.shade300 : Colors.blue, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Text(tank.name,
                                      style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))),
                              Text('${tank.fishCapacity} peixes',
                                  style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade600, fontSize: 12)),
                              Icon(Icons.chevron_right, color: isDark ? Colors.white30 : Colors.black26, size: 18),
                            ]),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),

          const SizedBox(height: 24),

          // Latest water quality
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Última Leitura de Água',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go('/water-quality'),
              child: const Text('Ver todos →',
                  style: TextStyle(color: Color(0xFF13A538))),
            ),
          ]),
          const SizedBox(height: 8),
          wqAsync.when(
            data: (records) {
              if (records.isEmpty) return _emptyHint(context, 'Nenhuma leitura registrada.', Icons.science);
              final latest = records.last;
              Color phColor = latest.ph < 6.5 || latest.ph > 8.5
                  ? Colors.red
                  : (latest.ph < 7.0 || latest.ph > 8.0 ? Colors.orange : Colors.green);
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _metric(context, 'pH', latest.ph.toStringAsFixed(1), phColor),
                  _metric(context, 'Temp', '${latest.temperature.toStringAsFixed(1)}°C', Colors.blue),
                  _metric(context, 'O₂', '${latest.dissolvedOxygen.toStringAsFixed(1)} mg/L', Colors.lightBlue),
                ]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _kpi(BuildContext context, String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black54, fontSize: 12)),
      ]),
    );
  }

  Widget _metric(BuildContext context, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 11)),
    ]);
  }

  Widget _emptyHint(BuildContext context, String text, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Icon(icon, color: isDark ? Colors.white30 : Colors.grey.shade300, size: 28),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade600, fontSize: 13)),
      ]),
    );
  }
}

// ─── SaaS Admin Body ─────────────────────────────────────────────────────────

class SaasAdminBody extends ConsumerWidget {
  const SaasAdminBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final tenantsAsync = ref.watch(tenantsProvider);
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(plansProvider);
        ref.invalidate(tenantsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          tenantsAsync.when(
            data: (tenants) => plansAsync.when(
              data: (plans) {
                final totalMrr = plans.fold<double>(0, (s, p) => s + p.priceMonthly);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VISÃO GERAL',
                        style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _kpi(context, 'Tenants', '${tenants.length}', Icons.business, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _kpi(context, 'Planos', '${plans.length}', Icons.layers, Colors.purple)),
                    ]),
                    const SizedBox(height: 12),
                    _kpi(context, 'MRR Total', currencyFmt.format(totalMrr), Icons.trending_up, Colors.green, wide: true),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 28),
          Text('Planos SaaS',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          plansAsync.when(
            data: (plans) =>
                Column(children: plans.map((p) => _planCard(context, p, currencyFmt)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 28),
          Text('Clientes Farm (Tenants)',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          tenantsAsync.when(
            data: (tenants) => tenants.isEmpty
                ? Text('Nenhum tenant.', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54))
                : Column(children: tenants.map((t) => TenantSummaryCard(tenant: t)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _kpi(BuildContext context, String label, String value, IconData icon, Color color, {bool wide = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration:
              BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _planCard(BuildContext context, SaasPlan plan, NumberFormat fmt) {
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green];
    final color = colors[plan.name.hashCode.abs() % colors.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        Container(
            width: 4,
            height: 48,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(plan.name,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          Text('${plan.maxTanks} tanques · ${plan.maxUsers} usuários',
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 12)),
        ])),
        Text(fmt.format(plan.priceMonthly),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    );
  }


}


