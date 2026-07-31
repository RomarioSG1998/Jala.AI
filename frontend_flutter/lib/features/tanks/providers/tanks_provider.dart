import 'package:dio/dio.dart';
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

  // Holds the last PlanLimitException so the UI can react to it.
  PlanLimitException? lastPlanLimitError;

  Future<bool> createTank(
    String name,
    String species,
    int capacity, {
    String? stockingDate,
    int? initialStockingQty,
    int? initialAverageWeightG,
    String? supplier,
    String? customImage,
  }) async {
    lastPlanLimitError = null;
    try {
      print('TanksNotifier.createTank: customImage length = ${customImage?.length}');
      final newTank = await _repository.createTank({
        'name': name,
        'fishSpecies': species,
        'fishCapacity': capacity,
        'stockingDate': stockingDate,
        'initialStockingQty': initialStockingQty,
        'initialAverageWeightG': initialAverageWeightG,
        'supplier': supplier,
        'customImage': customImage,
      });
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, newTank]);
      }
      return true;
    } on PlanLimitException catch (e) {
      lastPlanLimitError = e;
      return false;
    } catch (e) {
      if (e is PlanLimitException || e.toString().contains('PlanLimitException') || (e is DioException && e.response?.statusCode == 402)) {
        int maxAllowed = 3;
        if (e is PlanLimitException) {
          maxAllowed = e.maxAllowed;
        } else if (e is DioException && e.response?.data is Map && e.response?.data['maxAllowed'] != null) {
          maxAllowed = (e.response?.data['maxAllowed'] as num).toInt();
        }
        lastPlanLimitError = PlanLimitException(maxAllowed);
        return false;
      }
      if (e is DioException) {
        print('TanksNotifier.createTank: Error: ${e.message} (status: ${e.response?.statusCode})');
      } else {
        print('TanksNotifier.createTank: Error: $e');
      }
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
    String? stockingDate,
    String status, {
    int? initialStockingQty,
    int? initialAverageWeightG,
    String? supplier,
    String? customImage,
    bool clearImage = false,
  }) async {
    try {
      final imgVal = clearImage ? "" : customImage;
      print('TanksNotifier.updateTank: customImage length = ${imgVal?.length}, clearImage = $clearImage');
      final updatedTank = await _repository.updateTank(id, {
        'name': name,
        'fishSpecies': species,
        'fishCapacity': capacity,
        'averageWeightG': averageWeight,
        'mortalityCount': mortalityCount,
        'nextHarvestDate': nextHarvestDate,
        'stockingDate': stockingDate,
        'initialStockingQty': initialStockingQty,
        'initialAverageWeightG': initialAverageWeightG,
        'supplier': supplier,
        'status': status,
        'customImage': imgVal,
      });
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((t) => t.id == id ? updatedTank : t).toList(),
        );
      }
      return true;
    } catch (e) {
      if (e is DioException) {
        print('TanksNotifier.updateTank: Error: ${e.message} (status: ${e.response?.statusCode})');
      } else {
        print('TanksNotifier.updateTank: Error: $e');
      }
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


