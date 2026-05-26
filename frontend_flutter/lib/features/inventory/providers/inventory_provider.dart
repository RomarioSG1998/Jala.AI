import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/inventory/data/inventory_model.dart';
import 'package:frontend_flutter/features/inventory/data/inventory_repository.dart';

class InventoryNotifier extends AsyncNotifier<List<InventoryItem>> {
  late final InventoryRepository _repository;

  @override
  Future<List<InventoryItem>> build() async {
    _repository = ref.watch(inventoryRepositoryProvider);
    return _repository.getItems();
  }

  Future<void> refreshItems() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.getItems());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createItem(String name, double qty, String unit, String type) async {
    try {
      final item = await _repository.createItem({
        'itemName': name,
        'quantity': qty,
        'unit': unit,
        'type': type,
      });
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, item]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateItem(String id, String name, double qty, String unit, String type) async {
    try {
      final updated = await _repository.updateItem(id, {
        'itemName': name,
        'quantity': qty,
        'unit': unit,
        'type': type,
      });
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.map((i) => i.id == id ? updated : i).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _repository.deleteItem(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((i) => i.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final inventoryProvider =
    AsyncNotifierProvider<InventoryNotifier, List<InventoryItem>>(() {
  return InventoryNotifier();
});
