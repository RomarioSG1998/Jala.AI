import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';

class SaasAdminRepository {
  final Dio _dio;

  SaasAdminRepository(this._dio);

  Future<List<SaasPlan>> getPlans() async {
    try {
      final response = await _dio.get('/api/saas-plans');
      if (response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => SaasPlan.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    try {
      final response = await _dio.get('/api/billing/plans/details');
      if (response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => SaasPlan.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      throw Exception('Erro ao carregar planos atualizados do backend: $e');
    }

    return [];
  }

  Future<List<FarmTenant>> getAllTenants() async {
    try {
      const johnUserId = '44444444-4444-4444-4444-444444444444';
      final response = await _dio.get('/api/tenants/owner/$johnUserId');
      final data = response.data;
      if (data != null && data['content'] != null) {
        final List<dynamic> content = data['content'];
        return content.map((json) => FarmTenant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load tenants: $e');
    }
  }

  Future<bool> createTenant(String name, String cnpj) async {
    try {
      const johnUserId = '44444444-4444-4444-4444-444444444444';
      await _dio.post(
        '/api/tenants',
        data: {
          'name': name,
          'cnpj': cnpj,
          'ownerId': johnUserId,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<SaasMasterOverview> getMasterOverview() async {
    try {
      final response = await _dio.get('/api/saas/master/overview');
      if (response.data != null && response.data is Map<String, dynamic>) {
        return SaasMasterOverview.fromJson(response.data);
      }
    } catch (_) {}
    return SaasMasterOverview(
      totalFarms: 0,
      activeSubscriptions: 0,
      totalTanks: 0,
      estimatedMRR: 0.0,
      estimatedARR: 0.0,
      upToDateTenantsCount: 0,
      pastDueTenantsCount: 0,
      freeTenantsCount: 0,
      b2bEscrowVolume: 0.0,
    );
  }

  Future<List<TenantFinancialStatus>> getTenantsFinancialReport() async {
    try {
      final response = await _dio.get('/api/saas/master/financial-report');
      if (response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => TenantFinancialStatus.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}

final saasAdminRepositoryProvider = Provider<SaasAdminRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SaasAdminRepository(dio);
});
