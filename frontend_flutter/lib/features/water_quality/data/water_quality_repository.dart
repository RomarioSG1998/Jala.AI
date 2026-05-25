import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_model.dart';

class WaterQualityRepository {
  final Dio _dio;

  WaterQualityRepository(this._dio);

  Future<List<WaterQuality>> getRecords() async {
    try {
      final response = await _dio.get('/api/water-quality');
      final List<dynamic> data = response.data;
      return data.map((json) => WaterQuality.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load water quality records: $e');
    }
  }
}

final waterQualityRepositoryProvider = Provider<WaterQualityRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return WaterQualityRepository(dio);
});
