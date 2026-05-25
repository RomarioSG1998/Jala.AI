import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/saas_dashboard_screen.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/features/water_quality/providers/water_quality_provider.dart';
import 'package:intl/intl.dart';

/// AppShell: wrapper with Drawer for all authenticated screens.
/// The body shows the role-specific dashboard on first load.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.accountType ?? '';

    return Scaffold(
      drawer: _AppDrawer(role: role),
      body: role == 'SAAS_ADMIN'
          ? const _SaasAdminHome()
          : const _FarmHome(),
    );
  }
}

// ─── SaaS Admin Home ─────────────────────────────────────────────────────────

class _SaasAdminHome extends ConsumerWidget {
  const _SaasAdminHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SaasDashboardScreen(embedded: true);
  }
}

// ─── Farm Home Dashboard ─────────────────────────────────────────────────────

class _FarmHome extends ConsumerWidget {
  const _FarmHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final tanksAsync = ref.watch(tanksProvider);
    final wqAsync = ref.watch(waterQualityProvider);
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AquaSertão',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(authState.email ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.4)),
              ),
              child: Text(
                authState.accountType ?? '',
                style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tanksProvider);
          ref.invalidate(waterQualityProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // ── Welcome Banner ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bem-vindo de volta! 👋',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          authState.email?.split('@').first ?? 'Usuário',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Seus tanques e métricas em tempo real',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.water, color: Colors.white24, size: 56),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── KPI Row ───────────────────────────────────────────────
            const Text('Visão Geral',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            tanksAsync.when(
              data: (tanks) => Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      label: 'Tanques',
                      value: '${tanks.length}',
                      icon: Icons.water,
                      color: Colors.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  wqAsync.when(
                    data: (records) => Expanded(
                      child: _kpiCard(
                        label: 'Leituras pH',
                        value: '${records.length}',
                        icon: Icons.science,
                        color: Colors.teal,
                      ),
                    ),
                    loading: () => Expanded(
                        child: _kpiCard(
                            label: 'Leituras pH',
                            value: '…',
                            icon: Icons.science,
                            color: Colors.teal)),
                    error: (_, __) => Expanded(
                        child: _kpiCard(
                            label: 'Leituras pH',
                            value: '!',
                            icon: Icons.science,
                            color: Colors.red)),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // ── Tanks Quick List ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seus Tanques',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.push('/tanks'),
                  child: const Text('Ver todos →',
                      style: TextStyle(color: Colors.cyan)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            tanksAsync.when(
              data: (tanks) {
                if (tanks.isEmpty) {
                  return _emptyHint(
                      'Nenhum tanque cadastrado ainda.', Icons.water);
                }
                final preview = tanks.take(3).toList();
                return Column(
                  children: preview
                      .map((tank) => _tankRow(context, tank))
                      .toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e',
                  style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 24),

            // ── Latest Water Quality ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Última Qualidade da Água',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.push('/water-quality'),
                  child: const Text('Ver todos →',
                      style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            wqAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return _emptyHint(
                      'Nenhuma leitura registrada.', Icons.science);
                }
                final latest = records.last;
                Color phColor = Colors.green;
                if (latest.ph < 6.5 || latest.ph > 8.5) {
                  phColor = Colors.red;
                } else if (latest.ph < 7.0 || latest.ph > 8.0) {
                  phColor = Colors.orange;
                }
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metric('pH', latest.ph.toStringAsFixed(1), phColor),
                      _metric('Temp', '${latest.temperature.toStringAsFixed(1)}°C',
                          Colors.blue),
                      _metric('O₂', '${latest.dissolvedOxygen.toStringAsFixed(1)} mg/L',
                          Colors.lightBlue),
                    ],
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro: $e',
                  style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 24),

            // ── Quick-access module buttons ───────────────────────────
            const Text('Módulos',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _quickModuleGrid(context, authState.accountType ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _tankRow(BuildContext context, dynamic tank) {
    return GestureDetector(
      onTap: () => context.push('/tanks'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.cyan.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.cyan.withOpacity(0.15),
              radius: 20,
              child:
                  const Icon(Icons.water, color: Colors.cyan, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(tank.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            Text('${tank.fishCapacity} peixes',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _emptyHint(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 28),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _quickModuleGrid(BuildContext context, String role) {
    final modules = <_ModuleItem>[];

    if (role == 'FARM_OWNER' || role == 'CLIENT') {
      modules.addAll([
        _ModuleItem('Tanques', Icons.water, Colors.cyan, '/tanks'),
        _ModuleItem('Qualidade Água', Icons.science, Colors.teal, '/water-quality'),
        _ModuleItem('Estoque', Icons.inventory, Colors.orange, '/inventory'),
        _ModuleItem('Colheitas', Icons.agriculture, Colors.green, '/harvests'),
      ]);
    }
    if (role == 'FARM_OWNER') {
      modules.add(
          _ModuleItem('Manutenção', Icons.build, Colors.grey, '/maintenance'));
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: modules
          .map((m) => GestureDetector(
                onTap: () => context.push(m.route),
                child: Container(
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: m.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.icon, color: m.color, size: 20),
                      const SizedBox(width: 8),
                      Text(m.label,
                          style: TextStyle(
                              color: m.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _ModuleItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _ModuleItem(this.label, this.icon, this.color, this.route);
}

// ─── App Drawer ───────────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  final String role;
  const _AppDrawer({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Drawer(
      backgroundColor: const Color(0xFF0D1117),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.withOpacity(0.2),
                    child:
                        const Icon(Icons.person, color: Colors.blue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.email?.split('@').first ?? 'Usuário',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            role,
                            style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white12),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Dashboard (home)
                  _drawerTile(
                    context: context,
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    color: Colors.blue,
                    onTap: () => Navigator.of(context).pop(),
                  ),

                  if (role == 'SAAS_ADMIN') ...[
                    const _DrawerSection('Admin'),
                    _drawerTile(
                        context: context,
                        icon: Icons.business,
                        label: 'Tenants',
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/tenants');
                        }),
                    _drawerTile(
                        context: context,
                        icon: Icons.local_shipping,
                        label: 'Fornecedores',
                        color: Colors.brown,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/suppliers');
                        }),
                  ],

                  if (role == 'FARM_OWNER' || role == 'CLIENT') ...[
                    const _DrawerSection('Operacional'),
                    _drawerTile(
                        context: context,
                        icon: Icons.water,
                        label: 'Tanques',
                        color: Colors.cyan,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/tanks');
                        }),
                    _drawerTile(
                        context: context,
                        icon: Icons.science,
                        label: 'Qualidade da Água',
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/water-quality');
                        }),
                    _drawerTile(
                        context: context,
                        icon: Icons.inventory,
                        label: 'Estoque',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/inventory');
                        }),
                    _drawerTile(
                        context: context,
                        icon: Icons.agriculture,
                        label: 'Colheitas',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/harvests');
                        }),
                  ],

                  if (role == 'FARM_OWNER') ...[
                    const _DrawerSection('Gestão'),
                    _drawerTile(
                        context: context,
                        icon: Icons.build,
                        label: 'Manutenção',
                        color: Colors.grey,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/maintenance');
                        }),
                    _drawerTile(
                        context: context,
                        icon: Icons.attach_money,
                        label: 'Finanças',
                        color: Colors.green.shade700,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/finances');
                        }),
                  ],
                ],
              ),
            ),

            Divider(color: Colors.white12),
            // Logout
            _drawerTile(
              context: context,
              icon: Icons.logout,
              label: 'Sair',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                ref.read(authNotifierProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  const _DrawerSection(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }
}
