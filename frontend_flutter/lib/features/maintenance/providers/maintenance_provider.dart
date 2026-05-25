import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/maintenance/data/maintenance_model.dart';
import 'package:frontend_flutter/features/maintenance/data/maintenance_repository.dart';

class MaintenanceNotifier extends AsyncNotifier<List<MaintenanceTask>> {
  late final MaintenanceRepository _repository;

  @override
  Future<List<MaintenanceTask>> build() async {
    _repository = ref.watch(maintenanceRepositoryProvider);
    return _repository.getTasks();
  }

  Future<void> refreshTasks() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.getTasks());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createTask(
      String tankId, String description, String status, String scheduledDate) async {
    try {
      final task = await _repository.createTask({
        'tankId': tankId,
        'description': description,
        'status': status,
        'scheduledDate': scheduledDate,
      });
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, task]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((t) => t.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final maintenanceProvider =
    AsyncNotifierProvider<MaintenanceNotifier, List<MaintenanceTask>>(() {
  return MaintenanceNotifier();
});
