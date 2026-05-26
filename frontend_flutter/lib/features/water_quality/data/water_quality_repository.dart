import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_model.dart';

class WaterQualityRepository {
  final Dio _dio;

  WaterQualityRepository(this._dio);

  // Hardcoded test farm ID for now.
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

  Future<List<WaterQuality>> getRecords() async {
    try {
      final response = await _dio.get('/api/water-quality/farm/$_farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(WaterQuality.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load water quality records (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load water quality records: $e');
    }
  }

  Future<WaterQuality?> getLatestByTankId(String tankId) async {
    try {
      final response = await _dio.get('/api/water-quality/tank/$tankId/latest?farmId=$_farmId');
      if (response.data != null) {
        return WaterQuality.fromJson(response.data);
      }
      return null;
    } catch (e) {
      // Return null if not found (e.g., 400/404/500 on no reading)
      return null;
    }
  }

  Future<WaterQuality> createRecord(Map<String, dynamic> logData) async {
    try {
      logData['farmId'] = _farmId;
      final response = await _dio.post('/api/water-quality', data: logData);
      return WaterQuality.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create water quality record: $e');
    }
  }

  Future<WaterQuality> updateRecord(String id, Map<String, dynamic> data) async {
    try {
      data['farmId'] = _farmId;
      final response = await _dio.put('/api/water-quality/$id', data: data);
      return WaterQuality.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update water quality record: $e');
    }
  }

  Future<void> deleteRecord(String logId) async {
    try {
      await _dio.delete('/api/water-quality/$logId?farmId=$_farmId');
    } catch (e) {
      throw Exception('Failed to delete water quality record: $e');
    }
  }
}

final waterQualityRepositoryProvider = Provider<WaterQualityRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return WaterQualityRepository(dio);
});
