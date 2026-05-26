import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/tanks/presentation/widgets/tank_card.dart';
import 'package:frontend_flutter/features/tanks/data/tank_model.dart';
import 'package:frontend_flutter/features/dashboard/providers/farm_summary_provider.dart';
import 'package:frontend_flutter/features/dashboard/data/farm_summary_model.dart';

class TanksScreen extends ConsumerStatefulWidget {
  const TanksScreen({super.key});

  static void showAddTankModal(BuildContext context) {
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
  ConsumerState<TanksScreen> createState() => _TanksScreenState();
}

class _TanksScreenState extends ConsumerState<TanksScreen> {
  String _activeFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _refreshData() async {
    await ref.read(tanksProvider.notifier).refreshTanks();
    ref.invalidate(farmSummaryProvider);
  }



  @override
  Widget build(BuildContext context) {
    final tanksAsyncValue = ref.watch(tanksProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState.accountType == 'FARM_OWNER' || authState.accountType == 'CLIENT';

    final summaryAsyncValue = ref.watch(farmSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Fundo Gelo
      
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: CustomScrollView(
            slivers: [
              // Cabeçalho e KPIs (SliverToBoxAdapter)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSectionTitle(context, ref, isOwner),
                    tanksAsyncValue.when(
                      data: (tanks) => _buildMetricsPanel(tanks, summaryAsyncValue),
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
                    final isTankActive = t.status == 'ACTIVE';
                    if (_activeFilter == 'Ativos') return isTankActive;
                    if (_activeFilter == 'Inativos') return !isTankActive;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(
                        message: 'Nenhum tanque encontrado para o filtro selecionado',
                      ),
                    );
                  }
 
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final tank = filtered[index];
                          
                          return TankCard(
                            tank: tank,
                            isActive: tank.status == 'ACTIVE',
                            onTap: () {
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
                                  child: EditTankForm(tank: tank),
                                ),
                              );
                            },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, _) => SliverToBoxAdapter(
                  child: _buildErrorState(e.toString()),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)), // Espaço para FAB central
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Tanques', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Gerencie todos os tanques da sua criação',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13A538),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => TanksScreen.showAddTankModal(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 22),
                tooltip: 'Novo tanque',
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsPanel(List<Tank> tanks, AsyncValue<FarmSummary> summaryAsync) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: SizedBox(
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            summaryAsync.maybeWhen(
              data: (summary) => _kpiCard(Icons.water, 'Tanques ativos', '${summary.activeTanks} de ${summary.totalTanks}', Colors.blue, summary.totalTanks > 0 ? (summary.activeTanks / summary.totalTanks) : 0.0),
              orElse: () => _kpiCard(Icons.water, 'Tanques ativos', '${tanks.length} de --', Colors.blue, 0.5),
            ),
            summaryAsync.maybeWhen(
              data: (summary) => _kpiCard(Icons.set_meal, 'Peixes totais', '${summary.totalFishCapacity}', Colors.green, null, subtitle: 'Capacidade total'),
              orElse: () => _kpiCard(Icons.set_meal, 'Peixes totais', '--', Colors.green, null, subtitle: 'Capacidade total'),
            ),
            summaryAsync.maybeWhen(
              data: (summary) => _kpiCard(Icons.shopping_bag, 'Ração hoje', '${summary.feedingTodayKg.toStringAsFixed(1)} kg', Colors.orange, null, subtitle: 'Total alimentado'),
              orElse: () => _kpiCard(Icons.shopping_bag, 'Ração hoje', '--', Colors.orange, null, subtitle: 'Total alimentado'),
            ),
            () {
              double totalWeight = 0;
              int count = 0;
              for (final t in tanks) {
                if (t.status == 'ACTIVE' && t.averageWeightG > 0) {
                  totalWeight += t.averageWeightG;
                  count++;
                }
              }
              final avgWeight = count > 0 ? totalWeight / count : 0.0;
              final progress = (avgWeight / 1000.0).clamp(0.0, 1.0);
              return _kpiCard(
                Icons.show_chart,
                'Crescimento',
                count > 0 ? '${avgWeight.toInt()} g' : '--',
                Colors.purple,
                progress,
                subtitle: 'Peso médio',
              );
            }(),
            () {
              int totalCapacity = 0;
              int totalMortality = 0;
              for (final t in tanks) {
                if (t.status == 'ACTIVE') {
                  totalCapacity += t.fishCapacity;
                  totalMortality += t.mortalityCount;
                }
              }
              final progress = totalCapacity > 0 ? (totalMortality / totalCapacity).clamp(0.0, 1.0) : 0.0;
              return _kpiCard(
                Icons.warning,
                'Mortalidade',
                '$totalMortality peixes',
                Colors.red,
                progress,
                subtitle: 'Mortalidade total',
              );
            }(),
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

  Widget _buildEmptyState({String message = 'Nenhum tanque encontrado'}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.water, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(message, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Nao foi possivel carregar os tanques',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF13A538),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar novamente'),
            ),
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

// ─── Componente EditTankForm ───

class EditTankForm extends ConsumerStatefulWidget {
  final Tank tank;
  const EditTankForm({super.key, required this.tank});

  @override
  ConsumerState<EditTankForm> createState() => _EditTankFormState();
}

class _EditTankFormState extends ConsumerState<EditTankForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _capacityController;
  late TextEditingController _weightController;
  late TextEditingController _mortalityController;
  late TextEditingController _harvestDateController;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tank.name);
    _speciesController = TextEditingController(text: widget.tank.fishSpecies);
    _capacityController = TextEditingController(text: widget.tank.fishCapacity.toString());
    _weightController = TextEditingController(text: widget.tank.averageWeightG.toString());
    _mortalityController = TextEditingController(text: widget.tank.mortalityCount.toString());
    _harvestDateController = TextEditingController(text: widget.tank.nextHarvestDate ?? '');
    _status = widget.tank.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _capacityController.dispose();
    _weightController.dispose();
    _mortalityController.dispose();
    _harvestDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    if (_harvestDateController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_harvestDateController.text);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _harvestDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    final success = await ref.read(tanksProvider.notifier).updateTank(
          widget.tank.id,
          _nameController.text.trim(),
          _speciesController.text.trim(),
          int.parse(_capacityController.text.trim()),
          int.parse(_weightController.text.trim()),
          int.parse(_mortalityController.text.trim()),
          _harvestDateController.text.isEmpty ? null : _harvestDateController.text,
          _status,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ref.invalidate(farmSummaryProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanque atualizado com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar tanque')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Tanque'),
        content: Text('Deseja realmente excluir o tanque "${widget.tank.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      final success = await ref.read(tanksProvider.notifier).deleteTank(widget.tank.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ref.invalidate(farmSummaryProvider);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tanque excluído com sucesso!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao excluir tanque')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState.accountType == 'FARM_OWNER' || authState.accountType == 'CLIENT';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Editar Tanque', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  if (isOwner)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _isLoading ? null : _delete,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome do Tanque', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(labelText: 'Espécie de Peixe', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacidade', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (int.tryParse(v) == null ? 'Deve ser um número' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Peso Médio (g)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (int.tryParse(v) == null ? 'Deve ser um número' : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mortalityController,
                decoration: const InputDecoration(labelText: 'Mortalidade', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : (int.tryParse(v) == null ? 'Deve ser um número' : null),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _harvestDateController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Data de Despesca',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      onTap: _selectDate,
                    ),
                  ),
                  if (_harvestDateController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _harvestDateController.clear()),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Ativo')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inativo')),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13A538),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
