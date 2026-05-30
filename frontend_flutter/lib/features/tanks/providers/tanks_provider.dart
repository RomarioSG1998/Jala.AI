import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/tanks/data/tank_model.dart';
import 'package:frontend_flutter/features/tanks/data/tank_repository.dart';

class TanksNotifier extends AsyncNotifier<List<Tank>> {
  late TankRepository _repository;

  @override
  Future<List<Tank>> build() async {
    _repository = ref.watch(tankRepositoryProvider);
    return _fetchTanks();
  }

  Future<List<Tank>> _fetchTanks() async {
    return await _repository.getTanks();
  }

  Future<void> refreshTanks() async {
    state = const AsyncValue.loading();
    try {
      final tanks = await _fetchTanks();
      state = AsyncValue.data(tanks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createTank(String name, String species, int capacity, [String? customImage]) async {
    try {
      final newTank = await _repository.createTank({
        'name': name,
        'fishSpecies': species,
        'fishCapacity': capacity,
        'customImage': customImage,
      });
      // Update state optimistically or by fetching
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newTank]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTank(
    String id,
    String name,
    String species,
    int capacity,
    int averageWeight,
    int mortalityCount,
    String? nextHarvestDate,
    String status, [
    String? customImage,
    bool clearImage = false,
  ]) async {
    try {
      final updatedTank = await _repository.updateTank(id, {
        'name': name,
        'fishSpecies': species,
        'fishCapacity': capacity,
        'averageWeightG': averageWeight,
        'mortalityCount': mortalityCount,
        'nextHarvestDate': nextHarvestDate,
        'status': status,
        'customImage': clearImage ? "" : customImage,
      });
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((t) => t.id == id ? updatedTank : t).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTank(String id) async {
    try {
      await _repository.deleteTank(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((t) => t.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final tanksProvider = AsyncNotifierProvider<TanksNotifier, List<Tank>>(() {
  return TanksNotifier();
});

class GlobalSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final globalSearchQueryProvider = NotifierProvider<GlobalSearchQuery, String>(GlobalSearchQuery.new);


class SearchBarVisible extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool visible) => state = visible;
}

final searchBarVisibleProvider = NotifierProvider<SearchBarVisible, bool>(SearchBarVisible.new);


