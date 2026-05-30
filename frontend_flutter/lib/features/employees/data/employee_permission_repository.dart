import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/employees/data/employee_permission_model.dart';

class EmployeePermissionRepository {
  final Dio _dio;

  EmployeePermissionRepository(this._dio);

  /// Load all module permissions for an employee in a farm.
  /// The backend initializes any missing modules as enabled on first call.
  Future<List<EmployeePermission>> getPermissions(String employeeId, String farmId) async {
    try {
      final response =
          await _dio.get('/api/employees/$employeeId/farm/$farmId/permissions');
      final list = (response.data as List<dynamic>).cast<Map<String, dynamic>>();
      return list.map(EmployeePermission.fromJson).toList();
    } on DioException catch (e) {
      throw Exception('Erro ao carregar permissões (${e.response?.statusCode})');
    }
  }

  /// Toggle a single module for an employee.
  Future<EmployeePermission> setPermission(
      String employeeId, String farmId, String moduleName, bool isEnabled) async {
    try {
      final response = await _dio.put(
        '/api/employees/$employeeId/farm/$farmId/permissions/$moduleName',
        data: {'isEnabled': isEnabled},
      );
      return EmployeePermission.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
          'Erro ao atualizar permissão (${e.response?.statusCode})');
    }
  }
}

final employeePermissionRepositoryProvider =
    Provider<EmployeePermissionRepository>((ref) {
  return EmployeePermissionRepository(ref.watch(dioProvider));
});
