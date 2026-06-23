import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/inventory/data/inventory_model.dart';
import 'package:frontend_flutter/features/inventory/providers/inventory_provider.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';

import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  static void showAddItemModal(BuildContext context, WidgetRef ref) {
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
        child: const AddInventoryItemForm(),
      ),
    );
  }

  // Returns an icon and color based on item type
  ({IconData icon, Color color}) _typeStyle(String type) {
    switch (type.toLowerCase()) {
      case 'feed':
        return (icon: Icons.set_meal, color: Colors.amber.shade700);
      case 'medicine':
        return (icon: Icons.medication, color: Colors.red.shade400);
      case 'equipment':
        return (icon: Icons.build_circle, color: Colors.blueGrey);
      default:
        return (icon: Icons.inventory_2, color: Colors.orange.shade700);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState.accountType == 'FARM_OWNER' || authState.accountType == 'CLIENT';
    final searchQuery = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: inventoryAsync.when(
        data: (items) {
          final filtered = items.where((item) {
            if (searchQuery.isEmpty) return true;
            final nameMatch = item.itemName.toLowerCase().contains(searchQuery.toLowerCase());
            final typeMatch = item.type.toLowerCase().contains(searchQuery.toLowerCase());
            return nameMatch || typeMatch;
          }).toList();

          if (filtered.isEmpty) {
            return searchQuery.isNotEmpty
                ? _buildEmptyState(context, message: 'Nenhum item encontrado para "$searchQuery"')
                : _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(inventoryProvider.notifier).refreshItems(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final style = _typeStyle(item.type);

                return Dismissible(
                  key: Key(item.id),
                  direction: isOwner
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await PasswordConfirmationDialog.confirm(context, ref);
                  },
                  onDismissed: (direction) {
                    ref.read(inventoryProvider.notifier).deleteItem(item.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF263350) : Colors.transparent, width: 1.0)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: style.color.withOpacity(0.15),
                        radius: 26,
                        child: Icon(style.icon,
                            color: style.color, size: 26),
                      ),
                      title: Text(item.itemName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Quantidade: ${item.quantity} ${item.unit}${item.unitCost != null ? " (Custo: R\$ ${item.unitCost!.toStringAsFixed(2)}/${item.unit})" : ""}'),
                          if (item.power != null && item.power!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Potência: ${item.power}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: style.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.type == 'Feed' ? 'Ração' : (item.type == 'Medicine' ? 'Medicamento' : (item.type == 'Equipment' ? 'Equipamento' : 'Outro')),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: style.color),
                            ),
                          )
                        ],
                      ),
                      trailing: const Icon(Icons.edit_outlined),
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
                            child: EditInventoryItemForm(item: item),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Falha ao carregar estoque:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(inventoryProvider.notifier).refreshItems(),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String message = 'Nenhum item encontrado no estoque.'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(fontSize: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
              textAlign: TextAlign.center,),
          const SizedBox(height: 8),
          if (message == 'Nenhum item encontrado no estoque.')
            const Text('Clique no botão + para adicionar seu primeiro item.',
                style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Add Item Form ────────────────────────────────────────────────────────────

class AddInventoryItemForm extends ConsumerStatefulWidget {
  const AddInventoryItemForm({super.key});

  @override
  ConsumerState<AddInventoryItemForm> createState() =>
      _AddInventoryItemFormState();
}

class _AddInventoryItemFormState
    extends ConsumerState<AddInventoryItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  final _customEquipmentNameController = TextEditingController();
  final _powerController = TextEditingController();
  final _unitCostController = TextEditingController();

  String _selectedType = 'Feed';
  String _selectedEquipmentName = 'Tarrafa';
  bool _isLoading = false;

  static const _types = ['Feed', 'Medicine', 'Equipment', 'Other'];
  static const _equipments = ['Tarrafa', 'Soprador', 'Aerador', 'Outro'];

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _customEquipmentNameController.dispose();
    _powerController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String finalName = _nameController.text.trim();
    if (_selectedType == 'Equipment') {
      if (_selectedEquipmentName != 'Outro') {
        finalName = _selectedEquipmentName;
      } else {
        finalName = _customEquipmentNameController.text.trim();
      }
    }

    String? finalPower = (_selectedType == 'Equipment' && _selectedEquipmentName == 'Aerador')
        ? _powerController.text.trim()
        : null;

    final success = await ref.read(inventoryProvider.notifier).createItem(
          finalName,
          double.parse(_qtyController.text.trim()),
          _unitController.text.trim(),
          _selectedType,
          power: finalPower,
          unitCost: double.tryParse(_unitCostController.text.trim()),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao adicionar item')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Text(
                    'Adicionar Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF003366),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                    labelText: 'Tipo de Item', border: OutlineInputBorder()),
                items: _types
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t == 'Feed' ? 'Ração' : (t == 'Medicine' ? 'Medicamento' : (t == 'Equipment' ? 'Equipamento' : 'Outro')))))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedType = val ?? 'Feed'),
              ),
              const SizedBox(height: 16),
              if (_selectedType == 'Equipment') ...[
                DropdownButtonFormField<String>(
                  value: _selectedEquipmentName,
                  decoration: const InputDecoration(
                      labelText: 'Equipamento', border: OutlineInputBorder()),
                  items: _equipments
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedEquipmentName = val ?? 'Tarrafa'),
                ),
                const SizedBox(height: 16),
                if (_selectedEquipmentName == 'Outro') ...[
                  TextFormField(
                    controller: _customEquipmentNameController,
                    decoration: const InputDecoration(
                        labelText: 'Nome do Equipamento Personalizado', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_selectedEquipmentName == 'Aerador') ...[
                  TextFormField(
                    controller: _powerController,
                    decoration: const InputDecoration(
                        labelText: 'Potência (ex: 1 cavalo, 2 cavalos) - Opcional', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                ],
              ] else ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Nome do Item', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtyController,
                      decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          border: OutlineInputBorder()),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty
                          ? 'Obrigatório'
                          : (double.tryParse(v) == null ? 'Inválido' : null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                          labelText: 'Unidade (kg, L…)',
                          border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitCostController,
                decoration: const InputDecoration(
                    labelText: 'Custo Unitário (R\$)',
                    helperText: 'Opcional. Ex: preço pago por kg/unidade',
                    border: OutlineInputBorder()),
                keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (double.tryParse(v) == null) return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13A538),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Item Form ───────────────────────────────────────────────────────────

class EditInventoryItemForm extends ConsumerStatefulWidget {
  final InventoryItem item;
  const EditInventoryItemForm({super.key, required this.item});

  @override
  ConsumerState<EditInventoryItemForm> createState() =>
      _EditInventoryItemFormState();
}

class _EditInventoryItemFormState
    extends ConsumerState<EditInventoryItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final TextEditingController _unitController;
  late final TextEditingController _customEquipmentNameController;
  late final TextEditingController _powerController;
  late final TextEditingController _unitCostController;

  late String _selectedType;
  late String _selectedEquipmentName;
  bool _isLoading = false;

  static const _types = ['Feed', 'Medicine', 'Equipment', 'Other'];
  static const _equipments = ['Tarrafa', 'Soprador', 'Aerador', 'Outro'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    _qtyController = TextEditingController(text: widget.item.quantity.toString());
    _unitController = TextEditingController(text: widget.item.unit);
    _selectedType = _types.contains(widget.item.type) ? widget.item.type : 'Feed';
    _unitCostController = TextEditingController(text: widget.item.unitCost?.toString() ?? '');

    _customEquipmentNameController = TextEditingController();
    _powerController = TextEditingController(text: widget.item.power ?? '');

    if (_selectedType == 'Equipment') {
      if (_equipments.contains(widget.item.itemName)) {
        _selectedEquipmentName = widget.item.itemName;
      } else {
        _selectedEquipmentName = 'Outro';
        _customEquipmentNameController.text = widget.item.itemName;
      }
    } else {
      _selectedEquipmentName = 'Tarrafa';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    _customEquipmentNameController.dispose();
    _powerController.dispose();
    _unitCostController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String finalName = _nameController.text.trim();
    if (_selectedType == 'Equipment') {
      if (_selectedEquipmentName != 'Outro') {
        finalName = _selectedEquipmentName;
      } else {
        finalName = _customEquipmentNameController.text.trim();
      }
    }

    String? finalPower = (_selectedType == 'Equipment' && _selectedEquipmentName == 'Aerador')
        ? _powerController.text.trim()
        : null;

    final success = await ref.read(inventoryProvider.notifier).updateItem(
          widget.item.id,
          finalName,
          double.parse(_qtyController.text.trim()),
          _unitController.text.trim(),
          _selectedType,
          power: finalPower,
          unitCost: double.tryParse(_unitCostController.text.trim()),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao atualizar item')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  Text(
                    'Editar Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF003366),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                    labelText: 'Tipo de Item', border: OutlineInputBorder()),
                items: _types
                    .map((t) =>
                        DropdownMenuItem(value: t, child: Text(t == 'Feed' ? 'Ração' : (t == 'Medicine' ? 'Medicamento' : (t == 'Equipment' ? 'Equipamento' : 'Outro')))))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedType = val ?? 'Feed'),
              ),
              const SizedBox(height: 16),
              if (_selectedType == 'Equipment') ...[
                DropdownButtonFormField<String>(
                  value: _selectedEquipmentName,
                  decoration: const InputDecoration(
                      labelText: 'Equipamento', border: OutlineInputBorder()),
                  items: _equipments
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedEquipmentName = val ?? 'Tarrafa'),
                ),
                const SizedBox(height: 16),
                if (_selectedEquipmentName == 'Outro') ...[
                  TextFormField(
                    controller: _customEquipmentNameController,
                    decoration: const InputDecoration(
                        labelText: 'Nome do Equipamento Personalizado', border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                ],
                if (_selectedEquipmentName == 'Aerador') ...[
                  TextFormField(
                    controller: _powerController,
                    decoration: const InputDecoration(
                        labelText: 'Potência (ex: 1 cavalo, 2 cavalos) - Opcional', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                ],
              ] else ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Nome do Item', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _qtyController,
                      decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          border: OutlineInputBorder()),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty
                          ? 'Obrigatório'
                          : (double.tryParse(v) == null ? 'Inválido' : null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                          labelText: 'Unidade (kg, L…)',
                          border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitCostController,
                decoration: const InputDecoration(
                    labelText: 'Custo Unitário (R\$)',
                    helperText: 'Opcional. Ex: preço pago por kg/unidade',
                    border: OutlineInputBorder()),
                keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (double.tryParse(v) == null) return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
