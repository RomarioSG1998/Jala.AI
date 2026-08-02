import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'employee_model.dart';
import 'package:frontend_flutter/features/tanks/data/tank_repository.dart';

class EmployeeRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  EmployeeRepository(this._dio, this._tokenStorage);

  Future<String> _getFarmId() async {
    final farmId = await _tokenStorage.getFarmId();
    if (farmId == null || farmId.isEmpty) {
      return '55555555-5555-5555-5555-555555555555';
    }
    return farmId;
  }

  Future<List<Employee>> getEmployees() async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/employees/farm/$farmId');
      final list = response.data as List<dynamic>;
      return list.map((item) => Employee.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load employees: $e');
    }
  }

  Future<Employee> registerEmployee(String name, String email, String password) async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.post(
        '/api/employees',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'farmId': farmId,
        },
      );
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 402) {
        final data = e.response?.data;
        final maxAllowed = (data is Map && data['maxAllowed'] != null) ? (data['maxAllowed'] as num).toInt() : 2;
        throw PlanLimitException(maxAllowed);
      }
      throw Exception('Failed to register employee: $e');
    }
  }

  Future<Employee> updateEmployee(String id, String name, String email, String? password) async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.put(
        '/api/employees/$id',
        data: {
          'name': name,
          'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
          'farmId': farmId,
        },
      );
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update employee: $e');
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      final farmId = await _getFarmId();
      await _dio.delete('/api/employees/$id/farm/$farmId');
    } catch (e) {
      throw Exception('Failed to delete employee: $e');
    }
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return EmployeeRepository(dio, tokenStorage);
});
