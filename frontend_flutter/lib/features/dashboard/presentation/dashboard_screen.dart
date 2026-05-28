import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/saas_admin/providers/saas_providers.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';
import 'package:frontend_flutter/features/water_quality/providers/water_quality_provider.dart';
import 'package:frontend_flutter/features/dashboard/providers/farm_summary_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend_flutter/features/tanks/presentation/tanks_screen.dart';
import 'package:frontend_flutter/features/water_quality/presentation/water_quality_screen.dart';
import 'package:frontend_flutter/features/inventory/presentation/inventory_screen.dart';
import 'package:frontend_flutter/features/harvests/presentation/harvests_screen.dart';
import 'package:frontend_flutter/features/maintenance/presentation/maintenance_screen.dart';
import 'package:frontend_flutter/features/finances/presentation/finances_screen.dart';
import 'package:frontend_flutter/features/suppliers/presentation/suppliers_screen.dart';
import 'package:frontend_flutter/features/saas_admin/presentation/tenants_screen.dart';
import 'package:frontend_flutter/features/feeding_records/presentation/feeding_records_screen.dart';
import 'package:frontend_flutter/features/employees/presentation/employees_screen.dart';
import 'package:frontend_flutter/features/employees/providers/employee_permissions_provider.dart';
import 'package:frontend_flutter/features/maintenance/providers/maintenance_provider.dart';
import 'package:frontend_flutter/features/maintenance/data/maintenance_model.dart';
import 'package:frontend_flutter/features/tanks/data/tank_model.dart';
import 'package:frontend_flutter/core/widgets/password_confirmation_dialog.dart';
import 'dart:convert';
import 'package:frontend_flutter/core/api/secure_storage.dart';


class AppNotification {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onAction;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.onAction,
  });
}

class DismissedNotificationsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'dismissed_notifications';

  @override
  Set<String> build() {
    final authState = ref.watch(authNotifierProvider);
    if (authState.isAuthenticated && authState.email != null) {
      _load(authState.email!);
    }
    return <String>{};
  }

  Future<void> _load(String email) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final jsonStr = await storage.read(key: '${_storageKey}_$email');
      debugPrint("LOADED dismissed_notifications for $email: $jsonStr");
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        state = list.map((e) => e.toString()).toSet();
      } else {
        state = <String>{};
      }
    } catch (e) {
      debugPrint("ERROR LOADING dismissed_notifications: $e");
    }
  }

  Future<void> dismiss(String id) async {
    final authState = ref.read(authNotifierProvider);
    final email = authState.email ?? 'global';
    state = {...state, id};
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.write(key: '${_storageKey}_$email', value: json.encode(state.toList()));
      debugPrint("SAVED dismissed_notifications for $email: ${state.toList()}");
    } catch (e) {
      debugPrint("ERROR SAVING dismissed_notifications: $e");
    }
  }
}

final dismissedNotificationsProvider = NotifierProvider<DismissedNotificationsNotifier, Set<String>>(() {
  return DismissedNotificationsNotifier();
});

class SeenNotificationsNotifier extends Notifier<Set<String>> {
  static const _storageKey = 'seen_notifications';

  @override
  Set<String> build() {
    final authState = ref.watch(authNotifierProvider);
    if (authState.isAuthenticated && authState.email != null) {
      _load(authState.email!);
    }
    return <String>{};
  }

  Future<void> _load(String email) async {
    try {
      final storage = ref.read(secureStorageProvider);
      final jsonStr = await storage.read(key: '${_storageKey}_$email');
      debugPrint("LOADED seen_notifications for $email: $jsonStr");
      if (jsonStr != null) {
        final List<dynamic> list = json.decode(jsonStr);
        state = list.map((e) => e.toString()).toSet();
      } else {
        state = <String>{};
      }
    } catch (e) {
      debugPrint("ERROR LOADING seen_notifications: $e");
    }
  }

  Future<void> markAsSeen(List<String> ids) async {
    final authState = ref.read(authNotifierProvider);
    final email = authState.email ?? 'global';
    final newState = {...state, ...ids};
    state = newState;
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.write(key: '${_storageKey}_$email', value: json.encode(newState.toList()));
      debugPrint("SAVED seen_notifications for $email: ${newState.toList()}");
    } catch (e) {
      debugPrint("ERROR SAVING seen_notifications: $e");
    }
  }
}

final seenNotificationsProvider = NotifierProvider<SeenNotificationsNotifier, Set<String>>(() {
  return SeenNotificationsNotifier();
});

// ─── AppShell – Casca Permanente com Header e Bottom Nav ────────────────────

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final String currentLocation;

  const AppShell({super.key, required this.navigationShell, required this.currentLocation});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _kNavyBlue = Color(0xFF003366);
  static const _kGreen = Color(0xFF13A538);
  late final TextEditingController _searchController;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCentralFabPressed(BuildContext context) {
    final currentRoute = widget.currentLocation;
    final authState = ref.read(authNotifierProvider);

    switch (currentRoute) {
      case '/tanks':
        TanksScreen.showAddTankModal(context);
        break;
      case '/water-quality':
        WaterQualityScreen.showAddLogModal(context, ref);
        break;
      case '/inventory':
        InventoryScreen.showAddItemModal(context, ref);
        break;
      case '/harvests':
        HarvestsScreen.showLogHarvestModal(context, ref);
        break;
      case '/maintenance':
        MaintenanceScreen.showAddTaskModal(context, ref);
        break;
      case '/finances':
        FinancesScreen.showAddTransactionModal(context, ref);
        break;
      case '/suppliers':
        SuppliersScreen.showAddSupplierModal(context, ref);
        break;
      case '/tenants':
        TenantsScreen.showAddTenantModal(context, ref);
        break;
      case '/feeding-records':
        FeedingRecordsScreen.showAddFeedingRecordModal(context, ref);
        break;
      case '/employees':
        EmployeesScreen.showAddEmployeeModal(context);
        break;
      case '/saas-dashboard':
        TenantsScreen.showAddTenantModal(context, ref);
        break;
      default:
        if (authState.accountType == 'SAAS_ADMIN') {
          TenantsScreen.showAddTenantModal(context, ref);
        } else {
          final isOwner = authState.accountType == 'FARM_OWNER' || authState.accountType == 'CLIENT';
          if (isOwner) {
            TanksScreen.showAddTankModal(context);
          } else {
            FeedingRecordsScreen.showAddFeedingRecordModal(context, ref);
          }
        }
        break;
    }
  }

  void _showNotificationDialog(BuildContext context) {
    final authState = ref.read(authNotifierProvider);
    final role = authState.accountType ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(20),
            child: Consumer(
              builder: (context, ref, child) {
                final tasksAsync = ref.watch(maintenanceProvider);
                final tenantsAsync = ref.watch(tenantsProvider);
                final tanksAsync = ref.watch(tanksProvider);
                final dismissed = ref.watch(dismissedNotificationsProvider);

                final List<AppNotification> notifications = [];

                if (role == 'SAAS_ADMIN') {
                  final tenants = tenantsAsync.maybeWhen(data: (list) => list, orElse: () => <FarmTenant>[]);
                  for (var t in tenants) {
                    final empId = '${t.id}_employee';
                    if (!dismissed.contains(empId)) {
                      notifications.add(AppNotification(
                        id: empId,
                        title: 'Novo Funcionário Cadastrado',
                        description: 'Um novo funcionário foi registrado na fazenda ${t.name}.',
                        time: 'Recente',
                        icon: Icons.person_add_rounded,
                        iconColor: Colors.green,
                      ));
                    }
                    final payId = '${t.id}_payment';
                    if (!dismissed.contains(payId)) {
                      notifications.add(AppNotification(
                        id: payId,
                        title: 'Pagamento Aprovado',
                        description: 'Assinatura do Plano Profissional renovada para ${t.name}.',
                        time: 'Hoje',
                        icon: Icons.monetization_on_rounded,
                        iconColor: Colors.blue,
                      ));
                    }
                    final tankId = '${t.id}_tank';
                    if (!dismissed.contains(tankId)) {
                      notifications.add(AppNotification(
                        id: tankId,
                        title: 'Novo Tanque Adquirido',
                        description: 'Fazenda ${t.name} registrou um novo tanque de piscicultura.',
                        time: 'Ontem',
                        icon: Icons.water_drop_rounded,
                        iconColor: Colors.cyan,
                      ));
                    }
                  }
                } else if (role == 'FARM_OWNER' || role == 'CLIENT') {
                  final tasks = tasksAsync.maybeWhen(data: (list) => list, orElse: () => <MaintenanceTask>[]);
                  final completedTasks = tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').toList();
                  final tankMap = tanksAsync.maybeWhen(
                    data: (list) => {for (var t in list) t.id: t.name},
                    orElse: () => <String, String>{},
                  );

                  for (var task in completedTasks) {
                    final notifId = 'completed_${task.id}';
                    if (!dismissed.contains(notifId)) {
                      final tankName = tankMap[task.tankId] ?? 'Tanque não identificado';
                      String formattedDate = task.scheduledDate;
                      try {
                        final parsed = DateTime.parse(task.scheduledDate);
                        formattedDate = DateFormat('dd/MM/yyyy').format(parsed);
                      } catch (_) {}

                      notifications.add(AppNotification(
                        id: notifId,
                        title: 'Tarefa Concluída',
                        description: '${task.description} concluída no tanque $tankName.',
                        time: formattedDate,
                        icon: Icons.check_circle_rounded,
                        iconColor: Colors.green,
                      ));
                    }
                  }
                } else { // FIELD_OPERATOR
                  final tasks = tasksAsync.maybeWhen(data: (list) => list, orElse: () => <MaintenanceTask>[]);
                  final activeTasks = tasks.where((t) => t.status.toUpperCase() == 'PENDING' || t.status.toUpperCase() == 'IN_PROGRESS').toList();
                  final tankMap = tanksAsync.maybeWhen(
                    data: (list) => {for (var t in list) t.id: t.name},
                    orElse: () => <String, String>{},
                  );

                  for (var task in activeTasks) {
                    final notifId = 'pending_${task.id}';
                    if (!dismissed.contains(notifId)) {
                      final tankName = tankMap[task.tankId] ?? 'Tanque não identificado';
                      String formattedDate = task.scheduledDate;
                      try {
                        final parsed = DateTime.parse(task.scheduledDate);
                        formattedDate = DateFormat('dd/MM/yyyy').format(parsed);
                      } catch (_) {}

                      notifications.add(AppNotification(
                        id: notifId,
                        title: task.status.toUpperCase() == 'IN_PROGRESS'
                            ? 'Tarefa Em Andamento'
                            : 'Tarefa Pendente',
                        description: '${task.description} no tanque $tankName.',
                        time: formattedDate,
                        icon: task.status.toUpperCase() == 'IN_PROGRESS'
                            ? Icons.pending_rounded
                            : Icons.schedule_rounded,
                        iconColor: task.status.toUpperCase() == 'IN_PROGRESS'
                            ? Colors.blue
                            : Colors.orange,
                        onAction: () async {
                          final success = await ref
                              .read(maintenanceProvider.notifier)
                              .updateTask(
                                task.id,
                                task.description,
                                'COMPLETED',
                                task.scheduledDate,
                              );
                          if (success) {
                            ref.invalidate(farmSummaryProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tarefa marcada como concluída!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ));
                    }
                  }
                }

                if (notifications.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      ref.read(seenNotificationsProvider.notifier).markAsSeen(
                        notifications.map((n) => n.id).toList(),
                      );
                    }
                  });
                }

                // Check loading state of primary provider
                final isLoading = (role == 'SAAS_ADMIN' && tenantsAsync.isLoading) ||
                                  (role != 'SAAS_ADMIN' && tasksAsync.isLoading);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active, color: Color(0xFF003366), size: 24),
                            const SizedBox(width: 8),
                            Text(
                              role == 'SAAS_ADMIN'
                                  ? 'Painel de Eventos SaaS'
                                  : role == 'FIELD_OPERATOR'
                                      ? 'Suas Tarefas Operacionais'
                                      : 'Notificações do Sistema',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 15, thickness: 1),

                    // Body
                    if (isLoading)
                      const SizedBox(
                        height: 150,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.done_all_rounded,
                                color: Colors.green,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nenhuma notificação!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              role == 'SAAS_ADMIN'
                                  ? 'Sem novos cadastros, pagamentos ou tanques.'
                                  : role == 'FIELD_OPERATOR'
                                      ? 'Todas as tarefas foram concluídas!'
                                      : 'Nenhum evento recente de manutenção.',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final item = notifications[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                color: Colors.grey.shade50,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: item.iconColor.withOpacity(0.1),
                                    radius: 18,
                                    child: Icon(
                                      item.icon,
                                      color: item.iconColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        item.description,
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.time,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (item.onAction != null)
                                        IconButton(
                                          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                          tooltip: 'Marcar como concluída',
                                          onPressed: item.onAction,
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                        tooltip: 'Ignorar',
                                        onPressed: () async {
                                          final confirmed = await PasswordConfirmationDialog.confirm(context, ref);
                                          if (confirmed) {
                                            ref.read(dismissedNotificationsProvider.notifier).dismiss(item.id);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: role == 'SAAS_ADMIN'
                                      ? () {
                                          Navigator.pop(context);
                                          context.go('/tenants');
                                        }
                                      : () {
                                          Navigator.pop(context);
                                          context.go('/maintenance');
                                        },
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    if (role != 'SAAS_ADMIN') ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/maintenance');
                        },
                        child: const Text(
                          'Ver Todas as Tarefas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.accountType ?? '';
    final currentIndex = widget.navigationShell.currentIndex;
    final tasksAsync = ref.watch(maintenanceProvider);
    final tenantsAsync = ref.watch(tenantsProvider);
    final dismissed = ref.watch(dismissedNotificationsProvider);
    final seen = ref.watch(seenNotificationsProvider);

    int notificationCount = 0;

    if (role == 'SAAS_ADMIN') {
      final tenants = tenantsAsync.maybeWhen(data: (list) => list, orElse: () => <FarmTenant>[]);
      int count = 0;
      for (var t in tenants) {
        final empId = '${t.id}_employee';
        final payId = '${t.id}_payment';
        final tankId = '${t.id}_tank';
        if (!dismissed.contains(empId) && !seen.contains(empId)) count++;
        if (!dismissed.contains(payId) && !seen.contains(payId)) count++;
        if (!dismissed.contains(tankId) && !seen.contains(tankId)) count++;
      }
      notificationCount = count;
    } else if (role == 'FARM_OWNER' || role == 'CLIENT') {
      final tasks = tasksAsync.maybeWhen(data: (list) => list, orElse: () => <MaintenanceTask>[]);
      final completed = tasks.where((t) => t.status.toUpperCase() == 'COMPLETED').toList();
      notificationCount = completed.where((t) => !dismissed.contains('completed_${t.id}') && !seen.contains('completed_${t.id}')).length;
    } else { // FIELD_OPERATOR
      final tasks = tasksAsync.maybeWhen(data: (list) => list, orElse: () => <MaintenanceTask>[]);
      final active = tasks.where((t) => t.status.toUpperCase() == 'PENDING' || t.status.toUpperCase() == 'IN_PROGRESS').toList();
      notificationCount = active.where((t) => !dismissed.contains('pending_${t.id}') && !seen.contains('pending_${t.id}')).length;
    }

    final isSearchVisible = ref.watch(searchBarVisibleProvider);
    final searchQuery = ref.watch(globalSearchQueryProvider);

    if (currentIndex != _lastIndex) {
      _lastIndex = currentIndex;
      Future.microtask(() {
        ref.read(searchBarVisibleProvider.notifier).setVisible(false);
        ref.read(globalSearchQueryProvider.notifier).setQuery('');
        _searchController.clear();
      });
    }

    final currentRoute = widget.currentLocation;

    String searchHint = 'Pesquisar...';
    switch (currentRoute) {
      case '/tanks':
        searchHint = 'Buscar tanques por nome ou espécie...';
        break;
      case '/water-quality':
        searchHint = 'Buscar leituras de água...';
        break;
      case '/inventory':
        searchHint = 'Buscar itens no estoque...';
        break;
      case '/harvests':
        searchHint = 'Buscar despescas/colheitas...';
        break;
      case '/maintenance':
        searchHint = 'Buscar tarefas de manutenção...';
        break;
      case '/tenants':
        searchHint = 'Buscar tenants/clientes...';
        break;
      case '/suppliers':
        searchHint = 'Buscar fornecedores...';
        break;
      case '/finances':
        searchHint = 'Buscar transações financeiras...';
        break;
      case '/feeding-records':
        searchHint = 'Buscar registros de alimentação...';
        break;
      case '/employees':
        searchHint = 'Buscar funcionários...';
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBody: true,
      // ── AppBar permanente ────────────────────────────────────────────────
      appBar: isSearchVisible
          ? AppBar(
              backgroundColor: _kNavyBlue,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  ref.read(searchBarVisibleProvider.notifier).setVisible(false);
                  ref.read(globalSearchQueryProvider.notifier).setQuery('');
                  _searchController.clear();
                },
              ),
              title: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: _kGreen,
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: const TextStyle(color: Colors.white60, fontSize: 16),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(globalSearchQueryProvider.notifier).setQuery(val);
                },
              ),
              actions: [
                if (searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      ref.read(globalSearchQueryProvider.notifier).setQuery('');
                      _searchController.clear();
                    },
                  ),
              ],
            )
          : AppBar(
              backgroundColor: _kNavyBlue,
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: Image.network(
                        '/logo_emblem.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.water, color: Colors.white, size: 36),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            children: [
                              TextSpan(text: 'Aqua', style: TextStyle(color: Colors.white)),
                              TextSpan(text: 'Sertão', style: TextStyle(color: _kGreen)),
                            ],
                          ),
                        ),
                        const Text('PISCICULTURA INTELIGENTE',
                            style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    ref.read(searchBarVisibleProvider.notifier).setVisible(true);
                  },
                ),
                Stack(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () => _showNotificationDialog(context),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('$notificationCount',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
              ],
            ),
      // ── Drawer lateral ───────────────────────────────────────────────────
      drawer: _AppDrawer(role: role, ref: ref),
      // ── Bottom Navigation permanente ─────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(context, currentIndex, role),
      // ── Corpo dinâmico ───────────────────────────────────────────────────
      body: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: role == 'SAAS_ADMIN' && currentIndex == 0
            ? const _SaasAdminBody()
            : widget.navigationShell,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex, String role) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 10),
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Início', currentIndex == 0),
              _buildNavItem(1, Icons.water_drop_rounded, Icons.water_drop_outlined, 'Tanques', currentIndex == 1),
              const SizedBox(width: 48), // Espaço reservado para o FAB central
              _buildNavItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Qualidade', currentIndex == 2),
              _buildNavItem(3, Icons.apps_rounded, Icons.apps_outlined, 'Menu', currentIndex == 3),
            ],
          ),
        ),
        Positioned(
          top: -12,
          child: _buildCentralFab(context),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, bool isActive) {
    final color = isActive ? _kGreen : Colors.grey.shade400;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.navigationShell.goBranch(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 12 : 0,
              decoration: BoxDecoration(
                color: _kGreen,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralFab(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_kNavyBlue, Color(0xFF0055A5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _kNavyBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _handleCentralFabPressed(context),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── FarmDashboardBody – Conteúdo do Início ─────────────────────────────────

class FarmDashboardBody extends ConsumerWidget {
  const FarmDashboardBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState.accountType ?? '';

    if (role == 'SAAS_ADMIN') return const _SaasAdminBody();

    final tanksAsync = ref.watch(tanksProvider);
    final wqAsync = ref.watch(waterQualityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(tanksProvider);
        ref.invalidate(waterQualityProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Welcome banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003366), Color(0xFF13A538)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Bem-vindo de volta! 👋',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text('Seu painel operacional',
                      style: TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Dados em tempo real dos seus tanques.',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.water, color: Colors.white24, size: 52),
            ]),
          ),

          const SizedBox(height: 24),

          // KPIs
          const Text('VISÃO GERAL',
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          tanksAsync.when(
            data: (tanks) => Row(children: [
              Expanded(child: _kpi('Tanques', '${tanks.length}', Icons.water, Colors.blue)),
              const SizedBox(width: 12),
              wqAsync.when(
                data: (recs) =>
                    Expanded(child: _kpi('Leituras pH', '${recs.length}', Icons.science, Colors.teal)),
                loading: () =>
                    Expanded(child: _kpi('Leituras pH', '…', Icons.science, Colors.teal)),
                error: (_, __) => Expanded(child: _kpi('Erro', '!', Icons.science, Colors.red)),
              ),
            ]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Tanks preview
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tanques',
                style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go('/tanks'),
              child: const Text('Ver todos →',
                  style: TextStyle(color: Color(0xFF13A538))),
            ),
          ]),
          const SizedBox(height: 8),
          tanksAsync.when(
            data: (tanks) {
              if (tanks.isEmpty) return _emptyHint('Nenhum tanque cadastrado.', Icons.water);
              return Column(
                children: tanks
                    .take(3)
                    .map((tank) => GestureDetector(
                          onTap: () => context.go('/tanks'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                radius: 20,
                                child: const Icon(Icons.water, color: Colors.blue, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: Text(tank.name,
                                      style: const TextStyle(
                                          color: Colors.black87, fontWeight: FontWeight.w600))),
                              Text('${tank.fishCapacity} peixes',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              const Icon(Icons.chevron_right, color: Colors.black26, size: 18),
                            ]),
                          ),
                        ))
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),

          const SizedBox(height: 24),

          // Latest water quality
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Última Leitura de Água',
                style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => context.go('/water-quality'),
              child: const Text('Ver todos →',
                  style: TextStyle(color: Color(0xFF13A538))),
            ),
          ]),
          const SizedBox(height: 8),
          wqAsync.when(
            data: (records) {
              if (records.isEmpty) return _emptyHint('Nenhuma leitura registrada.', Icons.science);
              final latest = records.last;
              Color phColor = latest.ph < 6.5 || latest.ph > 8.5
                  ? Colors.red
                  : (latest.ph < 7.0 || latest.ph > 8.0 ? Colors.orange : Colors.green);
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _metric('pH', latest.ph.toStringAsFixed(1), phColor),
                  _metric('Temp', '${latest.temperature.toStringAsFixed(1)}°C', Colors.blue),
                  _metric('O₂', '${latest.dissolvedOxygen.toStringAsFixed(1)} mg/L', Colors.lightBlue),
                ]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ]),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
    ]);
  }

  Widget _emptyHint(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        Icon(icon, color: Colors.grey.shade300, size: 28),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ]),
    );
  }
}

// ─── SaaS Admin Body ─────────────────────────────────────────────────────────

class _SaasAdminBody extends ConsumerWidget {
  const _SaasAdminBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansProvider);
    final tenantsAsync = ref.watch(tenantsProvider);
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(plansProvider);
        ref.invalidate(tenantsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          tenantsAsync.when(
            data: (tenants) => plansAsync.when(
              data: (plans) {
                final totalMrr = plans.fold<double>(0, (s, p) => s + p.priceMonthly);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VISÃO GERAL',
                        style: TextStyle(
                            color: Colors.black54, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _kpi('Tenants', '${tenants.length}', Icons.business, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _kpi('Planos', '${plans.length}', Icons.layers, Colors.purple)),
                    ]),
                    const SizedBox(height: 12),
                    _kpi('MRR Total', currencyFmt.format(totalMrr), Icons.trending_up, Colors.green, wide: true),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 28),
          const Text('Planos SaaS',
              style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          plansAsync.when(
            data: (plans) =>
                Column(children: plans.map((p) => _planCard(p, currencyFmt)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 28),
          const Text('Clientes Farm (Tenants)',
              style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          tenantsAsync.when(
            data: (tenants) => tenants.isEmpty
                ? const Text('Nenhum tenant.', style: TextStyle(color: Colors.black54))
                : Column(children: tenants.map((t) => _tenantCard(t)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e', style: const TextStyle(color: Colors.red)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, IconData icon, Color color, {bool wide = false}) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration:
              BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _planCard(SaasPlan plan, NumberFormat fmt) {
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green];
    final color = colors[plan.name.hashCode.abs() % colors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
            width: 4,
            height: 48,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(plan.name,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          Text('${plan.maxTanks} tanques · ${plan.maxUsers} usuários',
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ])),
        Text(fmt.format(plan.priceMonthly),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
    );
  }

  Widget _tenantCard(dynamic tenant) {
    String formatted = '';
    try {
      formatted = DateFormat('dd/MM/yyyy').format(DateTime.parse(tenant.createdAt));
    } catch (_) {}
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: Colors.indigo.shade50,
          child: const Icon(Icons.business, color: Colors.indigo, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tenant.name,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          if ((tenant.cnpj as String).isNotEmpty)
            Text('CNPJ: ${tenant.cnpj}',
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Ativo',
                style: TextStyle(
                    color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          if (formatted.isNotEmpty)
            Text(formatted, style: const TextStyle(color: Colors.black38, fontSize: 11)),
        ]),
      ]),
    );
  }
}

// ─── Drawer lateral ──────────────────────────────────────────────────────────

class _AppDrawer extends ConsumerWidget {
  final String role;
  final WidgetRef ref;
  const _AppDrawer({required this.role, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    final authState = watchRef.watch(authNotifierProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFF003366)),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
              child: Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white12,
                  child: const Icon(Icons.person, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    authState.email?.split('@').first ?? 'Usuário',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                    child: Text(role,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ])),
              ]),
            ),
          ),

          // Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _tile(context, Icons.dashboard, 'Dashboard', const Color(0xFF003366), () {
                  Navigator.pop(context);
                  context.go('/dashboard');
                }),

                if (role == 'SAAS_ADMIN') ...[
                  _section('Administrador'),
                  _tile(context, Icons.business, 'Tenants', Colors.indigo, () {
                    Navigator.pop(context); context.go('/tenants');
                  }),
                  _tile(context, Icons.local_shipping, 'Fornecedores', Colors.brown, () {
                    Navigator.pop(context); context.go('/suppliers');
                  }),
                ],

                if (role == 'FARM_OWNER' || role == 'CLIENT' || role == 'FIELD_OPERATOR') ...[                  
                  _section('Operacional'),
                  if (role != 'FIELD_OPERATOR') ...[
                    _tile(context, Icons.water, 'Tanques', Colors.blue, () {
                      Navigator.pop(context); context.go('/tanks');
                    }),
                    _tile(context, Icons.science, 'Qualidade da Água', Colors.teal, () {
                      Navigator.pop(context); context.go('/water-quality');
                    }),
                    _tile(context, Icons.restaurant, 'Alimentação', Colors.purple, () {
                      Navigator.pop(context); context.go('/feeding-records');
                    }),
                    _tile(context, Icons.inventory, 'Estoque', Colors.orange, () {
                      Navigator.pop(context); context.go('/inventory');
                    }),
                    _tile(context, Icons.agriculture, 'Colheitas', Colors.green, () {
                      Navigator.pop(context); context.go('/harvests');
                    }),
                  ],
                  if (role == 'FIELD_OPERATOR') ...[
                    _FieldOperatorDrawerItems(userId: authState.userId ?? '', context: context),
                  ],
                ],

                if (role == 'FARM_OWNER' || role == 'CLIENT') ...[
                  _section('Gestão'),
                  _tile(context, Icons.build, 'Manutenção', Colors.grey.shade700, () {
                    Navigator.pop(context); context.go('/maintenance');
                  }),
                  _tile(context, Icons.attach_money, 'Finanças', Colors.green.shade700, () {
                    Navigator.pop(context); context.go('/finances');
                  }),
                  _tile(context, Icons.people, 'Funcionários', Colors.indigo, () {
                    Navigator.pop(context); context.go('/employees');
                  }),
                ],
              ],
            ),
          ),

          const Divider(color: Colors.black12),
          _tile(context, Icons.logout, 'Sair', Colors.red, () {
            Navigator.pop(context);
            watchRef.read(authNotifierProvider.notifier).logout();
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
    );
  }
}

// ─── Field Operator Drawer Items (permission-aware) ───────────────────────────

class _FieldOperatorDrawerItems extends ConsumerWidget {
  final String userId;
  final BuildContext context;

  const _FieldOperatorDrawerItems({required this.userId, required this.context});

  static const _kFarmId = '55555555-5555-5555-5555-555555555555';

  static const _moduleRoutes = {
    'tanks':           ('/tanks',           Icons.water,                 'Tanques',           Colors.blue),
    'water_quality':   ('/water-quality',   Icons.science,               'Qualidade da Água', Colors.teal),
    'feeding_records': ('/feeding-records', Icons.restaurant,            'Alimentação',       Colors.purple),
    'inventory':       ('/inventory',       Icons.inventory,             'Estoque',           Colors.orange),
    'harvests':        ('/harvests',        Icons.agriculture,           'Colheitas',         Colors.green),
    'maintenance':     ('/maintenance',     Icons.build,                 'Manutenção',        Colors.grey),
  };

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    if (userId.isEmpty) return const SizedBox.shrink();

    final key = '$userId:$_kFarmId';
    final permsAsync = ref.watch(currentUserPermissionsProvider(key));

    return permsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) {
        // On error fall back to showing all operational modules
        return Column(
          children: _moduleRoutes.entries.map((e) {
            final (route, icon, label, color) = e.value;
            return ListTile(
              onTap: () { Navigator.pop(context); context.go(route); },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
            );
          }).toList(),
        );
      },
      data: (perms) {
        final permMap = {for (final p in perms) p.moduleName: p.isEnabled};
        return Column(
          children: _moduleRoutes.entries.map((e) {
            final moduleKey = e.key;
            final (route, icon, label, color) = e.value;
            final enabled = permMap[moduleKey] ?? true;
            if (!enabled) return const SizedBox.shrink();
            return ListTile(
              onTap: () { Navigator.pop(context); context.go(route); },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
            );
          }).toList(),
        );
      },
    );
  }
}
