import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/mortality/data/mortality_model.dart';
import 'package:frontend_flutter/features/mortality/data/mortality_repository.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';

class MortalityNotifier extends AsyncNotifier<List<MortalityRecord>> {
  late MortalityRepository _repository;

  @override
  Future<List<MortalityRecord>> build() async {
    _repository = ref.watch(mortalityRepositoryProvider);
    return _fetchRecords();
  }

  Future<List<MortalityRecord>> _fetchRecords() async {
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

  Future<String?> createRecord(String tankId, int quantity, String? cause, {String? recordDate}) async {
    try {
      final newRecord = await _repository.createRecord({
        'tankId': tankId,
        'quantity': quantity,
        if (cause != null && cause.isNotEmpty) 'cause': cause,
        if (recordDate != null) 'recordDate': recordDate,
      });
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newRecord]);
      }
      // Refresh tanks to update mortality counts and capacities
      ref.read(tanksProvider.notifier).refreshTanks();
      return null; // success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> updateRecord(String id, String tankId, int quantity, String? cause, {String? recordDate}) async {
    try {
      final updated = await _repository.updateRecord(id, {
        'tankId': tankId,
        'quantity': quantity,
        if (cause != null && cause.isNotEmpty) 'cause': cause,
        if (recordDate != null) 'recordDate': recordDate,
      });
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.map((r) => r.id == id ? updated : r).toList());
      }
      // Refresh tanks to update mortality counts and capacities
      ref.read(tanksProvider.notifier).refreshTanks();
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
      // Refresh tanks to update mortality counts and capacities
      ref.read(tanksProvider.notifier).refreshTanks();
      return null; // success
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

final mortalityProvider = AsyncNotifierProvider<MortalityNotifier, List<MortalityRecord>>(() {
  return MortalityNotifier();
});
