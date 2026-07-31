import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/tanks/presentation/widgets/tank_card.dart';
import 'package:frontend_flutter/features/tanks/data/tank_model.dart';
import 'package:frontend_flutter/features/tanks/data/biometrics_model.dart';
import 'package:frontend_flutter/features/tanks/providers/biometrics_provider.dart';
import 'package:frontend_flutter/features/dashboard/providers/farm_summary_provider.dart';
import 'package:frontend_flutter/features/dashboard/data/farm_summary_model.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/profile/providers/subscription_provider.dart';
import 'package:frontend_flutter/features/tanks/presentation/upgrade_plan_screen.dart';
import 'package:frontend_flutter/features/tanks/data/tank_repository.dart';

class TanksScreen extends ConsumerStatefulWidget {
  const TanksScreen({super.key});

  static void showAddTankModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
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
    final searchQuery = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      
      body: SafeArea(
        bottom: false,
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
                  }).where((t) {
                    if (searchQuery.isEmpty) return true;
                    final nameMatch = t.name.toLowerCase().contains(searchQuery.toLowerCase());
                    final speciesMatch = t.fishSpecies.toLowerCase().contains(searchQuery.toLowerCase());
                    return nameMatch || speciesMatch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(
                        message: searchQuery.isNotEmpty
                            ? 'Nenhum tanque encontrado para "$searchQuery"'
                            : 'Nenhum tanque encontrado para o filtro selecionado',
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
                                useRootNavigator: true,
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
              
              const SliverToBoxAdapter(child: SizedBox(height: 110)), // Espaço para FAB central
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
        ],
      ),
    );
  }

  Widget _buildMetricsPanel(List<Tank> tanks, AsyncValue<FarmSummary> summaryAsync) {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: SizedBox(
        height: 105,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          children: [
            summaryAsync.maybeWhen(
              data: (summary) => _kpiCard(context, Icons.water, 'Tanques ativos', '${summary.activeTanks} de ${summary.totalTanks}', Colors.blue, summary.totalTanks > 0 ? (summary.activeTanks / summary.totalTanks) : 0.0),
              orElse: () => _kpiCard(context, Icons.water, 'Tanques ativos', '${tanks.length} de --', Colors.blue, 0.5),
            ),
            summaryAsync.maybeWhen(
              data: (summary) => _kpiCard(context, Icons.set_meal, 'Peixes totais', '${summary.totalFishCapacity}', Colors.green, null, subtitle: 'Capacidade total'),
              orElse: () => _kpiCard(context, Icons.set_meal, 'Peixes totais', '--', Colors.green, null, subtitle: 'Capacidade total'),
            ),
            summaryAsync.maybeWhen(
              data: (summary) => _kpiCard(context, Icons.shopping_bag, 'Ração hoje', '${summary.feedingTodayKg.toStringAsFixed(1)} kg', Colors.orange, null, subtitle: 'Total alimentado'),
              orElse: () => _kpiCard(context, Icons.shopping_bag, 'Ração hoje', '--', Colors.orange, null, subtitle: 'Total alimentado'),
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
                context,
                Icons.show_chart,
                'Crescimento',
                count > 0 ? '${avgWeight.toInt()} g' : '--',
                Colors.purple,
                progress,
                subtitle: 'Peso médio / Biometria',
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
                context,
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

  Widget _kpiCard(BuildContext context, IconData icon, String title, String value, Color color, double? progress, {String? subtitle}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: const Color(0xFF334155), width: 1.0) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 120,
          height: 89,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Expanded(child: Text(title, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade300 : Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
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
        ),
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
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF151D30) : Colors.grey.shade200,
              border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.black54, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFF13A538) 
              : (isDark ? const Color(0xFF151D30) : Colors.grey.shade200),
          border: !isActive && isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive 
                ? Colors.white 
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
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
  // Capacidade removida: usa initialStockingQty como contagem oficial
  final _stockingDateController = TextEditingController();
  final _initialStockingQtyController = TextEditingController();
  final _initialAverageWeightGController = TextEditingController();
  final _supplierController = TextEditingController();
  String? _customImageBase64;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _stockingDateController.dispose();
    _initialStockingQtyController.dispose();
    _initialAverageWeightGController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('AddTankForm: Início de _pickImage via ImagePicker...');
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        debugPrint('AddTankForm: Imagem selecionada com sucesso: ${bytes.length} bytes');
        setState(() {
          _customImageBase64 = base64Encode(bytes);
        });
      } else {
        debugPrint('AddTankForm: Seleção cancelada pelo usuário.');
      }
    } catch (e, stack) {
      debugPrint('AddTankForm: Erro ao selecionar imagem: $e\n$stack');
    }
  }

  Future<void> _selectStockingDate() async {
    DateTime initial = DateTime.now();
    if (_stockingDateController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_stockingDateController.text);
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
        _stockingDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final stockingQty = int.parse(_initialStockingQtyController.text.trim());
    final notifier = ref.read(tanksProvider.notifier);
    final success = await notifier.createTank(
          _nameController.text.trim(),
          _speciesController.text.trim(),
          stockingQty,
          stockingDate: _stockingDateController.text.isEmpty ? null : _stockingDateController.text,
          initialStockingQty: stockingQty,
          initialAverageWeightG: int.tryParse(_initialAverageWeightGController.text.trim()),
          supplier: _supplierController.text.isEmpty ? null : _supplierController.text.trim(),
          customImage: _customImageBase64,
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else if (notifier.lastPlanLimitError != null) {
        final err = notifier.lastPlanLimitError!;
        final router = GoRouter.of(context);
        final currentTanksCount = (ref.read(tanksProvider).value ?? []).length;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text('Limite do Plano Atingido', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Sua propriedade atingiu o limite máximo de ${err.maxAllowed} tanque(s) permitido(s) pelo seu plano atual.\n\n'
              'Faça o upgrade da sua assinatura para cadastrar mais tanques e liberar recursos ilimitados!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13A538),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pop();
                  router.push('/upgrade-plan?currentTanks=$currentTanksCount&maxAllowed=${err.maxAllowed}');
                },
                child: const Text('Ver Planos & Assinar 💳', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao criar tanque')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
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
                    const SizedBox(width: 48),
                    const Text('Adicionar Novo Tanque', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: _customImageBase64 != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(
                                  base64Decode(_customImageBase64!),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _customImageBase64 = null;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 40,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Adicionar Foto do Tanque (Opcional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome do Tanque', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 16),
                TextFormField(controller: _speciesController, decoration: const InputDecoration(labelText: 'Espécie de Peixe', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 16),
                // Quantidade de Povoamento: campo obrigatório, logo abaixo da espécie
                TextFormField(
                  controller: _initialStockingQtyController,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade de Povoamento',
                    hintText: 'Ex: 1000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.set_meal_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Obrigatório';
                    if (int.tryParse(v) == null) return 'Deve ser um número inteiro';
                    if (int.parse(v) <= 0) return 'Deve ser maior que zero';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockingDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Data de Povoamento',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectStockingDate,
                      ),
                    ),
                    if (_stockingDateController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _stockingDateController.clear()),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _initialAverageWeightGController,
                  decoration: const InputDecoration(labelText: 'Peso Médio Inicial (g) (Opcional)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isNotEmpty && int.tryParse(v) == null ? 'Deve ser um número inteiro' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _supplierController,
                  decoration: const InputDecoration(labelText: 'Fornecedor (Opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF13A538), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Criar Tanque'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
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
  // _capacityController removido: fishCapacity agora é derivado de initialStockingQty
  late TextEditingController _weightController;
  late TextEditingController _mortalityController;
  late TextEditingController _harvestDateController;
  late TextEditingController _stockingDateController;
  late TextEditingController _initialStockingQtyController;
  late TextEditingController _initialAverageWeightGController;
  late TextEditingController _supplierController;
  
  // Biometrics & tab state
  int _activeTab = 0;
  final _newWeightController = TextEditingController();
  late TextEditingController _newWeightDateController;

  late String _status;
  String? _customImageBase64;
  bool _clearImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tank.name);
    _speciesController = TextEditingController(text: widget.tank.fishSpecies);
    // Usa initialStockingQty como fonte de verdade; fallback para fishCapacity se vazio
    _weightController = TextEditingController(text: widget.tank.averageWeightG.toString());
    _mortalityController = TextEditingController(text: widget.tank.mortalityCount.toString());
    _harvestDateController = TextEditingController(text: widget.tank.nextHarvestDate ?? '');
    _stockingDateController = TextEditingController(text: widget.tank.stockingDate ?? '');
    final qty = widget.tank.initialStockingQty ?? widget.tank.fishCapacity;
    _initialStockingQtyController = TextEditingController(text: qty > 0 ? qty.toString() : '');
    _initialAverageWeightGController = TextEditingController(text: widget.tank.initialAverageWeightG?.toString() ?? '');
    _supplierController = TextEditingController(text: widget.tank.supplier ?? '');
    
    final today = DateTime.now();
    _newWeightDateController = TextEditingController(text: "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}");
    
    _status = widget.tank.status;
    _customImageBase64 = widget.tank.customImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _weightController.dispose();
    _mortalityController.dispose();
    _harvestDateController.dispose();
    _stockingDateController.dispose();
    _initialStockingQtyController.dispose();
    _initialAverageWeightGController.dispose();
    _supplierController.dispose();
    _newWeightController.dispose();
    _newWeightDateController.dispose();
    super.dispose();
  }

  Future<void> _selectNewWeightDate() async {
    DateTime initial = DateTime.now();
    if (_newWeightDateController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_newWeightDateController.text);
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
        _newWeightDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('EditTankForm: Início de _pickImage via ImagePicker...');
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        debugPrint('EditTankForm: Imagem selecionada com sucesso: ${bytes.length} bytes');
        setState(() {
          _customImageBase64 = base64Encode(bytes);
          _clearImage = false;
        });
      } else {
        debugPrint('EditTankForm: Seleção cancelada pelo usuário.');
      }
    } catch (e, stack) {
      debugPrint('EditTankForm: Erro ao selecionar imagem: $e\n$stack');
    }
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

  Future<void> _selectStockingDate() async {
    DateTime initial = DateTime.now();
    if (_stockingDateController.text.isNotEmpty) {
      try {
        initial = DateTime.parse(_stockingDateController.text);
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
        _stockingDateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    // fishCapacity = initialStockingQty para manter sincronização e evitar duplicação
    final stockingQty = int.tryParse(_initialStockingQtyController.text.trim()) ?? widget.tank.fishCapacity;
    final success = await ref.read(tanksProvider.notifier).updateTank(
          widget.tank.id,
          _nameController.text.trim(),
          _speciesController.text.trim(),
          stockingQty, // fishCapacity sincronizado com initialStockingQty
          int.parse(_weightController.text.trim()),
          int.parse(_mortalityController.text.trim()),
          _harvestDateController.text.isEmpty ? null : _harvestDateController.text,
          _stockingDateController.text.isEmpty ? null : _stockingDateController.text,
          _status,
          initialStockingQty: stockingQty,
          initialAverageWeightG: int.tryParse(_initialAverageWeightGController.text.trim()),
          supplier: _supplierController.text.isEmpty ? null : _supplierController.text.trim(),
          customImage: _customImageBase64,
          clearImage: _clearImage,
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
    final confirm = await PasswordConfirmationDialog.confirm(context, ref);

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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
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
                    Row(
                      children: [
                        if (isOwner)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: _isLoading ? null : _delete,
                          ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _activeTab == 0 ? Theme.of(context).primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: _activeTab == 0 ? Theme.of(context).primaryColor : Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Informações',
                                style: TextStyle(
                                  fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: _activeTab == 0 ? Theme.of(context).primaryColor : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _activeTab == 1 ? Theme.of(context).primaryColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.scale_outlined, size: 16, color: _activeTab == 1 ? Theme.of(context).primaryColor : Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Biometria',
                                style: TextStyle(
                                  fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: _activeTab == 1 ? Theme.of(context).primaryColor : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_activeTab == 0) ...[
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E293B)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: _customImageBase64 != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(
                                    base64Decode(_customImageBase64!),
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                        onPressed: () {
                                          setState(() {
                                            _customImageBase64 = null;
                                            _clearImage = true;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Alterar Foto do Tanque (Opcional)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  // Quantidade de Povoamento: obrigatório, logo abaixo da espécie
                  TextFormField(
                    controller: _initialStockingQtyController,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade de Povoamento',
                      hintText: 'Ex: 1000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.set_meal_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obrigatório';
                      if (int.tryParse(v) == null) return 'Deve ser um número inteiro';
                      if (int.parse(v) <= 0) return 'Deve ser maior que zero';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Peso Médio / Biometria (g)', border: OutlineInputBorder()),
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
                          controller: _stockingDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Data de Povoamento',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: _selectStockingDate,
                        ),
                      ),
                      if (_stockingDateController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _stockingDateController.clear()),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _initialAverageWeightGController,
                    decoration: const InputDecoration(labelText: 'Peso Médio Inicial (g) (Opcional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isNotEmpty && int.tryParse(v) == null ? 'Deve ser um número inteiro' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _supplierController,
                    decoration: const InputDecoration(labelText: 'Fornecedor (Opcional)', border: OutlineInputBorder()),
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
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
                  ),
                ] else ...[
                  // Biometrics Tab
                  Builder(
                    builder: (context) {
                      final biometricsAsync = ref.watch(biometricsProvider(widget.tank.id));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Registrar Nova Biometria',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _newWeightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Peso Médio (g)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _newWeightDateController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Data do Registro',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  onTap: _selectNewWeightDate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              if (_newWeightController.text.trim().isEmpty) return;
                              final weight = int.tryParse(_newWeightController.text.trim());
                              if (weight == null) return;
                              setState(() => _isLoading = true);
                              final success = await ref
                                  .read(biometricsProvider(widget.tank.id).notifier)
                                  .logBiometrics(weight, _newWeightDateController.text);
                              setState(() => _isLoading = false);
                              if (success) {
                                _newWeightController.clear();
                                // Refresh current tank weight field state
                                setState(() {
                                  _weightController.text = weight.toString();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Biometria registrada com sucesso!')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Registrar'),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Histórico de Medições',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          biometricsAsync.when(
                            data: (records) {
                              if (records.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    'Nenhuma biometria registrada para este tanque ainda.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: records.length,
                                itemBuilder: (context, index) {
                                  final record = records[index];
                                  
                                  String growthText = '';
                                  if (index < records.length - 1) {
                                    final prev = records[index + 1];
                                    final diff = record.weightG - prev.weightG;
                                    final sign = diff >= 0 ? '+' : '';
                                    growthText = ' ($sign${diff}g)';
                                  }
                                  
                                  final formattedDate = record.recordDate.split('-').reversed.join('/');
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(
                                        '${record.weightG} g$growthText',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text('Registrado em: $formattedDate'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Confirmar Exclusão'),
                                              content: const Text('Deseja realmente excluir este registro de biometria?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            setState(() => _isLoading = true);
                                            await ref
                                                .read(biometricsProvider(widget.tank.id).notifier)
                                                .deleteBiometrics(record.id);
                                            setState(() => _isLoading = false);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (err, stack) => Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text('Erro ao carregar biometria: $err'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Fechar', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
