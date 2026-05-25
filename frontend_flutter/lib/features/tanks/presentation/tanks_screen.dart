import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/tanks/presentation/widgets/tank_card.dart';

class TanksScreen extends ConsumerStatefulWidget {
  const TanksScreen({super.key});

  @override
  ConsumerState<TanksScreen> createState() => _TanksScreenState();
}

class _TanksScreenState extends ConsumerState<TanksScreen> {
  String _activeFilter = 'Todos';

  void _showAddTankModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const AddTankForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsyncValue = ref.watch(tanksProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState.accountType == 'FARM_OWNER';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Fundo Gelo
      
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(tanksProvider.notifier).refreshTanks(),
          child: CustomScrollView(
            slivers: [
              // Cabeçalho e KPIs (SliverToBoxAdapter)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSectionTitle(context, ref, isOwner),
                    tanksAsyncValue.when(
                      data: (tanks) => _buildMetricsPanel(tanks),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('Erro: $e', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                    _buildFilterBar(),
                  ],
                ),
              ),

              // Lista de Tanques
              tanksAsyncValue.when(
                data: (tanks) {
                  if (tanks.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  // Filtro local simples baseado na String "Inativo" no nome, 
                  // já que o modelo real ainda não tem campo "status".
                  // Vamos assumir que todos são ativos, exceto se houver lógica.
                  // Para demonstração visual, se o nome contiver "inativo", é inativo.
                  var filtered = tanks.where((t) {
                    if (_activeFilter == 'Todos') return true;
                    final isTankActive = !t.name.toLowerCase().contains('inativ');
                    if (_activeFilter == 'Ativos') return isTankActive;
                    if (_activeFilter == 'Inativos') return !isTankActive;
                    return true;
                  }).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tank = filtered[index];
                          final isTankActive = !tank.name.toLowerCase().contains('inativ');
                          
                          return TankCard(
                            tank: tank,
                            isActive: isTankActive,
                            onTap: () {
                              // Navegar para detalhes
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Espaço para FAB central
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, WidgetRef ref, bool isOwner) {
    return Container(
      color: const Color(0xFF003366),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Tanques', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Gerencie todos os tanques da sua criação', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          if (isOwner)
            ElevatedButton.icon(
              onPressed: () => _showAddTankModal(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF13A538), // Verde Principal
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo tanque', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsPanel(List<dynamic> tanks) {
    // Mocks visuais para o design
    return Transform.translate(
      offset: const Offset(0, -10),
      child: SizedBox(
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _kpiCard(Icons.water, 'Tanques ativos', '${tanks.length} de 10', Colors.blue, 0.8),
            _kpiCard(Icons.set_meal, 'Peixes totais', '12.540', Colors.green, null, subtitle: '+3,2% este mês'),
            _kpiCard(Icons.shopping_bag, 'Ração hoje', '125 kg', Colors.orange, null, subtitle: 'Plan: 150 kg'),
            _kpiCard(Icons.show_chart, 'Crescimento', '2,35%', Colors.purple, 0.6, subtitle: 'Este mês'),
            _kpiCard(Icons.warning, 'Mortalidade', '1,25%', Colors.red, null, subtitle: 'Este mês'),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard(IconData icon, String title, String value, Color color, double? progress, {String? subtitle}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Spacer(),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress, backgroundColor: color.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4),
            )
          else if (subtitle != null)
            Text(subtitle, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterPill('Todos'),
                  _filterPill('Ativos'),
                  _filterPill('Inativos'),
                  _filterPill('Esvaziados'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black54, size: 20),
              onPressed: () {},
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPill(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF13A538) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.water, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nenhum tanque encontrado', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

}

// ─── Componente AddTankForm (MANTIDO INTACTO) ───

class AddTankForm extends ConsumerStatefulWidget {
  const AddTankForm({super.key});

  @override
  ConsumerState<AddTankForm> createState() => _AddTankFormState();
}

class _AddTankFormState extends ConsumerState<AddTankForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _capacityController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final success = await ref.read(tanksProvider.notifier).createTank(
          _nameController.text.trim(),
          _speciesController.text.trim(),
          int.parse(_capacityController.text.trim()),
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create tank')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add New Tank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tank Name', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _speciesController, decoration: const InputDecoration(labelText: 'Fish Species', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _capacityController, decoration: const InputDecoration(labelText: 'Capacity', border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : (int.tryParse(v) == null ? 'Must be a number' : null)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF13A538), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Create Tank'),
            ),
          ],
        ),
      ),
    );
  }
}
