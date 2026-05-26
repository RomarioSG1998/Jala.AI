import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/features/water_quality/providers/water_quality_provider.dart';
import 'package:frontend_flutter/features/dashboard/providers/farm_summary_provider.dart';
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

// ─── AppShell – Casca Permanente com Header e Bottom Nav ────────────────────

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _kNavyBlue = Color(0xFF003366);
  static const _kGreen = Color(0xFF13A538);

  void _handleCentralFabPressed(BuildContext context, WidgetRef ref) {
    final state = GoRouterState.of(context);
    final currentRoute = state.matchedLocation;

    switch (currentRoute) {
      case '/tanks':
        TanksScreen.showAddTankModal(context);
        break;
      case '/water-quality':
        WaterQualityScreen.showAddLogModal(context, ref);
        break;
      case '/inventory':
        InventoryScreen.showAddItemModal(context, ref);
        break;
      case '/harvests':
        HarvestsScreen.showLogHarvestModal(context, ref);
        break;
      case '/maintenance':
        MaintenanceScreen.showAddTaskModal(context, ref);
        break;
      case '/finances':
        FinancesScreen.showAddTransactionModal(context, ref);
        break;
      case '/suppliers':
        SuppliersScreen.showAddSupplierModal(context, ref);
        break;
      case '/tenants':
        TenantsScreen.showAddTenantModal(context, ref);
        break;
      case '/feeding-records':
        FeedingRecordsScreen.showAddFeedingRecordModal(context, ref);
        break;
      case '/saas-dashboard':
        TenantsScreen.showAddTenantModal(context, ref);
        break;
      default:
        final authState = ref.read(authNotifierProvider);
        if (authState.accountType == 'SAAS_ADMIN') {
          TenantsScreen.showAddTenantModal(context, ref);
        } else {
          TanksScreen.showAddTankModal(context);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.accountType ?? '';
    final currentIndex = navigationShell.currentIndex;
    final summaryAsync = ref.watch(farmSummaryProvider);
    final pendingTasks = summaryAsync.maybeWhen(
      data: (s) => s.pendingMaintenanceTasks,
      orElse: () => 0,
    );

    // Título dinâmico por aba
    const tabTitles = ['Início', 'Tanques', 'Qualidade da Água', 'Menu'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      // ── AppBar permanente ────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kNavyBlue,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            SizedBox(
              height: 44,
              width: 44,
              child: Image.network(
                '/logo_emblem.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    children: [
                      TextSpan(text: 'Aqua', style: TextStyle(color: Colors.white)),
                      TextSpan(text: 'Sertão', style: TextStyle(color: _kGreen)),
                    ],
                  ),
                ),
                const Text('PISCICULTURA INTELIGENTE',
                    style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
          Stack(
            children: [
              IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () {}),
              if (pendingTasks > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text('$pendingTasks',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
        ],
      ),
      // ── Drawer lateral ───────────────────────────────────────────────────
      drawer: _AppDrawer(role: role, ref: ref),
      // ── Bottom Navigation permanente ─────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(context, ref, currentIndex, role),
      // ── Corpo dinâmico ───────────────────────────────────────────────────
      body: role == 'SAAS_ADMIN' && currentIndex == 0
          ? const _SaasAdminBody()
          : navigationShell,
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int currentIndex, String role) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 10),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Início', currentIndex == 0),
              _buildNavItem(1, Icons.water_drop_rounded, Icons.water_drop_outlined, 'Tanques', currentIndex == 1),
              const SizedBox(width: 48), // Espaço reservado para o FAB central
              _buildNavItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Qualidade', currentIndex == 2),
              _buildNavItem(3, Icons.apps_rounded, Icons.apps_outlined, 'Menu', currentIndex == 3),
            ],
          ),
        ),
        Positioned(
          top: -12,
          child: _buildCentralFab(context, ref),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, bool isActive) {
    final color = isActive ? _kGreen : Colors.grey.shade400;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          navigationShell.goBranch(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 12 : 0,
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralFab(BuildContext context, WidgetRef ref) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_kNavyBlue, Color(0xFF0055A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kNavyBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _handleCentralFabPressed(context, ref),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── FarmDashboardBody – Conteúdo do Início ─────────────────────────────────

class FarmDashboardBody extends ConsumerWidget {
  const FarmDashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.accountType ?? '';

    if (role == 'SAAS_ADMIN') return const _SaasAdminBody();

    final tanksAsync = ref.watch(tanksProvider);
    final wqAsync = ref.watch(waterQualityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tanksProvider);
        ref.invalidate(waterQualityProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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

          // KPIs
          const Text('VISÃO GERAL',
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          tanksAsync.when(
            data: (tanks) => Row(children: [
              Expanded(child: _kpi('Tanques', '${tanks.length}', Icons.water, Colors.blue)),
              const SizedBox(width: 12),
              wqAsync.when(
                data: (recs) =>
                    Expanded(child: _kpi('Leituras pH', '${recs.length}', Icons.science, Colors.teal)),
                loading: () =>
                    Expanded(child: _kpi('Leituras pH', '…', Icons.science, Colors.teal)),
                error: (_, __) => Expanded(child: _kpi('Erro', '!', Icons.science, Colors.red)),
              ),
            ]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Tanks preview
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tanques',
                style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go('/tanks'),
              child: const Text('Ver todos →',
                  style: TextStyle(color: Color(0xFF13A538))),
            ),
          ]),
          const SizedBox(height: 8),
          tanksAsync.when(
            data: (tanks) {
              if (tanks.isEmpty) return _emptyHint('Nenhum tanque cadastrado.', Icons.water);
              return Column(
                children: tanks
                    .take(3)
                    .map((tank) => GestureDetector(
                          onTap: () => context.go('/tanks'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                radius: 20,
                                child: const Icon(Icons.water, color: Colors.blue, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Text(tank.name,
                                      style: const TextStyle(
                                          color: Colors.black87, fontWeight: FontWeight.w600))),
                              Text('${tank.fishCapacity} peixes',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              const Icon(Icons.chevron_right, color: Colors.black26, size: 18),
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
            const Text('Última Leitura de Água',
                style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go('/water-quality'),
              child: const Text('Ver todos →',
                  style: TextStyle(color: Color(0xFF13A538))),
            ),
          ]),
          const SizedBox(height: 8),
          wqAsync.when(
            data: (records) {
              if (records.isEmpty) return _emptyHint('Nenhuma leitura registrada.', Icons.science);
              final latest = records.last;
              Color phColor = latest.ph < 6.5 || latest.ph > 8.5
                  ? Colors.red
                  : (latest.ph < 7.0 || latest.ph > 8.0 ? Colors.orange : Colors.green);
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _metric('pH', latest.ph.toStringAsFixed(1), phColor),
                  _metric('Temp', '${latest.temperature.toStringAsFixed(1)}°C', Colors.blue),
                  _metric('O₂', '${latest.dissolvedOxygen.toStringAsFixed(1)} mg/L', Colors.lightBlue),
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

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ]),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
    ]);
  }

  Widget _emptyHint(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Icon(icon, color: Colors.grey.shade300, size: 28),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ]),
    );
  }
}

// ─── SaaS Admin Body ─────────────────────────────────────────────────────────

class _SaasAdminBody extends ConsumerWidget {
  const _SaasAdminBody();

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
        padding: const EdgeInsets.all(20),
        children: [
          tenantsAsync.when(
            data: (tenants) => plansAsync.when(
              data: (plans) {
                final totalMrr = plans.fold<double>(0, (s, p) => s + p.priceMonthly);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OVERVIEW',
                        style: TextStyle(
                            color: Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _kpi('Tenants', '${tenants.length}', Icons.business, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _kpi('Planos', '${plans.length}', Icons.layers, Colors.purple)),
                    ]),
                    const SizedBox(height: 12),
                    _kpi('MRR Total', currencyFmt.format(totalMrr), Icons.trending_up, Colors.green, wide: true),
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
          const Text('Planos SaaS',
              style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          plansAsync.when(
            data: (plans) =>
                Column(children: plans.map((p) => _planCard(p, currencyFmt)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 28),
          const Text('Farm Tenants',
              style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          tenantsAsync.when(
            data: (tenants) => tenants.isEmpty
                ? const Text('Nenhum tenant.', style: TextStyle(color: Colors.black54))
                : Column(children: tenants.map((t) => _tenantCard(t)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color, {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
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
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _planCard(SaasPlan plan, NumberFormat fmt) {
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green];
    final color = colors[plan.name.hashCode.abs() % colors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
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
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          Text('${plan.maxTanks} tanques · ${plan.maxUsers} usuários',
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ])),
        Text(fmt.format(plan.priceMonthly),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    );
  }

  Widget _tenantCard(dynamic tenant) {
    String formatted = '';
    try {
      formatted = DateFormat('MMM dd, yyyy').format(DateTime.parse(tenant.createdAt));
    } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: const Icon(Icons.business, color: Colors.indigo, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tenant.name,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          if ((tenant.cnpj as String).isNotEmpty)
            Text('CNPJ: ${tenant.cnpj}',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Ativo',
                style: TextStyle(
                    color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          if (formatted.isNotEmpty)
            Text(formatted, style: const TextStyle(color: Colors.black38, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ─── Drawer lateral ──────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  final String role;
  final WidgetRef ref;
  const _AppDrawer({required this.role, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    final authState = watchRef.watch(authNotifierProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFF003366)),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white12,
                child: const Icon(Icons.person, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  authState.email?.split('@').first ?? 'Usuário',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                  child: Text(role,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ])),
            ]),
          ),

          // Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _tile(context, Icons.dashboard, 'Dashboard', const Color(0xFF003366),
                    () { Navigator.pop(context); }),

                if (role == 'SAAS_ADMIN') ...[
                  _section('Admin'),
                  _tile(context, Icons.business, 'Tenants', Colors.indigo, () {
                    Navigator.pop(context); context.go('/tenants');
                  }),
                  _tile(context, Icons.local_shipping, 'Fornecedores', Colors.brown, () {
                    Navigator.pop(context); context.go('/suppliers');
                  }),
                ],

                if (role == 'FARM_OWNER' || role == 'CLIENT') ...[
                  _section('Operacional'),
                  _tile(context, Icons.water, 'Tanques', Colors.blue, () {
                    Navigator.pop(context); context.go('/tanks');
                  }),
                  _tile(context, Icons.science, 'Qualidade da Água', Colors.teal, () {
                    Navigator.pop(context); context.go('/water-quality');
                  }),
                  _tile(context, Icons.restaurant, 'Alimentação', Colors.purple, () {
                    Navigator.pop(context); context.go('/feeding-records');
                  }),
                  _tile(context, Icons.inventory, 'Estoque', Colors.orange, () {
                    Navigator.pop(context); context.go('/inventory');
                  }),
                  _tile(context, Icons.agriculture, 'Colheitas', Colors.green, () {
                    Navigator.pop(context); context.go('/harvests');
                  }),
                ],

                if (role == 'FARM_OWNER') ...[
                  _section('Gestão'),
                  _tile(context, Icons.build, 'Manutenção', Colors.grey.shade700, () {
                    Navigator.pop(context); context.go('/maintenance');
                  }),
                  _tile(context, Icons.attach_money, 'Finanças', Colors.green.shade700, () {
                    Navigator.pop(context); context.go('/finances');
                  }),
                ],
              ],
            ),
          ),

          const Divider(color: Colors.black12),
          _tile(context, Icons.logout, 'Sair', Colors.red, () {
            Navigator.pop(context);
            watchRef.read(authNotifierProvider.notifier).logout();
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }
}
