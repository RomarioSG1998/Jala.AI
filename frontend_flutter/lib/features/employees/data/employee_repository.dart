import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'employee_model.dart';

class EmployeeRepository {
  final Dio _dio;
  final String _farmId = '55555555-5555-5555-5555-555555555555';

  EmployeeRepository(this._dio);

  Future<List<Employee>> getEmployees() async {
    try {
      final response = await _dio.get('/api/employees/farm/$_farmId');
      final list = response.data as List<dynamic>;
      return list.map((item) => Employee.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load employees: $e');
    }
  }

  Future<Employee> registerEmployee(String name, String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/employees',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'farmId': _farmId,
        },
      );
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to register employee: $e');
    }
  }

  Future<Employee> updateEmployee(String id, String name, String email, String? password) async {
    try {
      final response = await _dio.put(
        '/api/employees/$id',
        data: {
          'name': name,
          'email': email,
          if (password != null && password.isNotEmpty) 'password': password,
          'farmId': _farmId,
        },
      );
      return Employee.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update employee: $e');
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      await _dio.delete('/api/employees/$id/farm/$_farmId');
    } catch (e) {
      throw Exception('Failed to delete employee: $e');
    }
  }
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return EmployeeRepository(dio);
});
