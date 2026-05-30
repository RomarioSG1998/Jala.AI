import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:intl/intl.dart';

class SaasDashboardScreen extends ConsumerWidget {
  final bool embedded;
  const SaasDashboardScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final tenantsAsync = ref.watch(tenantsProvider);

    // Compute MRR from plans (sum of all plan prices × known tenants)
    // In reality, MRR = sum of active subscription values.
    // Here we approximate from plan prices as a demonstration.
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: embedded
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              title: const Text('Dashboard SaaS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(plansProvider);
          ref.invalidate(tenantsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── KPI Header Cards ──────────────────────────────────────
            tenantsAsync.when(
              data: (tenants) {
                return plansAsync.when(
                  data: (plans) {
                    final totalMrr = plans.fold<double>(
                        0, (sum, p) => sum + p.priceMonthly);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Visão Geral',
                            style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _kpiCard(
                                context,
                                label: 'Tenants Ativos',
                                value: '${tenants.length}',
                                icon: Icons.business,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kpiCard(
                                context,
                                label: 'Planos Oferecidos',
                                value: '${plans.length}',
                                icon: Icons.layers,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _kpiCard(
                          context,
                          label: 'MRR Total (Catálogo de Planos)',
                          value: currencyFmt.format(totalMrr),
                          icon: Icons.trending_up,
                          color: Colors.green,
                          wide: true,
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Text('Erro: $e', style: const TextStyle(color: Colors.red)),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Erro: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 28),

            // ── Plans Catalog ────────────────────────────────────────
            Text('Catálogo de Planos SaaS',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            plansAsync.when(
              data: (plans) => Column(
                children: plans.map((plan) => _planCard(context, plan, currencyFmt)).toList(),
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Erro: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 28),

            // ── Tenant List ──────────────────────────────────────────
            Text('Clientes (Tenants) Registrados',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            tenantsAsync.when(
              data: (tenants) {
                if (tenants.isEmpty) {
                  return Center(
                    child: Text('Nenhum tenant encontrado.',
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54)),
                  );
                }
                return Column(
                  children:
                      tenants.map((t) => _tenantCard(context, t)).toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Erro: $e', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool wide = false,
  }) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF263350) : color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _planCard(BuildContext context, plan, NumberFormat currencyFmt) {
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green];
    final color = colors[plan.name.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF263350) : color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name,
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    '${plan.maxTanks} tanques · ${plan.maxUsers} usuários',
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45, fontSize: 12)),
              ],
            ),
          ),
          Text(
            currencyFmt.format(plan.priceMonthly),
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ignore: avoid_annotating_with_dynamic
  Widget _tenantCard(BuildContext context, dynamic tenant) {
    String formatted = '';
    try {
      final dt = DateTime.parse(tenant.createdAt);
      formatted = DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      formatted = tenant.createdAt;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF263350) : Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.withOpacity(0.2),
            radius: 24,
            child: const Icon(Icons.business, color: Colors.indigo, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tenant.name,
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 4),
                if (tenant.cnpj.isNotEmpty)
                  Text('CNPJ: ${tenant.cnpj}',
                      style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Ativo',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              if (formatted.isNotEmpty)
                Text(formatted,
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
