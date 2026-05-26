import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/suppliers/data/supplier_model.dart';
import 'package:frontend_flutter/features/suppliers/data/supplier_repository.dart';

class SupplierNotifier extends AsyncNotifier<List<NationalSupplier>> {
  late final SupplierRepository _repository;

  @override
  Future<List<NationalSupplier>> build() async {
    _repository = ref.watch(supplierRepositoryProvider);
    return _repository.getSuppliers();
  }

  Future<void> refreshSuppliers() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.getSuppliers());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createSupplier(String companyName, String cnpj, String supplyType) async {
    try {
      final supplier = await _repository.createSupplier(companyName, cnpj, supplyType);
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, supplier]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> approveSupplier(String id) async {
    try {
      final updated = await _repository.approveSupplier(id);
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.map((s) => s.id == id ? updated : s).toList(),
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSupplier(String id) async {
    try {
      await _repository.deleteSupplier(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((s) => s.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final supplierProvider =
    AsyncNotifierProvider<SupplierNotifier, List<NationalSupplier>>(() {
  return SupplierNotifier();
});
