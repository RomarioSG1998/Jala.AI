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

  List<dynamic> _extractCollection(dynamic data) {
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    if (data is List) {
      return data;
    }
    return const [];
  }

  Future<List<Tank>> getTanks() async {
    try {
      final response = await _dio.get('/api/tanks/farm/$_farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(Tank.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load tanks (HTTP ${e.response?.statusCode ?? 'unknown'}).');
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

  Future<Tank> updateTank(String tankId, Map<String, dynamic> tankData) async {
    try {
      tankData['farmId'] = _farmId; // Inject required farmId
      final response = await _dio.put('/api/tanks/$tankId', data: tankData);
      return Tank.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update tank: $e');
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
