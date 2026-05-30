import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/suppliers/data/supplier_model.dart';

class SupplierRepository {
  final Dio _dio;

  SupplierRepository(this._dio);

  Future<List<NationalSupplier>> getSuppliers() async {
    try {
      final response = await _dio.get('/api/suppliers');
      final List<dynamic> rawList = response.data ?? [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(NationalSupplier.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load suppliers (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load suppliers: $e');
    }
  }

  Future<NationalSupplier> createSupplier(String companyName, String cnpj, String supplyType) async {
    try {
      final response = await _dio.post(
        '/api/suppliers',
        data: {
          'companyName': companyName,
          'cnpj': cnpj,
          'supplyType': supplyType,
        },
      );
      return NationalSupplier.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create supplier: $e');
    }
  }

  Future<NationalSupplier> approveSupplier(String id) async {
    try {
      final response = await _dio.put('/api/suppliers/$id/approve');
      return NationalSupplier.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to approve supplier: $e');
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _dio.delete('/api/suppliers/$id');
    } catch (e) {
      throw Exception('Failed to delete supplier: $e');
    }
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SupplierRepository(dio);
});
