import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/dashboard/data/farm_summary_model.dart';
import 'package:frontend_flutter/features/dashboard/data/farm_summary_repository.dart';

class FarmSummaryNotifier extends AsyncNotifier<FarmSummary> {
  late FarmSummaryRepository _repository;

  @override
  Future<FarmSummary> build() async {
    _repository = ref.watch(farmSummaryRepositoryProvider);
    return _repository.getSummary();
  }

  Future<void> refreshSummary() async {
    state = const AsyncValue.loading();
    try {
      final summary = await _repository.getSummary();
      state = AsyncValue.data(summary);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final farmSummaryProvider = AsyncNotifierProvider<FarmSummaryNotifier, FarmSummary>(() {
  return FarmSummaryNotifier();
});
