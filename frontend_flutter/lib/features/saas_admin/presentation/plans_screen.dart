import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/features/saas_admin/data/plans_repository.dart';

const _kGreen = Color(0xFF13A538);
const _kNavy = Color(0xFF003366);
const _kNeon = Color(0xFF00FF66);

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansDetailProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Planos & Assinaturas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(plansDetailProvider.notifier).refresh(),
        child: plansAsync.when(
          data: (plans) => _buildContent(context, ref, plans, isDark, currencyFmt),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Erro: $e', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(plansDetailProvider.notifier).refresh(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<SaasPlanDetail> plans,
    bool isDark,
    NumberFormat fmt,
  ) {
    // KPIs
    final totalActive = plans.fold<int>(0, (s, p) => s + p.activeSubscribers);
    final totalMrr = plans.fold<double>(
        0, (s, p) => s + (p.priceMonthly * p.activeSubscribers));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        // ── Header Banner ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kNavy, Color(0xFF1A5276)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _kNavy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('GESTÃO DE PLANOS',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Crie, edite e controle\nos planos da plataforma.',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.layers_rounded, color: Colors.white, size: 32),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // ── KPI Row ──────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _kpiCard(context, 'Assinantes Ativos', '$totalActive', Icons.people_alt_rounded, Colors.green, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _kpiCard(context, 'MRR Real', fmt.format(totalMrr), Icons.trending_up_rounded, Colors.purple, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _kpiCard(context, 'Planos', '${plans.length}/3', Icons.layers_rounded, Colors.blue, isDark)),
        ]),

        const SizedBox(height: 28),

        // ── Section Title + Add Button ────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Planos Disponíveis',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 17, fontWeight: FontWeight.bold)),
          if (plans.length < 3)
            _addButton(context, ref, isDark),
        ]),

        const SizedBox(height: 4),
        Text(
          plans.length >= 3 ? 'Limite de 3 planos atingido.' : '${3 - plans.length} slot(s) disponível(is)',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12),
        ),

        const SizedBox(height: 16),

        // ── Plan Cards ────────────────────────────────────────────────────
        if (plans.isEmpty)
          _emptyState(context, isDark)
        else
          ...plans.asMap().entries.map((e) => _planCard(context, ref, e.value, e.key, isDark, fmt)),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _kpiCard(BuildContext context, String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF263350) : color.withOpacity(0.2)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 10)),
      ]),
    );
  }

  Widget _addButton(BuildContext context, WidgetRef ref, bool isDark) {
    return GestureDetector(
      onTap: () => _showPlanModal(context, ref, null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_kGreen, Color(0xFF0DA832)]),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: const Row(children: [
          Icon(Icons.add_rounded, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text('Novo Plano', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _emptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF263350) : Colors.grey.shade200),
      ),
      child: Column(children: [
        Icon(Icons.layers_outlined, size: 56, color: isDark ? Colors.grey.shade600 : Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Nenhum plano criado', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 4),
        Text('Crie até 3 planos para seus clientes.', style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade500, fontSize: 12)),
      ]),
    );
  }

  Widget _planCard(BuildContext context, WidgetRef ref, SaasPlanDetail plan, int index, bool isDark, NumberFormat fmt) {
    final colors = [const Color(0xFF3B82F6), _kGreen, const Color(0xFF8B5CF6)];
    final gradients = [
      [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)],
      [_kNavy, _kGreen],
      [const Color(0xFF5B21B6), const Color(0xFF8B5CF6)],
    ];
    final accentColor = colors[index % 3];
    final gradientColors = gradients[index % 3];

    final isFree = plan.priceMonthly == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF263350) : accentColor.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(isDark ? 0.1 : 0.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        // Gradient header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text('PLANO ${index + 1} DE 3',
                      style: const TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(plan.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                isFree
                    ? const Text('Gratuito', style: TextStyle(color: Colors.white70, fontSize: 14))
                    : Text(fmt.format(plan.priceMonthly) + '/mês',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                if (plan.stripeProductId != null && plan.stripeProductId!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.amber.shade900.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: Colors.amber, size: 12),
                        const SizedBox(width: 4),
                        Text('ID do Produto: ${plan.stripeProductId}', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
            Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('${plan.activeSubscribers} ativo(s)',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ),

        // Body: limits + actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Benefits row
            Row(children: [
              _benefit(context, Icons.water_drop_rounded, '${plan.maxTanks} tanques', accentColor, isDark),
              const SizedBox(width: 10),
              _benefit(context, Icons.people_rounded, '${plan.maxUsers} usuários', accentColor, isDark),
              const SizedBox(width: 10),
              _benefit(context, Icons.subscriptions_rounded, '${plan.totalSubscribers} total', accentColor, isDark),
            ]),
            const SizedBox(height: 14),
            // Action buttons
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPlanModal(context, ref, plan),
                  icon: Icon(Icons.edit_outlined, size: 14, color: accentColor),
                  label: Text('Editar', style: TextStyle(color: accentColor, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: accentColor.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: plan.activeSubscribers > 0
                      ? null
                      : () => _confirmDelete(context, ref, plan),
                  icon: Icon(Icons.delete_outline, size: 14, color: plan.activeSubscribers > 0 ? Colors.grey : Colors.red),
                  label: Text(
                    plan.activeSubscribers > 0 ? 'Em uso' : 'Excluir',
                    style: TextStyle(color: plan.activeSubscribers > 0 ? Colors.grey : Colors.red, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: plan.activeSubscribers > 0 ? Colors.grey.withOpacity(0.3) : Colors.red.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _benefit(BuildContext context, IconData icon, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 10, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── Modals ──────────────────────────────────────────────────────────────────

  static void _showPlanModal(BuildContext context, WidgetRef ref, SaasPlanDetail? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _PlanForm(existing: existing),
      ),
    );
  }

  static void _confirmDelete(BuildContext context, WidgetRef ref, SaasPlanDetail plan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Plano'),
        content: Text('Tem certeza que deseja excluir o plano "${plan.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final err = await ref.read(plansDetailProvider.notifier).deletePlan(plan.id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $err'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Plan Form (Create / Edit) ───────────────────────────────────────────────

class _PlanForm extends ConsumerStatefulWidget {
  final SaasPlanDetail? existing;
  const _PlanForm({this.existing});

  @override
  ConsumerState<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends ConsumerState<_PlanForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _tanks;
  late final TextEditingController _users;
  late final TextEditingController _price;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _tanks = TextEditingController(text: p != null ? '${p.maxTanks}' : '');
    _users = TextEditingController(text: p != null ? '${p.maxUsers}' : '');
    _price = TextEditingController(text: p != null ? p.priceMonthly.toStringAsFixed(2) : '');
  }

  @override
  void dispose() {
    _name.dispose(); _tanks.dispose(); _users.dispose(); _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(plansDetailProvider.notifier);
    final isEdit = widget.existing != null;

    String? err;
    if (isEdit) {
      err = await notifier.updatePlan(
        id: widget.existing!.id,
        name: _name.text.trim(),
        maxTanks: int.parse(_tanks.text.trim()),
        maxUsers: int.parse(_users.text.trim()),
        priceMonthly: double.parse(_price.text.trim().replaceAll(',', '.')),
      );
    } else {
      err = await notifier.createPlan(
        name: _name.text.trim(),
        maxTanks: int.parse(_tanks.text.trim()),
        maxUsers: int.parse(_users.text.trim()),
        priceMonthly: double.parse(_price.text.trim().replaceAll(',', '.')),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $err'), backgroundColor: Colors.red));
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(isEdit ? 'Editar Plano' : 'Criar Novo Plano',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(isEdit ? 'Atualize as configurações do plano.' : 'Defina nome, limites e preço do novo plano.',
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 24),

          _field(_name, 'Nome do Plano', 'Ex: Starter, Pro, Enterprise', null, null, isDark),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_tanks, 'Máx. Tanques', 'Ex: 10', FilteringTextInputFormatter.digitsOnly, TextInputType.number, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _field(_users, 'Máx. Usuários', 'Ex: 5', FilteringTextInputFormatter.digitsOnly, TextInputType.number, isDark)),
          ]),
          const SizedBox(height: 12),
          _field(
            _price, 'Preço Mensal (R\$)', 'Ex: 49.90',
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            const TextInputType.numberWithOptions(decimal: true),
            isDark,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Obrigatório';
              final parsed = double.tryParse(v.replaceAll(',', '.'));
              if (parsed == null || parsed < 0) return 'Valor inválido';
              return null;
            },
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEdit ? 'Salvar Alterações' : 'Criar Plano', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ]),
      ),
    ),
  );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint,
    TextInputFormatter? fmt,
    TextInputType? type,
    bool isDark, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      inputFormatters: [if (fmt != null) fmt],
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF263350) : Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
    );
  }
}
