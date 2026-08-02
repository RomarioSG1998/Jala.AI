import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/maintenance/data/maintenance_model.dart';

class MaintenanceRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  MaintenanceRepository(this._dio, this._tokenStorage);

  Future<String> _getFarmId() async {
    final farmId = await _tokenStorage.getFarmId();
    if (farmId == null || farmId.isEmpty) {
      return '55555555-5555-5555-5555-555555555555';
    }
    return farmId;
  }

  List<dynamic> _extractCollection(dynamic data) {
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    if (data is List) {
      return data;
    }
    return const [];
  }

  Future<List<MaintenanceTask>> getTasks() async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/maintenance/farm/$farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(MaintenanceTask.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load maintenance tasks (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load maintenance tasks: $e');
    }
  }

  Future<MaintenanceTask> createTask(Map<String, dynamic> taskData) async {
    try {
      final farmId = await _getFarmId();
      taskData['farmId'] = farmId;
      final response = await _dio.post('/api/maintenance', data: taskData);
      return MaintenanceTask.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<MaintenanceTask> updateTask(String id, Map<String, dynamic> data) async {
    try {
      final farmId = await _getFarmId();
      data['farmId'] = farmId;
      final response = await _dio.put('/api/maintenance/$id', data: data);
      return MaintenanceTask.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final farmId = await _getFarmId();
      await _dio.delete('/api/maintenance/$taskId?farmId=$farmId');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return MaintenanceRepository(dio, tokenStorage);
});
