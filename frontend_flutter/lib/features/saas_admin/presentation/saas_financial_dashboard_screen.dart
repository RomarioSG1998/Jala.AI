import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_repository.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:intl/intl.dart';

class SaasFinancialDashboardScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const SaasFinancialDashboardScreen({super.key, this.embedded = false});

  @override
  ConsumerState<SaasFinancialDashboardScreen> createState() => _SaasFinancialDashboardScreenState();
}

class _SaasFinancialDashboardScreenState extends ConsumerState<SaasFinancialDashboardScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'USER_ACTIVE', 'USER_DISABLED', 'PAST_DUE', 'FREE'

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
          padding: const EdgeInsets.all(16),
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
                                fontSize: 11,
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

                    // Main Revenue Cards Layout (Responsive Grid/Row)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        if (isMobile) {
                          return Column(
                            children: [
                              _kpiCard(
                                context,
                                label: 'MRR (Receita Recorrente Mensal)',
                                value: currencyFmt.format(overview.estimatedMRR),
                                icon: Icons.trending_up_rounded,
                                color: const Color(0xFF13A538),
                                subtitle: 'Assinaturas ativas no Stripe',
                              ),
                              const SizedBox(height: 10),
                              _kpiCard(
                                context,
                                label: 'ARR (Receita Anual Estimada)',
                                value: currencyFmt.format(overview.estimatedARR),
                                icon: Icons.auto_graph_rounded,
                                color: Colors.blueAccent,
                                subtitle: 'Projeção (MRR x 12)',
                              ),
                            ],
                          );
                        }
                        return Row(
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
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Status Breakdown Row (Responsive)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        if (isMobile) {
                          return Column(
                            children: [
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
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _kpiCard(
                                      context,
                                      label: 'Em Atraso',
                                      value: '${overview.pastDueTenantsCount}',
                                      icon: Icons.warning_amber_rounded,
                                      color: Colors.redAccent,
                                      small: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _kpiCard(
                                context,
                                label: 'Plano Gratuito',
                                value: '${overview.freeTenantsCount}',
                                icon: Icons.card_giftcard_rounded,
                                color: Colors.purple,
                                small: true,
                              ),
                            ],
                          );
                        }
                        return Row(
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
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF13A538)))),
              error: (e, _) => Text('Erro ao carregar KPIs: $e', style: const TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 24),

            // ── Financial Situation per Customer ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Situação Financeira dos Clientes',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
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
                  _filterChip('Ativos', 'USER_ACTIVE', const Color(0xFF13A538)),
                  const SizedBox(width: 8),
                  _filterChip('Desativados', 'USER_DISABLED', Colors.redAccent),
                  const SizedBox(width: 8),
                  _filterChip('Inadimplentes', 'PAST_DUE', Colors.orange),
                  const SizedBox(width: 8),
                  _filterChip('Gratuitos', 'FREE', Colors.purple),
                ],
              ),
            ),
            const SizedBox(height: 16),

            financialReportAsync.when(
              data: (report) {
                final filtered = report.where((r) {
                  if (_selectedFilter == 'USER_ACTIVE') return r.userActive;
                  if (_selectedFilter == 'USER_DISABLED') return !r.userActive;
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
                  children: filtered.map((tenantStatus) => _ExpandableFinancialCard(item: tenantStatus, currencyFmt: currencyFmt)).toList(),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF13A538)))),
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
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF13A538)))),
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
      padding: EdgeInsets.all(small ? 14 : 16),
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
                  fontSize: small ? 18 : 22,
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

class _ExpandableFinancialCard extends ConsumerStatefulWidget {
  final TenantFinancialStatus item;
  final NumberFormat currencyFmt;

  const _ExpandableFinancialCard({required this.item, required this.currencyFmt});

  @override
  ConsumerState<_ExpandableFinancialCard> createState() => _ExpandableFinancialCardState();
}

class _ExpandableFinancialCardState extends ConsumerState<_ExpandableFinancialCard> {
  bool _isExpanded = false;
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final currencyFmt = widget.currencyFmt;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeColor;
    String statusText;

    if (!item.userActive) {
      badgeColor = Colors.redAccent;
      statusText = 'DESATIVADO';
    } else {
      switch (item.status.toUpperCase()) {
        case 'ACTIVE':
        case 'PAID':
          badgeColor = const Color(0xFF13A538);
          statusText = 'EM DIA';
          break;
        case 'PAST_DUE':
        case 'UNPAID':
          badgeColor = Colors.orange;
          statusText = 'INADIMPLENTE';
          break;
        case 'FREE':
          badgeColor = Colors.purple;
          statusText = 'GRATUITO';
          break;
        default:
          badgeColor = Colors.grey;
          statusText = item.status.toUpperCase();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF263350) : Colors.grey.shade200),
      ),
      child: ExpansionTile(
        key: PageStorageKey(item.farmId),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (val) => setState(() => _isExpanded = val),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: badgeColor.withOpacity(0.15),
          child: Icon(
            item.userActive ? Icons.business : Icons.block,
            color: badgeColor,
            size: 20,
          ),
        ),
        title: Text(
          item.farmName,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          'Plano: ${item.planName} · ${currencyFmt.format(item.priceMonthly)}/mês',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.black54),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('CNPJ:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                    Text(item.cnpj.isNotEmpty ? item.cnpj : 'Não informado', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status da Conta:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                    Text(item.userActive ? 'Conta Ativa' : 'Acesso Bloqueado',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item.userActive ? Colors.green : Colors.red)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stripe Customer ID:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                    Text(item.stripeCustomerId ?? 'N/A', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.userActive ? Colors.redAccent : const Color(0xFF13A538),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isToggling
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Icon(item.userActive ? Icons.block : Icons.check_circle, size: 18),
                    label: Text(_isToggling
                        ? 'Processando...'
                        : (item.userActive ? 'Bloquear Acesso do Cliente' : 'Reativar Acesso do Cliente')),
                    onPressed: _isToggling
                        ? null
                        : () async {
                            setState(() => _isToggling = true);
                            final repo = ref.read(saasAdminRepositoryProvider);
                            final targetId = item.ownerId ?? item.farmId;
                            final success = await repo.toggleUserActiveStatus(targetId);
                            if (mounted) {
                              setState(() => _isToggling = false);
                              if (success) {
                                ref.invalidate(tenantsFinancialReportProvider);
                                ref.invalidate(masterOverviewProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Status do cliente ${item.farmName} atualizado com sucesso!')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Falha ao alterar status do cliente.')),
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
