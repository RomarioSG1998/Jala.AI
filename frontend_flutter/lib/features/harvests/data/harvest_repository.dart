import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/harvests/data/harvest_model.dart';

class HarvestRepository {
  final Dio _dio;

  HarvestRepository(this._dio);

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

  Future<List<Harvest>> getHarvests() async {
    try {
      final response = await _dio.get('/api/harvests/farm/$_farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(Harvest.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load harvests (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load harvests: $e');
    }
  }

  Future<Harvest> logHarvest(Map<String, dynamic> data) async {
    try {
      data['farmId'] = _farmId;
      final response = await _dio.post('/api/harvests', data: data);
      return Harvest.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to log harvest: $e');
    }
  }

  Future<void> deleteHarvest(String harvestId) async {
    try {
      await _dio.delete('/api/harvests/$harvestId?farmId=$_farmId');
    } catch (e) {
      throw Exception('Failed to delete harvest: $e');
    }
  }
}

final harvestRepositoryProvider = Provider<HarvestRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HarvestRepository(dio);
});
