import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/tanks/data/biometrics_model.dart';
import 'package:frontend_flutter/features/tanks/data/tank_repository.dart';
import 'package:frontend_flutter/features/tanks/providers/tanks_provider.dart';

class BiometricsNotifier extends Notifier<AsyncValue<List<BiometricsRecord>>> {
  final String tankId;
  BiometricsNotifier(this.tankId);

  late final TankRepository _repository;

  @override
  AsyncValue<List<BiometricsRecord>> build() {
    _repository = ref.watch(tankRepositoryProvider);
    Future.microtask(() => _load());
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    try {
      final records = await _repository.getBiometrics(tankId);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> logBiometrics(int weightG, [String? recordDate]) async {
    try {
      final newRecord = await _repository.createBiometricsRecord(tankId, weightG, recordDate);
      state = state.whenData((records) => [newRecord, ...records]);
      // Refresh tanks to get updated average weight
      ref.invalidate(tanksProvider);
      return true;
    } catch (e) {
      print('BiometricsNotifier.logBiometrics: Error: $e');
      return false;
    }
  }

  Future<bool> deleteBiometrics(String id) async {
    try {
      await _repository.deleteBiometricsRecord(id);
      state = state.whenData((records) => records.where((r) => r.id != id).toList());
      // Refresh tanks to get updated average weight
      ref.invalidate(tanksProvider);
      return true;
    } catch (e) {
      print('BiometricsNotifier.deleteBiometrics: Error: $e');
      return false;
    }
  }
}

final biometricsProvider = NotifierProvider.family<
    BiometricsNotifier,
    AsyncValue<List<BiometricsRecord>>,
    String>(BiometricsNotifier.new);
