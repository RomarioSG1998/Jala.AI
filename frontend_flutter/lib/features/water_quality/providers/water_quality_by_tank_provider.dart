import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_model.dart';
import 'package:frontend_flutter/features/water_quality/data/water_quality_repository.dart';

final waterQualityByTankProvider = FutureProvider.family<WaterQuality?, String>((ref, tankId) async {
  final repository = ref.watch(waterQualityRepositoryProvider);
  return repository.getLatestByTankId(tankId);
});
