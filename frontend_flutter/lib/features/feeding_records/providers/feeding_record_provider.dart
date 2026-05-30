import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/feeding_records/data/feeding_record_model.dart';
import 'package:frontend_flutter/features/feeding_records/data/feeding_record_repository.dart';
import 'package:frontend_flutter/features/inventory/providers/inventory_provider.dart';

class FeedingRecordNotifier extends AsyncNotifier<List<FeedingRecord>> {
  late FeedingRecordRepository _repository;

  @override
  Future<List<FeedingRecord>> build() async {
    _repository = ref.watch(feedingRecordRepositoryProvider);
    return _fetchRecords();
  }

  Future<List<FeedingRecord>> _fetchRecords() async {
    return await _repository.getRecords();
  }

  Future<void> refreshRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await _fetchRecords();
      state = AsyncValue.data(records);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<String?> createRecord(String tankId, String feedId, double quantity) async {
    try {
      final userId = ref.read(authNotifierProvider).userId;
      final newRecord = await _repository.createRecord({
        'tankId': tankId,
        'feedId': feedId,
        'quantity': quantity,
        'userId': userId,
      });
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newRecord]);
      }
      // Refresh inventory items to update feed quantity
      ref.read(inventoryProvider.notifier).refreshItems();
      return null; // success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> updateRecord(String id, String tankId, String feedId, double quantity) async {
    try {
      final userId = ref.read(authNotifierProvider).userId;
      final updated = await _repository.updateRecord(id, {
        'tankId': tankId,
        'feedId': feedId,
        'quantity': quantity,
        'userId': userId,
      });
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.map((r) => r.id == id ? updated : r).toList());
      }
      // Refresh inventory items to update feed quantity
      ref.read(inventoryProvider.notifier).refreshItems();
      return null; // success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> deleteRecord(String id) async {
    try {
      await _repository.deleteRecord(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((r) => r.id != id).toList());
      }
      // Refresh inventory items to update feed quantity (reclaimed feed)
      ref.read(inventoryProvider.notifier).refreshItems();
      return null; // success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

final feedingRecordProvider = AsyncNotifierProvider<FeedingRecordNotifier, List<FeedingRecord>>(() {
  return FeedingRecordNotifier();
});
