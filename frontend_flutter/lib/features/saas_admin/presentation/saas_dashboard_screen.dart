import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:intl/intl.dart';

class SaasDashboardScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const SaasDashboardScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SaasDashboardScreen> createState() => _SaasDashboardScreenState();
}

class _SaasDashboardScreenState extends ConsumerState<SaasDashboardScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'ACTIVE', 'PAST_DUE', 'FREE'

  @override
  Widget build(BuildContext context) {
    final masterOverviewAsync = ref.watch(masterOverviewProvider);
    final financialReportAsync = ref.watch(tenantsFinancialReportProvider);
    final plansAsync = ref.watch(plansProvider);
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              title: const Text('Dashboard Financeiro SaaS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(masterOverviewProvider);
          ref.invalidate(tenantsFinancialReportProvider);
          ref.invalidate(plansProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Header & KPI Cards ──────────────────────────────────────
            masterOverviewAsync.when(
              data: (overview) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('SAÚDE FINANCEIRA DO SAAS (STRIPE SYNC)',
                            style: TextStyle(
                                color: isDark ? Colors.grey.shade400 : Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF13A538).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync, color: Color(0xFF13A538), size: 14),
                              SizedBox(width: 4),
                              Text('Conectado', style: TextStyle(color: Color(0xFF13A538), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Main Revenue Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            context,
                            label: 'MRR (Receita Recorrente Mensal)',
                            value: currencyFmt.format(overview.estimatedMRR),
                            icon: Icons.trending_up_rounded,
                            color: const Color(0xFF13A538),
                            subtitle: 'Assinaturas ativas no Stripe',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _kpiCard(
                            context,
                            label: 'ARR (Receita Anual Estimada)',
                            value: currencyFmt.format(overview.estimatedARR),
                            icon: Icons.auto_graph_rounded,
                            color: Colors.blueAccent,
                            subtitle: 'Projeção (MRR x 12)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Breakdown Row
                    Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            context,
                            label: 'Clientes Em Dia',
                            value: '${overview.upToDateTenantsCount}',
                            icon: Icons.check_circle_rounded,
                            color: Colors.green,
                            small: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _kpiCard(
                            context,
                            label: 'Em Atraso / Pendentes',
                            value: '${overview.pastDueTenantsCount}',
                            icon: Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            small: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _kpiCard(
                            context,
                            label: 'Plano Gratuito',
                            value: '${overview.freeTenantsCount}',
                            icon: Icons.card_giftcard_rounded,
                            color: Colors.purple,
                            small: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF13A538))),
              error: (e, _) => Text('Erro ao carregar KPIs: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 28),

            // ── Financial Situation per Customer ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Situação Financeira dos Clientes',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Atualizar Relatório',
                  onPressed: () {
                    ref.invalidate(tenantsFinancialReportProvider);
                    ref.invalidate(masterOverviewProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Todos', 'ALL', Colors.blue),
                  const SizedBox(width: 8),
                  _filterChip('Em Dia (Ativos)', 'ACTIVE', Colors.green),
                  const SizedBox(width: 8),
                  _filterChip('Em Atraso / Inadimplentes', 'PAST_DUE', Colors.redAccent),
                  const SizedBox(width: 8),
                  _filterChip('Gratuitos', 'FREE', Colors.purple),
                ],
              ),
            ),
            const SizedBox(height: 16),

            financialReportAsync.when(
              data: (report) {
                final filtered = report.where((r) {
                  if (_selectedFilter == 'ACTIVE') return r.status == 'ACTIVE';
                  if (_selectedFilter == 'PAST_DUE') return r.status == 'PAST_DUE' || r.status == 'UNPAID' || r.status == 'PENDING_PAYMENT';
                  if (_selectedFilter == 'FREE') return r.status == 'FREE';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Nenhum cliente encontrado para o filtro selecionado.',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((tenantStatus) => _tenantFinancialCard(context, tenantStatus, currencyFmt)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF13A538))),
              error: (e, _) => Text('Erro ao carregar relatório financeiro: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 28),

            // ── Plans Catalog Overview ────────────────────────────────
            Text('Planos Cadastrados no SaaS',
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            plansAsync.when(
              data: (plans) => Column(
                children: plans.map((plan) => _planCard(context, plan, currencyFmt)).toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF13A538))),
              error: (e, _) => Text('Erro: $e', style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.bold, fontSize: 12)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.12),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    bool small = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(small ? 14 : 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF263350) : color.withOpacity(0.25), width: 1),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: color.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(small ? 6 : 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: small ? 18 : 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.black54,
                        fontSize: small ? 11 : 12,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          SizedBox(height: small ? 8 : 12),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: small ? 20 : 24,
                  fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  Widget _tenantFinancialCard(BuildContext context, TenantFinancialStatus item, NumberFormat currencyFmt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info_outline;

    switch (item.status) {
      case 'ACTIVE':
        statusColor = const Color(0xFF13A538);
        statusIcon = Icons.check_circle;
        break;
      case 'PAST_DUE':
      case 'UNPAID':
        statusColor = Colors.redAccent;
        statusIcon = Icons.error;
        break;
      case 'PENDING_PAYMENT':
        statusColor = Colors.amber.shade800;
        statusIcon = Icons.hourglass_top;
        break;
      case 'FREE':
        statusColor = Colors.blue;
        statusIcon = Icons.card_giftcard;
        break;
      case 'CANCELLED':
      case 'CANCELED':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF263350) : statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Farm Name + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.15),
                      radius: 20,
                      child: Icon(Icons.business_rounded, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.farmName,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (item.cnpj.isNotEmpty)
                            Text('CNPJ: ${item.cnpj}',
                                style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      item.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),

          // Details Grid
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  context,
                  Icons.person,
                  'Responsável / E-mail',
                  item.ownerName,
                  subtitle: item.ownerEmail,
                ),
              ),
              Expanded(
                child: _detailTile(
                  context,
                  Icons.layers,
                  'Plano Assinado',
                  item.planName,
                  subtitle: item.priceMonthly > 0 ? '${currencyFmt.format(item.priceMonthly)}/mês' : 'Sem cobrança',
                  highlightColor: item.priceMonthly > 0 ? const Color(0xFF13A538) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _detailTile(
                  context,
                  Icons.calendar_month,
                  'Próximo Vencimento',
                  item.nextBillingDate ?? 'N/A',
                ),
              ),
              Expanded(
                child: _detailTile(
                  context,
                  Icons.payment,
                  'Forma de Pagamento',
                  item.paymentMethodType,
                ),
              ),
            ],
          ),

          // Optional Stripe IDs for Admin Debugging
          if (item.stripeCustomerId != null || item.stripeSubscriptionId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Stripe Sync: Customer ${item.stripeCustomerId ?? "N/A"} | Sub ${item.stripeSubscriptionId ?? "N/A"}',
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailTile(BuildContext context, IconData icon, String label, String value, {String? subtitle, Color? highlightColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.black45),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 10)),
              Text(
                value,
                style: TextStyle(
                  color: highlightColor ?? (isDark ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _planCard(BuildContext context, SaasPlan plan, NumberFormat currencyFmt) {
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green];
    final color = colors[plan.name.hashCode.abs() % colors.length];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF263350) : color.withOpacity(0.25)),
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
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    '${plan.maxTanks} tanques · ${plan.maxUsers} usuários',
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontSize: 12)),
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
}
