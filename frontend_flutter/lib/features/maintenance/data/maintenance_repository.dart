import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/maintenance/data/maintenance_model.dart';

class MaintenanceRepository {
  final Dio _dio;

  MaintenanceRepository(this._dio);

  final String _farmId = '55555555-5555-5555-5555-555555555555';

  Future<List<MaintenanceTask>> getTasks() async {
    try {
      final response = await _dio.get('/api/maintenance/farm/$_farmId');
      final data = response.data;
      if (data != null && data['content'] != null) {
        final List<dynamic> content = data['content'];
        return content.map((json) => MaintenanceTask.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load maintenance tasks: $e');
    }
  }

  Future<MaintenanceTask> createTask(Map<String, dynamic> taskData) async {
    try {
      taskData['farmId'] = _farmId;
      final response = await _dio.post('/api/maintenance', data: taskData);
      return MaintenanceTask.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _dio.delete('/api/maintenance/$taskId?farmId=$_farmId');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MaintenanceRepository(dio);
});
