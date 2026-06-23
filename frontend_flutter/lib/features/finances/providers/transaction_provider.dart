import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/finances/data/transaction_model.dart';
import 'package:frontend_flutter/features/finances/data/transaction_repository.dart';

class TransactionNotifier extends AsyncNotifier<List<FinancialTransaction>> {
  late final TransactionRepository _repository;

  @override
  Future<List<FinancialTransaction>> build() async {
    _repository = ref.watch(transactionRepositoryProvider);
    return _repository.getTransactions();
  }

  Future<void> refreshTransactions() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.getTransactions());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createTransaction({
    required String type,
    required double amount,
    String? category,
    String? clientName,
    String? fishSpecies,
    double? quantityKg,
    String? transactionDate,
  }) async {
    try {
      final transaction = await _repository.createTransaction(
        type: type,
        amount: amount,
        category: category,
        clientName: clientName,
        fishSpecies: fishSpecies,
        quantityKg: quantityKg,
        transactionDate: transactionDate,
      );
      if (state.hasValue) {
        state = AsyncValue.data([...state.value!, transaction]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTransaction({
    required String id,
    required String type,
    required double amount,
    String? category,
    String? clientName,
    String? fishSpecies,
    double? quantityKg,
    String? transactionDate,
  }) async {
    try {
      final updated = await _repository.updateTransaction(
        id: id,
        type: type,
        amount: amount,
        category: category,
        clientName: clientName,
        fishSpecies: fishSpecies,
        quantityKg: quantityKg,
        transactionDate: transactionDate,
      );
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.map((t) => t.id == id ? updated : t).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.where((t) => t.id != id).toList());
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final transactionProvider =
    AsyncNotifierProvider<TransactionNotifier, List<FinancialTransaction>>(() {
  return TransactionNotifier();
});
