import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import '../providers/employees_provider.dart';
import '../providers/employee_permissions_provider.dart';
import '../data/employee_model.dart';
import '../data/employee_permission_model.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

// Hardcoded test farm ID (matches seed data)
const _kFarmId = '55555555-5555-5555-5555-555555555555';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesProvider);
    final searchQuery = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
        centerTitle: true,
      ),
      body: employeesAsync.when(
        data: (employees) {
          final filtered = employees.where((emp) {
            if (searchQuery.isEmpty) return true;
            final nameMatch = emp.name.toLowerCase().contains(searchQuery.toLowerCase());
            final emailMatch = emp.email.toLowerCase().contains(searchQuery.toLowerCase());
            final roleMatch = emp.accountType.toLowerCase().contains(searchQuery.toLowerCase());
            return nameMatch || emailMatch || roleMatch;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isNotEmpty
                        ? 'Nenhum funcionário encontrado para "$searchQuery"'
                        : 'Nenhum funcionário cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  if (searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pressione + para adicionar um funcionário.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final emp = filtered[index];
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isDark ? const BorderSide(color: Color(0xFF263350), width: 1.0) : BorderSide.none,
                ),
                elevation: 0,
                color: Theme.of(context).cardColor,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isDark ? Colors.blue.withOpacity(0.2) : const Color(0xFF003366).withOpacity(0.1),
                    child: Icon(Icons.person, color: isDark ? Colors.blue.shade300 : const Color(0xFF003366)),
                  ),
                  title: Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Text(emp.email, style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Permissions button ─────────────────────────
                      Tooltip(
                        message: 'Gerenciar Acessos',
                        child: IconButton(
                          icon: const Icon(Icons.shield_outlined, color: Color(0xFF13A538)),
                          onPressed: () => _showPermissionsSheet(context, emp),
                        ),
                      ),
                      // ── Edit button ────────────────────────────────
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => EmployeesScreen.showAddEmployeeModal(context, emp),
                      ),
                      // ── Delete button ──────────────────────────────
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, emp),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Erro ao carregar funcionários: $err'),
        ),
      ),
    );
  }

  // ── Permissions sheet ──────────────────────────────────────────────────────
  void _showPermissionsSheet(BuildContext context, Employee emp) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmployeePermissionsSheet(employee: emp),
    );
  }

  // ── Confirm delete ─────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, WidgetRef ref, Employee emp) async {
    final confirm = await PasswordConfirmationDialog.confirm(context, ref);

    if (confirm == true) {
      final success = await ref.read(employeesProvider.notifier).deleteEmployee(emp.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? 'Funcionário removido com sucesso!' : 'Erro ao remover funcionário.')),
        );
      }
    }
  }

  // ── Static modal – called by central FAB ───────────────────────────────────
  static void showAddEmployeeModal(BuildContext context, [Employee? employee]) {
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
        child: AddEmployeeForm(employee: employee),
      ),
    );
  }
}

// ─── Employee Permissions Sheet ───────────────────────────────────────────────

class EmployeePermissionsSheet extends ConsumerWidget {
  final Employee employee;
  const EmployeePermissionsSheet({super.key, required this.employee});

  String get _key => '${employee.id}:$_kFarmId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permsAsync = ref.watch(employeePermissionsProvider(_key));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF13A538).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF13A538), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Controle de Acesso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF003366),
                      ),
                    ),
                    Text(
                      employee.name,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade300 : Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ative ou desative os módulos que este funcionário poderá acessar.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const Divider(height: 28),

          // ── Module toggles ────────────────────────────────────────────────
          permsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Erro: $e', style: const TextStyle(color: Colors.red)),
            ),
            data: (perms) {
              // Build a map for quick lookup
              final permMap = {for (final p in perms) p.moduleName: p.isEnabled};

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: kAvailableModules.map((mod) {
                  final isEnabled = permMap[mod.key] ?? true;
                  return _ModuleTile(
                    mod: mod,
                    isEnabled: isEnabled,
                    onToggle: (val) {
                      ref
                          .read(employeePermissionsProvider(_key).notifier)
                          .toggle(mod.key, val);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Module Tile ─────────────────────────────────────────────────────────────

class _ModuleTile extends StatelessWidget {
  final ModuleInfo mod;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;

  const _ModuleTile({
    required this.mod,
    required this.isEnabled,
    required this.onToggle,
  });

  static const _moduleIcons = {
    'tanks':           Icons.water,
    'water_quality':   Icons.science,
    'inventory':       Icons.inventory_2_outlined,
    'feeding_records': Icons.restaurant_outlined,
    'harvests':        Icons.agriculture_outlined,
    'maintenance':     Icons.build_outlined,
  };

  static const _moduleColors = {
    'tanks':           Colors.blue,
    'water_quality':   Colors.teal,
    'inventory':       Colors.orange,
    'feeding_records': Colors.purple,
    'harvests':        Colors.green,
    'maintenance':     Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final color = _moduleColors[mod.key] ?? Colors.blueGrey;
    final icon = _moduleIcons[mod.key] ?? Icons.widgets;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.05) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.2) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isEnabled ? color.withOpacity(0.12) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF334155) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isEnabled ? color : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade400), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mod.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87) : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
                Text(
                  mod.description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isEnabled,
            onChanged: onToggle,
            activeColor: color,
          ),
        ],
      ),
    );
  }
}

// ─── Add / Edit Employee Form ─────────────────────────────────────────────────

class AddEmployeeForm extends ConsumerStatefulWidget {
  final Employee? employee;
  const AddEmployeeForm({super.key, this.employee});

  @override
  ConsumerState<AddEmployeeForm> createState() => _AddEmployeeFormState();
}

class _AddEmployeeFormState extends ConsumerState<AddEmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSaving = false;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.employee?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.employee?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    bool success;
    if (_isEditing) {
      success = await ref.read(employeesProvider.notifier).updateEmployee(
            widget.employee!.id,
            _nameCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
          );
    } else {
      success = await ref.read(employeesProvider.notifier).registerEmployee(
            _nameCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _passwordCtrl.text.trim(),
          );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Funcionário atualizado!' : 'Funcionário cadastrado!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar. Verifique os dados.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  const Icon(Icons.person_add_outlined, color: Color(0xFF003366)),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Editar Funcionário' : 'Novo Funcionário',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003366)),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 14),

              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 14),

              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: _isEditing ? 'Nova senha (deixe em branco para não alterar)' : 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (!_isEditing && (v == null || v.trim().length < 6)) {
                    return 'Senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_isEditing ? 'Salvar Alterações' : 'Cadastrar Funcionário'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
