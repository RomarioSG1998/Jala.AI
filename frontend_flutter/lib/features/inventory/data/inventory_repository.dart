import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'package:frontend_flutter/features/inventory/data/inventory_model.dart';

class InventoryRepository {
  final Dio _dio;

  InventoryRepository(this._dio);

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

  Future<List<InventoryItem>> getItems() async {
    try {
      final response = await _dio.get('/api/inventory/farm/$_farmId');
      final rawItems = _extractCollection(response.data);
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map(InventoryItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load inventory (HTTP ${e.response?.statusCode ?? 'unknown'}).');
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  Future<InventoryItem> createItem(Map<String, dynamic> itemData) async {
    try {
      itemData['farmId'] = _farmId;
      final response = await _dio.post('/api/inventory', data: itemData);
      return InventoryItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create inventory item: $e');
    }
  }

  Future<InventoryItem> updateItem(String id, Map<String, dynamic> data) async {
    try {
      data['farmId'] = _farmId;
      final response = await _dio.put('/api/inventory/$id', data: data);
      return InventoryItem.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _dio.delete('/api/inventory/$itemId?farmId=$_farmId');
    } catch (e) {
      throw Exception('Failed to delete inventory item: $e');
    }
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return InventoryRepository(dio);
});
