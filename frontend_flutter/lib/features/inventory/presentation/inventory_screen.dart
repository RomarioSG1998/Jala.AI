import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/inventory/providers/inventory_provider.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  static void showAddItemModal(BuildContext context, WidgetRef ref) {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: inventoryAsync.when(
        data: (items) {
          if (items.isEmpty) return _buildEmptyState();
          return RefreshIndicator(
            onRefresh: () => ref.read(inventoryProvider.notifier).refreshItems(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
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
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Item'),
                        content: Text(
                            'Are you sure you want to delete "${item.itemName}"?'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    ref.read(inventoryProvider.notifier).deleteItem(item.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                          Text('Quantity: ${item.quantity} ${item.unit}'),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: style.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.type,
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
              Text('Failed to load inventory:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(inventoryProvider.notifier).refreshItems(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No inventory items found.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          const Text('Click the + button to add your first item.',
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
  String _selectedType = 'Feed';
  bool _isLoading = false;

  static const _types = ['Feed', 'Medicine', 'Equipment', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref.read(inventoryProvider.notifier).createItem(
          _nameController.text.trim(),
          double.parse(_qtyController.text.trim()),
          _unitController.text.trim(),
          _selectedType,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add item')),
        );
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
            const Text(
              'Add Inventory Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Item Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyController,
                    decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder()),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : (double.tryParse(v) == null ? 'Invalid' : null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                        labelText: 'Unit (kg, L…)',
                        border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                  labelText: 'Type', border: OutlineInputBorder()),
              items: _types
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedType = val ?? 'Feed'),
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
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}

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
  late String _selectedType;
  bool _isLoading = false;

  static const _types = ['Feed', 'Medicine', 'Equipment', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.itemName);
    _qtyController = TextEditingController(text: widget.item.quantity.toString());
    _unitController = TextEditingController(text: widget.item.unit);
    _selectedType = _types.contains(widget.item.type) ? widget.item.type : 'Feed';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref.read(inventoryProvider.notifier).updateItem(
          widget.item.id,
          _nameController.text.trim(),
          double.parse(_qtyController.text.trim()),
          _unitController.text.trim(),
          _selectedType,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update item')),
        );
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
            const Text(
              'Edit Inventory Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Item Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _qtyController,
                    decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder()),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : (double.tryParse(v) == null ? 'Invalid' : null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                        labelText: 'Unit (kg, L…)',
                        border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                  labelText: 'Type', border: OutlineInputBorder()),
              items: _types
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedType = val ?? 'Feed'),
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
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
