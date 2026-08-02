import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/mortality/data/mortality_model.dart';

class MortalityRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  MortalityRepository(this._dio, this._tokenStorage);

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

  Future<List<MortalityRecord>> getRecords() async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/mortality/farm/$farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(MortalityRecord.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load mortality records (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load mortality records: $e');
    }
  }

  Future<List<MortalityRecord>> getRecordsByTank(String tankId) async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/mortality/tank/$tankId?farmId=$farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(MortalityRecord.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load mortality records for tank (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load mortality records for tank: $e');
    }
  }

  Future<MortalityRecord> createRecord(Map<String, dynamic> data) async {
    try {
      final farmId = await _getFarmId();
      data['farmId'] = farmId;
      final response = await _dio.post('/api/mortality', data: data);
      return MortalityRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to create mortality record');
    } catch (e) {
      throw Exception('Failed to create mortality record: $e');
    }
  }

  Future<MortalityRecord> updateRecord(String id, Map<String, dynamic> data) async {
    try {
      final farmId = await _getFarmId();
      data['farmId'] = farmId;
      final response = await _dio.put('/api/mortality/$id', data: data);
      return MortalityRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to update mortality record');
    } catch (e) {
      throw Exception('Failed to update mortality record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final farmId = await _getFarmId();
      await _dio.delete('/api/mortality/$id?farmId=$farmId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to delete mortality record');
    } catch (e) {
      throw Exception('Failed to delete mortality record: $e');
    }
  }
}

final mortalityRepositoryProvider = Provider<MortalityRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return MortalityRepository(dio, tokenStorage);
});
