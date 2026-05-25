import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/harvests/data/harvest_model.dart';

class HarvestRepository {
  final Dio _dio;

  HarvestRepository(this._dio);

  final String _farmId = '55555555-5555-5555-5555-555555555555';

  Future<List<Harvest>> getHarvests() async {
    try {
      final response = await _dio.get('/api/harvests/farm/$_farmId');
      final data = response.data;
      if (data != null && data['content'] != null) {
        final List<dynamic> content = data['content'];
        return content.map((json) => Harvest.fromJson(json)).toList();
      }
      return [];
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
