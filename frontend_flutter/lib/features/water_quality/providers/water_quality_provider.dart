import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_model.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_repository.dart';

class WaterQualityNotifier extends AsyncNotifier<List<WaterQuality>> {
  late final WaterQualityRepository _repository;

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
}

final waterQualityProvider = AsyncNotifierProvider<WaterQualityNotifier, List<WaterQuality>>(() {
  return WaterQualityNotifier();
});
