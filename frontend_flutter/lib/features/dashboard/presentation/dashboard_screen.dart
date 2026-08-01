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
import 'package:frontend_flutter/features/weather/providers/weather_provider.dart';
import 'package:frontend_flutter/features/weather/data/weather_model.dart';
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
        ref.read(weatherProvider.notifier).detectAndFetch();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [

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

          // Weather Widget
          _buildWeatherWidget(context, ref),

          const SizedBox(height: 16),

          _buildAdBanner(context),

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

  Widget _buildAdBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade500.withOpacity(0.3), width: 1.5),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.amber.shade100.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade600,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PROMOÇÃO',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AgroShop Nordeste',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Compre rações com 15% de desconto! Use cupom AQUA15.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              context.go('/marketplace');
            },
            child: const Text('Ver', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherWidget(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weatherState = ref.watch(weatherProvider);

    return GestureDetector(
      onTap: () => context.go('/weather'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: const Color(0xFF334155), width: 1) : null,
        ),
        child: weatherState.isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : weatherState.error != null
                ? Row(children: [
                    Icon(Icons.error_outline, color: Colors.red.shade300),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Erro ao carregar clima.', style: TextStyle(fontSize: 12)),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                  ])
                : weatherState.forecast != null
                    ? _WeatherBannerContent(
                        forecast: weatherState.forecast!,
                        cityName: weatherState.cityName,
                        locationGranted: weatherState.locationGranted,
                        isDark: isDark,
                      )
                    : const SizedBox.shrink(),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(plansProvider);
        ref.invalidate(tenantsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          // ── Executive Banner ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4AF37), size: 14),
                          SizedBox(width: 6),
                          Text('👑 SUPERADMIN MASTER',
                              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const Icon(Icons.bolt, color: Colors.amber, size: 24),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Comando do Proprietário do SaaS',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Você possui autonomia total para criar e editar os planos da plataforma, visualizar métricas globais e gerenciar todas as fazendas.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                // Quick Action Buttons
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/plans'),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Gerenciar Planos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13A538),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => TenantsScreen.showAddTenantModal(context, ref),
                      icon: const Icon(Icons.add_business_rounded, size: 16, color: Colors.amber),
                      label: const Text('Cadastrar Cliente (Tenant)', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── KPIs Section (Real Stripe Data) ────────────────────────────────
          ref.watch(masterOverviewProvider).when(
            data: (overview) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VISÃO GERAL DO SAAS (STRIPE)',
                      style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _kpi(context, 'Clientes (Tenants)', '${overview.totalFarms}', Icons.business, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _kpi(context, 'Assinaturas Ativas', '${overview.upToDateTenantsCount}', Icons.check_circle, Colors.green)),
                  ]),
                  const SizedBox(height: 12),
                  _kpi(context, 'Receita Recorrente Mensal (MRR Real)', currencyFmt.format(overview.estimatedMRR), Icons.trending_up, const Color(0xFF13A538), wide: true),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro ao carregar MRR: $e', style: const TextStyle(color: Colors.red)),
          ),

          const SizedBox(height: 28),

          // ── Plans Control Row ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Planos do SaaS',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 20),
                tooltip: 'Abrir Gestor Completo de Planos',
                onPressed: () => context.go('/plans'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          plansAsync.when(
            data: (plans) =>
                Column(children: plans.map((p) => _planCard(context, p, currencyFmt)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),

          const SizedBox(height: 28),

          // ── Tenants Control Row ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Clientes Farm (Tenants)',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, size: 20),
                tooltip: 'Cadastrar Novo Tenant',
                onPressed: () => TenantsScreen.showAddTenantModal(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 12),
          tenantsAsync.when(
            data: (tenants) => tenants.isEmpty
                ? Text('Nenhum tenant.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))
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
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          tooltip: 'Editar Plano',
          onPressed: () => GoRouter.of(context).go('/plans'),
        ),
      ]),
    );
  }


}

// ─── Banner compacto de clima exibido no Dashboard ───────────────────────────
class _WeatherBannerContent extends StatelessWidget {
  final WeatherForecast forecast;
  final String cityName;
  final bool locationGranted;
  final bool isDark;

  const _WeatherBannerContent({
    required this.forecast,
    required this.cityName,
    required this.locationGranted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final temp = forecast.currentTemp ?? forecast.days.first.tempMax;
    final windSpeed = forecast.currentWindSpeed ?? forecast.days.first.windSpeedMax;
    final info = forecast.currentInfo;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cidade + badge de localização
              Row(
                children: [
                  Icon(
                    locationGranted ? Icons.my_location : Icons.location_on_outlined,
                    size: 12,
                    color: locationGranted
                        ? Colors.green.shade600
                        : (isDark ? Colors.grey.shade400 : Colors.blue.shade700),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      cityName,
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.blue.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                info.label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Vento: ${windSpeed.round()} km/h  •  Ver previsão completa →',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Text(
              '${temp.round()}°C',
              style: TextStyle(
                color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(info.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white30 : Colors.blue.shade300,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }
}
