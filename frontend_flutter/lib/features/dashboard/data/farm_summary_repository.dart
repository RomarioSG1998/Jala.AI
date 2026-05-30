import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/dashboard/data/farm_summary_model.dart';

class FarmSummaryRepository {
  final Dio _dio;

  FarmSummaryRepository(this._dio);

  final String _farmId = '55555555-5555-5555-5555-555555555555';

  Future<FarmSummary> getSummary() async {
    return getSummaryForFarm(_farmId);
  }

  Future<FarmSummary> getSummaryForFarm(String farmId) async {
    try {
      final response = await _dio.get('/api/farms/$farmId/summary');
      return FarmSummary.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load farm summary for $farmId: $e');
    }
  }
}

final farmSummaryRepositoryProvider = Provider<FarmSummaryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FarmSummaryRepository(dio);
});
