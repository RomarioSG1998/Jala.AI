import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_model.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_repository.dart';

class WaterQualityNotifier extends AsyncNotifier<List<WaterQuality>> {
  late WaterQualityRepository _repository;

  @override
  Future<List<WaterQuality>> build() async {
    _repository = ref.watch(waterQualityRepositoryProvider);
    return _fetchRecords();
  }

  Future<List<WaterQuality>> _fetchRecords() async {
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

  Future<bool> createRecord(String tankId, double ph, double temperature, double dissolvedOxygen) async {
    try {
      final newRecord = await _repository.createRecord({
        'tankId': tankId,
        'ph': ph,
        'temperature': temperature,
        'dissolvedOxygen': dissolvedOxygen,
      });
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newRecord]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      await _repository.deleteRecord(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((r) => r.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final waterQualityProvider = AsyncNotifierProvider<WaterQualityNotifier, List<WaterQuality>>(() {
  return WaterQualityNotifier();
});
