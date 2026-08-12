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
    List<FarmTenant> tenants = [];
    try {
      final response = await _dio.get('/api/tenants/all');
      final data = response.data;
      if (data != null && data['content'] != null) {
        final List<dynamic> content = data['content'];
        tenants = content.map((json) => FarmTenant.fromJson(json)).toList();
      } else if (data is List) {
        tenants = data.map((json) => FarmTenant.fromJson(json)).toList();
      }
    } catch (_) {}

    try {
      final report = await getTenantsFinancialReport();
      if (report.isNotEmpty) {
        final existingFarmIds = tenants.map((t) => t.id).toSet();
        final existingOwnerEmails = tenants.map((t) => t.ownerEmail).toSet();

        for (final r in report) {
          final farmId = r.farmId ?? '';
          if (farmId.isNotEmpty && !existingFarmIds.contains(farmId)) {
            tenants.add(FarmTenant(
              id: farmId,
              name: r.farmName,
              cnpj: r.cnpj,
              ownerId: r.ownerId ?? '',
              ownerName: r.ownerName,
              ownerEmail: r.ownerEmail,
              userActive: r.userActive,
              createdAt: '',
            ));
          } else if (farmId.isEmpty && !existingOwnerEmails.contains(r.ownerEmail)) {
            tenants.add(FarmTenant(
              id: r.ownerId ?? '',
              name: r.farmName,
              cnpj: r.cnpj,
              ownerId: r.ownerId ?? '',
              ownerName: r.ownerName,
              ownerEmail: r.ownerEmail,
              userActive: r.userActive,
              createdAt: '',
            ));
          }
        }
      }
    } catch (_) {}

    return tenants;
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

  Future<bool> toggleUserActiveStatus(String userId) async {
    try {
      final response = await _dio.post('/api/saas/master/users/$userId/toggle-active');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

final saasAdminRepositoryProvider = Provider<SaasAdminRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SaasAdminRepository(dio);
});
