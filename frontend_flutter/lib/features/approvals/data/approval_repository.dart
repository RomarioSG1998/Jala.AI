import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/approvals/data/approval_model.dart';

class ApprovalRepository {
  final Dio _dio;

  ApprovalRepository(this._dio);

  // Consistent with the rest of the application's mock farm ID
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

  Future<List<ApprovalRequestModel>> getApprovalRequests() async {
    try {
      final response = await _dio.get('/api/approvals/farm/$_farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(ApprovalRequestModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load approvals (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load approvals: $e');
    }
  }

  Future<ApprovalRequestModel> resolveApprovalRequest(String requestId, String status) async {
    try {
      final response = await _dio.put(
        '/api/approvals/$requestId/resolve',
        queryParameters: {'status': status},
      );
      return ApprovalRequestModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to resolve approval (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to resolve approval: $e');
    }
  }
}

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ApprovalRepository(dio);
});
