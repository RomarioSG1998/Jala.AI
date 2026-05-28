import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/employees/data/employee_permission_model.dart';
import 'package:frontend_flutter/features/employees/data/employee_permission_repository.dart';

// ─── Provider: current logged-in user's own permissions ─────────────────────
// Used by FIELD_OPERATOR to filter navigation drawer/more menu.
// Keyed by "employeeId:farmId"
final currentUserPermissionsProvider =
    FutureProvider.family<List<EmployeePermission>, String>((ref, key) async {
  final parts = key.split(':');
  final employeeId = parts[0];
  final farmId = parts[1];
  return ref
      .read(employeePermissionRepositoryProvider)
      .getPermissions(employeeId, farmId);
});

// ─── Notifier: permissions panel for a specific employee ─────────────────────
class EmployeePermissionsNotifier
    extends Notifier<AsyncValue<List<EmployeePermission>>> {
  final String arg;
  EmployeePermissionsNotifier(this.arg);

  late final EmployeePermissionRepository _repo;
  late final String employeeId;
  late final String farmId;

  @override
  AsyncValue<List<EmployeePermission>> build() {
    _repo = ref.read(employeePermissionRepositoryProvider);
    final parts = arg.split(':');
    employeeId = parts[0];
    farmId = parts[1];
    
    // Schedule state loading
    Future.microtask(() => _load());
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final perms = await _repo.getPermissions(employeeId, farmId);
      state = AsyncValue.data(perms);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggle(String moduleName, bool isEnabled) async {
    try {
      final updated = await _repo.setPermission(employeeId, farmId, moduleName, isEnabled);
      state = state.whenData((perms) => [
            for (final p in perms)
              if (p.moduleName == updated.moduleName) updated else p
          ]);
    } catch (_) {
      // Re-load on error to ensure consistent state
      await _load();
    }
  }
}

/// Provider keyed by "employeeId:farmId"
final employeePermissionsProvider = NotifierProvider.family<
    EmployeePermissionsNotifier,
    AsyncValue<List<EmployeePermission>>,
    String>(EmployeePermissionsNotifier.new);
