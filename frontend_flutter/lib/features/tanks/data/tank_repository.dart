import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/tanks/data/tank_model.dart';

class TankRepository {
  final Dio _dio;

  TankRepository(this._dio);

  // Hardcoded test farm ID for now.
  // In a real application, this would be fetched from AuthProvider state.
  final String _farmId = '55555555-5555-5555-5555-555555555555';

  Future<List<Tank>> getTanks() async {
    try {
      final response = await _dio.get('/api/tanks/farm/$_farmId');
      final data = response.data;
      if (data != null && data['content'] != null) {
        // Spring Boot Pageable response
        final List<dynamic> content = data['content'];
        return content.map((json) => Tank.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load tanks: $e');
    }
  }

  Future<Tank> createTank(Map<String, dynamic> tankData) async {
    try {
      tankData['farmId'] = _farmId; // Inject required farmId
      final response = await _dio.post('/api/tanks', data: tankData);
      return Tank.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create tank: $e');
    }
  }

  Future<void> deleteTank(String tankId) async {
    try {
      await _dio.delete('/api/tanks/$tankId?farmId=$_farmId');
    } catch (e) {
      throw Exception('Failed to delete tank: $e');
    }
  }
}

final tankRepositoryProvider = Provider<TankRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TankRepository(dio);
});
