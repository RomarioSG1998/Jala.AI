import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/harvests/data/harvest_model.dart';
import 'package:frontend_flutter/features/harvests/data/harvest_repository.dart';

class HarvestNotifier extends AsyncNotifier<List<Harvest>> {
  late final HarvestRepository _repository;

  @override
  Future<List<Harvest>> build() async {
    _repository = ref.watch(harvestRepositoryProvider);
    return _repository.getHarvests();
  }

  Future<void> refreshHarvests() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.getHarvests());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> logHarvest(
      String tankId, String date, double quantityKg, String destination) async {
    try {
      final harvest = await _repository.logHarvest({
        'tankId': tankId,
        'date': date,
        'quantityKg': quantityKg,
        'destination': destination,
      });
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, harvest]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteHarvest(String id) async {
    try {
      await _repository.deleteHarvest(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((h) => h.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final harvestProvider =
    AsyncNotifierProvider<HarvestNotifier, List<Harvest>>(() {
  return HarvestNotifier();
});
