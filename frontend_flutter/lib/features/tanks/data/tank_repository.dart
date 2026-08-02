import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/tanks/data/tank_model.dart';
import 'package:frontend_flutter/features/tanks/data/biometrics_model.dart';

/// Thrown when the backend returns HTTP 402 (plan limit exceeded).
class PlanLimitException implements Exception {
  final int maxAllowed;
  PlanLimitException(this.maxAllowed);
  @override
  String toString() => 'PlanLimitException(maxAllowed: $maxAllowed)';
}

class TankRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  TankRepository(this._dio, this._tokenStorage);

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

  Future<List<Tank>> getTanks() async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/tanks/farm/$farmId');
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
      final farmId = await _getFarmId();
      tankData['farmId'] = farmId; // Inject user's farmId
      final response = await _dio.post('/api/tanks', data: tankData);
      return Tank.fromJson(response.data);
    } on DioException catch (e) {
      // HTTP 402 = plan limit exceeded
      if (e.response?.statusCode == 402) {
        final data = e.response?.data;
        final maxAllowed = (data is Map && data['maxAllowed'] != null)
            ? (data['maxAllowed'] as num).toInt()
            : 3;
        throw PlanLimitException(maxAllowed);
      }
      throw Exception('Failed to create tank: ${e.message}');
    } catch (e) {
      if (e is PlanLimitException) rethrow;
      throw Exception('Failed to create tank: $e');
    }
  }

  Future<Tank> updateTank(String tankId, Map<String, dynamic> tankData) async {
    try {
      final farmId = await _getFarmId();
      tankData['farmId'] = farmId;
      final response = await _dio.put('/api/tanks/$tankId', data: tankData);
      return Tank.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update tank: $e');
    }
  }

  Future<void> deleteTank(String tankId) async {
    try {
      final farmId = await _getFarmId();
      await _dio.delete('/api/tanks/$tankId?farmId=$farmId');
    } catch (e) {
      throw Exception('Failed to delete tank: $e');
    }
  }

  // ─── Biometrics Endpoints ───
  Future<List<BiometricsRecord>> getBiometrics(String tankId) async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/biometrics/tank/$tankId?farmId=$farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(BiometricsRecord.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Failed to load biometrics: $e');
    }
  }

  Future<BiometricsRecord> createBiometricsRecord(String tankId, int weightG, [String? recordDate]) async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.post('/api/biometrics', data: {
        'farmId': farmId,
        'tankId': tankId,
        'weightG': weightG,
        'recordDate': recordDate,
      });
      return BiometricsRecord.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create biometrics: $e');
    }
  }

  Future<void> deleteBiometricsRecord(String id) async {
    try {
      final farmId = await _getFarmId();
      await _dio.delete('/api/biometrics/$id?farmId=$farmId');
    } catch (e) {
      throw Exception('Failed to delete biometrics record: $e');
    }
  }
}

final tankRepositoryProvider = Provider<TankRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return TankRepository(dio, tokenStorage);
});
