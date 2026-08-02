import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_model.dart';

class WaterQualityRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  WaterQualityRepository(this._dio, this._tokenStorage);

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

  Future<List<WaterQuality>> getRecords() async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/water-quality/farm/$farmId');
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
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/water-quality/tank/$tankId/latest?farmId=$farmId');
      if (response.data != null) {
        return WaterQuality.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<WaterQuality> createRecord(Map<String, dynamic> logData) async {
    try {
      final farmId = await _getFarmId();
      logData['farmId'] = farmId;
      final response = await _dio.post('/api/water-quality', data: logData);
      return WaterQuality.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create water quality record: $e');
    }
  }

  Future<WaterQuality> updateRecord(
    String id,
    String tankId,
    double ph,
    double temperature,
    double dissolvedOxygen, {
    double? ammonia,
    double? nitrite,
    double? alkalinity,
    double? hardness,
    double? solids,
  }) async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.put(
        '/api/water-quality/$id',
        data: {
          'farmId': farmId,
          'tankId': tankId,
          'ph': ph,
          'temperature': temperature,
          'dissolvedOxygen': dissolvedOxygen,
          'ammonia': ammonia,
          'nitrite': nitrite,
          'alkalinity': alkalinity,
          'hardness': hardness,
          'solids': solids,
        },
      );
      return WaterQuality.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to update water quality record');
    } catch (e) {
      throw Exception('Failed to update water quality record: $e');
    }
  }

  Future<void> deleteRecord(String logId) async {
    try {
      final farmId = await _getFarmId();
      await _dio.delete('/api/water-quality/$logId?farmId=$farmId');
    } catch (e) {
      throw Exception('Failed to delete water quality record: $e');
    }
  }
}

final waterQualityRepositoryProvider = Provider<WaterQualityRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return WaterQualityRepository(dio, tokenStorage);
});
