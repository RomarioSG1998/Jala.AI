import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/suppliers/providers/supplier_provider.dart';
import 'package:frontend_flutter/features/suppliers/data/supplier_model.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  static const _kNavyBlue = Color(0xFF003366);
  static const _kGreen = Color(0xFF13A538);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(supplierProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.accountType == 'SAAS_ADMIN';
    final searchQuery = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Fornecedores B2B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(supplierProvider.notifier).refreshSuppliers(),
        child: suppliersAsync.when(
          data: (suppliers) {
            final filtered = suppliers.where((s) {
              if (searchQuery.isEmpty) return true;
              final query = searchQuery.toLowerCase();
              final nameMatch = s.companyName.toLowerCase().contains(query);
              final cnpjMatch = s.cnpj.toLowerCase().contains(query);
              final typeMatch = s.supplyType.toLowerCase().contains(query);
              return nameMatch || cnpjMatch || typeMatch;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                Text(
                  'Catálogo de Fornecedores Nacionais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  isAdmin 
                      ? 'Administre e aprove parceiros de insumos e equipamentos.' 
                      : 'Veja fornecedores homologados para ração, alevinos e equipamentos.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54),
                ),
                const SizedBox(height: 20),
                if (filtered.isEmpty)
                  _buildEmptyState(context, message: searchQuery.isNotEmpty ? 'Nenhum fornecedor encontrado para "$searchQuery"' : 'Nenhum fornecedor cadastrado')
                else
                  Column(
                    children: filtered
                        .map((s) => _buildSupplierCard(context, ref, s, isAdmin))
                        .toList(),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Erro ao carregar fornecedores: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildSupplierCard(BuildContext context, WidgetRef ref, NationalSupplier s, bool isAdmin) {
    return Dismissible(
      key: Key(s.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await PasswordConfirmationDialog.confirm(context, ref);
      },
      onDismissed: (_) {
        ref.read(supplierProvider.notifier).deleteSupplier(s.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fornecedor removido')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Theme.of(context).brightness == Brightness.dark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.companyName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                  ),
                ),
                _buildStatusPill(context, s.isApproved),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.black38),
                const SizedBox(width: 6),
                Text('CNPJ: ${s.cnpj}', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.shopping_bag_outlined, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white30 : Colors.black38),
                const SizedBox(width: 6),
                Text('Categoria: ${s.supplyType}', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontSize: 12)),
              ],
            ),
            if (isAdmin && !s.isApproved) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref.read(supplierProvider.notifier).approveSupplier(s.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Homologar Fornecedor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(BuildContext context, bool isApproved) {
    final color = isApproved ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green) : (Theme.of(context).brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange);
    final bgColor = Theme.of(context).brightness == Brightness.dark ? (isApproved ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15)) : (isApproved ? Colors.green.shade50 : Colors.orange.shade50);
    final text = isApproved ? 'Homologado' : 'Pendente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isApproved ? Icons.verified_user : Icons.hourglass_empty, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String message = 'Nenhum fornecedor cadastrado'}) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.business_center_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (message == 'Nenhum fornecedor cadastrado') ...[
            const SizedBox(height: 4),
            const Text(
              'Adicione um novo fornecedor nacional clicando no botão +',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static void showAddSupplierModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _AddSupplierForm(),
      ),
    );
  }
}

class _AddSupplierForm extends ConsumerStatefulWidget {
  const _AddSupplierForm();

  @override
  ConsumerState<_AddSupplierForm> createState() => _AddSupplierFormState();
}

class _AddSupplierFormState extends ConsumerState<_AddSupplierForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _typeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cnpjController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref.read(supplierProvider.notifier).createSupplier(
          _nameController.text.trim(),
          _cnpjController.text.trim(),
          _typeController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao adicionar fornecedor')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cadastrar Fornecedor',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Razão Social / Nome da Empresa',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cnpjController,
                decoration: const InputDecoration(
                  labelText: 'CNPJ',
                  border: OutlineInputBorder(),
                  hintText: '00.000.000/0000-00',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Fornecimento',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Ração, Alevinos, Bombas, Filtros',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13A538),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Solicitar Cadastro', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
