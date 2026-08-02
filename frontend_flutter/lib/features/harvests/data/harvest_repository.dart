import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/harvests/data/harvest_model.dart';

class HarvestRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  HarvestRepository(this._dio, this._tokenStorage);

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

  Future<List<Harvest>> getHarvests() async {
    try {
      final farmId = await _getFarmId();
      final response = await _dio.get('/api/harvests/farm/$farmId');
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
      final farmId = await _getFarmId();
      data['farmId'] = farmId;
      final response = await _dio.post('/api/harvests', data: data);
      return Harvest.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to log harvest: $e');
    }
  }

  Future<Harvest> updateHarvest(String id, Map<String, dynamic> data) async {
    try {
      final farmId = await _getFarmId();
      data['farmId'] = farmId;
      final response = await _dio.put('/api/harvests/$id', data: data);
      return Harvest.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update harvest: $e');
    }
  }

  Future<void> deleteHarvest(String harvestId) async {
    try {
      final farmId = await _getFarmId();
      await _dio.delete('/api/harvests/$harvestId?farmId=$farmId');
    } catch (e) {
      throw Exception('Failed to delete harvest: $e');
    }
  }
}

final harvestRepositoryProvider = Provider<HarvestRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return HarvestRepository(dio, tokenStorage);
});
