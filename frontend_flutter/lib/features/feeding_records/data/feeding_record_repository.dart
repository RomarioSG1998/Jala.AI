import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/feeding_records/data/feeding_record_model.dart';

class FeedingRecordRepository {
  final Dio _dio;

  FeedingRecordRepository(this._dio);

  // Hardcoded test IDs matching database seeding
  final String _farmId = '55555555-5555-5555-5555-555555555555';
  final String _userId = '11111111-1111-1111-1111-111111111111';

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
      final response = await _dio.get('/api/feeding-records/farm/$_farmId');
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
      data['farmId'] = _farmId;
      data['userId'] = _userId;
      final response = await _dio.post('/api/feeding-records', data: data);
      return FeedingRecord.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to create feeding record');
    } catch (e) {
      throw Exception('Failed to create feeding record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      await _dio.delete('/api/feeding-records/$id?farmId=$_farmId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to delete feeding record');
    } catch (e) {
      throw Exception('Failed to delete feeding record: $e');
    }
  }
}

final feedingRecordRepositoryProvider = Provider<FeedingRecordRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FeedingRecordRepository(dio);
});
