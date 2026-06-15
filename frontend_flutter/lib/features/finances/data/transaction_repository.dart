import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/finances/data/transaction_model.dart';

class TransactionRepository {
  final Dio _dio;

  TransactionRepository(this._dio);

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

  Future<List<FinancialTransaction>> getTransactions() async {
    try {
      final response = await _dio.get('/api/finances/farm/$_farmId');
      final rawList = _extractCollection(response.data);
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(FinancialTransaction.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load transactions (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  Future<FinancialTransaction> createTransaction({
    required String type,
    required double amount,
    String? category,
    String? clientName,
    String? fishSpecies,
    double? quantityKg,
    String? transactionDate,
  }) async {
    try {
      final response = await _dio.post(
        '/api/finances',
        data: {
          'farmId': _farmId,
          'type': type,
          'amount': amount,
          'category': category,
          'clientName': clientName,
          'fishSpecies': fishSpecies,
          'quantityKg': quantityKg,
          'transactionDate': transactionDate,
        },
      );
      return FinancialTransaction.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  Future<FinancialTransaction> updateTransaction({
    required String id,
    required String type,
    required double amount,
    String? category,
    String? clientName,
    String? fishSpecies,
    double? quantityKg,
    String? transactionDate,
  }) async {
    try {
      final response = await _dio.put(
        '/api/finances/$id',
        data: {
          'farmId': _farmId,
          'type': type,
          'amount': amount,
          'category': category,
          'clientName': clientName,
          'fishSpecies': fishSpecies,
          'quantityKg': quantityKg,
          'transactionDate': transactionDate,
        },
      );
      return FinancialTransaction.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/api/finances/$id?farmId=$_farmId');
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TransactionRepository(dio);
});
