import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/employee_model.dart';
import '../data/employee_repository.dart';

import 'package:frontend_flutter/features/tanks/data/tank_repository.dart';

class EmployeesNotifier extends AsyncNotifier<List<Employee>> {
  late final EmployeeRepository _repository;
  PlanLimitException? lastPlanLimitError;

  @override
  Future<List<Employee>> build() async {
    _repository = ref.watch(employeeRepositoryProvider);
    return _repository.getEmployees();
  }

  Future<bool> registerEmployee(String name, String email, String password) async {
    lastPlanLimitError = null;
    try {
      final newEmp = await _repository.registerEmployee(name, email, password);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newEmp]);
      }
      return true;
    } on PlanLimitException catch (e) {
      lastPlanLimitError = e;
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEmployee(String id, String name, String email, String? password) async {
    try {
      final updatedEmp = await _repository.updateEmployee(id, name, email, password);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((emp) => emp.id == id ? updatedEmp : emp).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteEmployee(String id) async {
    try {
      await _repository.deleteEmployee(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((emp) => emp.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final employeesProvider = AsyncNotifierProvider<EmployeesNotifier, List<Employee>>(() {
  return EmployeesNotifier();
});
