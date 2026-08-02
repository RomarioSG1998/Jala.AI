import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/maintenance/data/maintenance_model.dart';
import 'package:frontend_flutter/features/maintenance/providers/maintenance_provider.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  static void showAddTaskModal(BuildContext context, WidgetRef ref) {
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
        child: const AddMaintenanceTaskForm(),
      ),
    );
  }

  ({Color color, IconData icon}) _statusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return (color: Colors.green, icon: Icons.check_circle);
      case 'IN_PROGRESS':
        return (color: Colors.blue, icon: Icons.pending);
      case 'CANCELLED':
        return (color: Colors.red, icon: Icons.cancel);
      default: // PENDING
        return (color: Colors.orange, icon: Icons.schedule);
    }
  }

  String _translateStatus(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Concluída';
      case 'IN_PROGRESS':
        return 'Em Andamento';
      case 'CANCELLED':
        return 'Cancelada';
      default:
        return 'Pendente';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(maintenanceProvider);
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState.accountType == 'FARM_OWNER' || authState.accountType == 'CLIENT';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final searchQuery = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: null,
      body: tasksAsync.when(
        data: (tasks) {
          final filtered = tasks.where((task) {
            if (searchQuery.isEmpty) return true;
            final query = searchQuery.toLowerCase();
            final descMatch = task.description.toLowerCase().contains(query);
            final statusMatch = task.status.toLowerCase().contains(query);
            final statusPtMatch = _translateStatus(task.status).toLowerCase().contains(query);
            return descMatch || statusMatch || statusPtMatch;
          }).toList();

          if (filtered.isEmpty) {
            return searchQuery.isNotEmpty
                ? _buildEmptyState(context, message: 'Nenhuma tarefa encontrada para "$searchQuery"')
                : _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(maintenanceProvider.notifier).refreshTasks(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final task = filtered[index];
                final style = _statusStyle(task.status);

                DateTime date;
                try {
                  date = DateTime.parse(task.scheduledDate);
                } catch (_) {
                  date = DateTime.now();
                }
                final formattedDate = DateFormat('dd/MM/yyyy').format(date);
                final isPast = date.isBefore(DateTime.now()) &&
                    task.status.toUpperCase() == 'PENDING';

                return Dismissible(
                  key: Key(task.id),
                  direction: isOwner
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                   confirmDismiss: (direction) async {
                    return await PasswordConfirmationDialog.confirm(context, ref);
                  },
                  onDismissed: (_) {
                    ref
                        .read(maintenanceProvider.notifier)
                        .deleteTask(task.id);
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
                          horizontal: 16, vertical: 10),
                      leading: CircleAvatar(
                        backgroundColor: style.color.withOpacity(0.15),
                        radius: 26,
                        child: Icon(style.icon,
                            color: style.color, size: 26),
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
                            child: EditMaintenanceTaskForm(task: task),
                          ),
                        );
                      },
                      title: Text(
                        task.description,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 4),
                               Text(formattedDate,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isPast
                                        ? Colors.red
                                        : (isDark ? Colors.white70 : Colors.black87),
                                    fontWeight: isPast
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  )),
                              if (isPast) ...[
                                const SizedBox(width: 4),
                                const Text('⚠️ Atrasada',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.red)),
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: style.color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _translateStatus(task.status),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: style.color),
                            ),
                          ),
                        ],
                      ),
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
              Text('Falha ao carregar tarefas:\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(maintenanceProvider.notifier).refreshTasks(),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String message = 'Nenhuma tarefa de manutenção encontrada.'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              style:
                  TextStyle(fontSize: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
              textAlign: TextAlign.center,),
          const SizedBox(height: 8),
          if (message == 'Nenhuma tarefa de manutenção encontrada.')
            const Text('Clique no botão + para agendar uma tarefa.',
                style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Add Maintenance Task Form ────────────────────────────────────────────────

class AddMaintenanceTaskForm extends ConsumerStatefulWidget {
  const AddMaintenanceTaskForm({super.key});

  @override
  ConsumerState<AddMaintenanceTaskForm> createState() =>
      _AddMaintenanceTaskFormState();
}

class _AddMaintenanceTaskFormState
    extends ConsumerState<AddMaintenanceTaskForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTankId;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  final _descriptionController = TextEditingController();
  String _selectedStatus = 'PENDING';
  bool _isLoading = false;

  static const _statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    ref.read(tanksProvider.notifier).refreshTanks();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedTankId == null) {
      if (_selectedTankId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecione um tanque')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_scheduledDate);

    final success =
        await ref.read(maintenanceProvider.notifier).createTask(
              _selectedTankId!,
              _descriptionController.text.trim(),
              _selectedStatus,
              dateStr,
            );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao criar tarefa')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tanksProvider);
    final formattedDate = DateFormat('dd/MM/yyyy').format(_scheduledDate);

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
                const Text(
                  'Agendar Manutenção',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 24),
              tanksAsync.when(
                data: (tanks) {
                  if (tanks.isEmpty) {
                    return const Text('Nenhum tanque disponível.');
                  }
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Selecionar Tanque',
                        border: OutlineInputBorder()),
                    value: _selectedTankId,
                    items: tanks
                        .map((t) => DropdownMenuItem(
                            value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedTankId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Erro ao carregar tanques: $err'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'ex: Limpar filtros do tanque',
                    border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data Agendada',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller:
                        TextEditingController(text: formattedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                    labelText: 'Status', border: OutlineInputBorder()),
                items: _statuses
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s == 'PENDING' ? 'Pendente' : (s == 'IN_PROGRESS' ? 'Em Andamento' : (s == 'COMPLETED' ? 'Concluída' : 'Cancelada')))))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedStatus = val ?? 'PENDING'),
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
                    : const Text('Criar Tarefa'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class EditMaintenanceTaskForm extends ConsumerStatefulWidget {
  final MaintenanceTask task;
  const EditMaintenanceTaskForm({super.key, required this.task});

  @override
  ConsumerState<EditMaintenanceTaskForm> createState() =>
      _EditMaintenanceTaskFormState();
}

class _EditMaintenanceTaskFormState
    extends ConsumerState<EditMaintenanceTaskForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _scheduledDate;
  late final TextEditingController _descriptionController;
  late String _selectedStatus;
  bool _isLoading = false;

  static const _statuses = ['PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    _scheduledDate = DateTime.tryParse(widget.task.scheduledDate) ?? DateTime.now();
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedStatus = _statuses.contains(widget.task.status) ? widget.task.status : 'PENDING';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dateStr = DateFormat('yyyy-MM-dd').format(_scheduledDate);

    final success =
        await ref.read(maintenanceProvider.notifier).updateTask(
              widget.task.id,
              widget.task.tankId,
              _descriptionController.text.trim(),
              _selectedStatus,
              dateStr,
            );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao atualizar tarefa')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(_scheduledDate);

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
              const Text(
                'Editar Tarefa de Manutenção',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'ex: Limpar filtros do tanque',
                    border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Data Agendada',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    controller:
                        TextEditingController(text: formattedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                    labelText: 'Status', border: OutlineInputBorder()),
                items: _statuses
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s == 'PENDING' ? 'Pendente' : (s == 'IN_PROGRESS' ? 'Em Andamento' : (s == 'COMPLETED' ? 'Concluída' : 'Cancelada')))))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedStatus = val ?? 'PENDING'),
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
                    : const Text('Salvar Alterações'),
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
