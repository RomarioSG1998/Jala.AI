import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/feeding_records/data/feeding_record_model.dart';

class FeedingRecordRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  FeedingRecordRepository(this._dio, this._tokenStorage);

  Future<String> _getFarmId() async {
    final farmId = await _tokenStorage.getFarmId();
    if (farmId == null || farmId.isEmpty) {
      return '55555555-5555-5555-5555-555555555555';
    }
    return farmId;
  }

  Future<String?> _getUserId() async {
    return await _tokenStorage.getUserId();
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

  Future<List<FeedingRecord>> getRecords() async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/feeding-records/farm/$farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(FeedingRecord.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load feeding records (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load feeding records: $e');
    }
  }

  Future<FeedingRecord> createRecord(Map<String, dynamic> data) async {
    try {
      final farmId = await _getFarmId();
      final userId = await _getUserId();
      data['farmId'] = farmId;
      data['userId'] ??= userId;
      final response = await _dio.post('/api/feeding-records', data: data);
      return FeedingRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to create feeding record');
    } catch (e) {
      throw Exception('Failed to create feeding record: $e');
    }
  }

  Future<FeedingRecord> updateRecord(String id, Map<String, dynamic> data) async {
    try {
      final farmId = await _getFarmId();
      final userId = await _getUserId();
      data['farmId'] = farmId;
      data['userId'] ??= userId;
      final response = await _dio.put('/api/feeding-records/$id', data: data);
      return FeedingRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to update feeding record');
    } catch (e) {
      throw Exception('Failed to update feeding record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final farmId = await _getFarmId();
      await _dio.delete('/api/feeding-records/$id?farmId=$farmId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to delete feeding record');
    } catch (e) {
      throw Exception('Failed to delete feeding record: $e');
    }
  }
}

final feedingRecordRepositoryProvider = Provider<FeedingRecordRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return FeedingRecordRepository(dio, tokenStorage);
});
