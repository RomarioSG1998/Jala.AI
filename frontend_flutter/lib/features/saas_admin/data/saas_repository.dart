import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/saas_admin/data/saas_models.dart';

class SaasAdminRepository {
  final Dio _dio;

  SaasAdminRepository(this._dio);

  Future<List<SaasPlan>> getPlans() async {
    try {
      final response = await _dio.get('/api/billing/plans/details');
      if (response.data is List && (response.data as List).isNotEmpty) {
        final List<dynamic> data = response.data;
        return data.map((json) => SaasPlan.fromJson(json)).toList();
      }
    } catch (_) {}

    try {
      final response = await _dio.get('/api/saas-plans');
      if (response.data is List && (response.data as List).isNotEmpty) {
        final List<dynamic> data = response.data;
        return data.map((json) => SaasPlan.fromJson(json)).toList();
      }
    } catch (_) {}

    return [
      SaasPlan(id: 'free', name: 'Plano Gratuito', maxTanks: 3, maxUsers: 2, priceMonthly: 0.0),
      SaasPlan(id: 'starter', name: 'Plano Starter', maxTanks: 10, maxUsers: 5, priceMonthly: 29.90),
      SaasPlan(id: 'pro', name: 'Plano Profissional', maxTanks: 30, maxUsers: 15, priceMonthly: 59.90),
    ];
  }

  // Returns ALL tenants from the system (global admin view)
  // NOTE: Backend currently only supports querying by ownerId.
  // As a temporary workaround for the admin view, we return John's farm.
  // In a production system, a dedicated admin endpoint would return all farms.
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
}

final saasAdminRepositoryProvider = Provider<SaasAdminRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SaasAdminRepository(dio);
});
