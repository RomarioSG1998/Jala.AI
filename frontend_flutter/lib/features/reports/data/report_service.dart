import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class GrowthPoint {
  final String date;
  final double avgWeightG;
  final String tankName;
  GrowthPoint({required this.date, required this.avgWeightG, required this.tankName});
  factory GrowthPoint.fromJson(Map<String, dynamic> j) => GrowthPoint(
        date: j['date'] ?? '',
        avgWeightG: (j['avgWeightG'] ?? 0).toDouble(),
        tankName: j['tankName'] ?? '',
      );
}

class MortalityPoint {
  final String date;
  final int count;
  final String? cause;
  MortalityPoint({required this.date, required this.count, this.cause});
  factory MortalityPoint.fromJson(Map<String, dynamic> j) => MortalityPoint(
        date: j['date'] ?? '',
        count: j['count'] ?? 0,
        cause: j['cause'],
      );
}

class FeedingPoint {
  final String date;
  final double quantityKg;
  final double cost;
  FeedingPoint({required this.date, required this.quantityKg, required this.cost});
  factory FeedingPoint.fromJson(Map<String, dynamic> j) => FeedingPoint(
        date: j['date'] ?? '',
        quantityKg: (j['quantityKg'] ?? 0).toDouble(),
        cost: (j['cost'] ?? 0).toDouble(),
      );
}

class HarvestForecast {
  final String tankName;
  final String expectedDate;
  final int estimatedFishCount;
  final double estimatedWeightKg;
  HarvestForecast({
    required this.tankName,
    required this.expectedDate,
    required this.estimatedFishCount,
    required this.estimatedWeightKg,
  });
  factory HarvestForecast.fromJson(Map<String, dynamic> j) => HarvestForecast(
        tankName: j['tankName'] ?? '',
        expectedDate: j['expectedDate'] ?? '',
        estimatedFishCount: j['estimatedFishCount'] ?? 0,
        estimatedWeightKg: (j['estimatedWeightKg'] ?? 0).toDouble(),
      );
}

class ReportSummary {
  final List<GrowthPoint> growthHistory;
  final int totalMortality;
  final double mortalityRate;
  final List<MortalityPoint> mortalityHistory;
  final double totalFeedKg;
  final double totalFeedCost;
  final List<FeedingPoint> feedingHistory;
  final List<HarvestForecast> harvestForecasts;

  ReportSummary({
    required this.growthHistory,
    required this.totalMortality,
    required this.mortalityRate,
    required this.mortalityHistory,
    required this.totalFeedKg,
    required this.totalFeedCost,
    required this.feedingHistory,
    required this.harvestForecasts,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
        growthHistory: (j['growthHistory'] as List? ?? []).map((e) => GrowthPoint.fromJson(e)).toList(),
        totalMortality: j['totalMortality'] ?? 0,
        mortalityRate: (j['mortalityRate'] ?? 0).toDouble(),
        mortalityHistory: (j['mortalityHistory'] as List? ?? []).map((e) => MortalityPoint.fromJson(e)).toList(),
        totalFeedKg: (j['totalFeedKg'] ?? 0).toDouble(),
        totalFeedCost: (j['totalFeedCost'] ?? 0).toDouble(),
        feedingHistory: (j['feedingHistory'] as List? ?? []).map((e) => FeedingPoint.fromJson(e)).toList(),
        harvestForecasts: (j['harvestForecasts'] as List? ?? []).map((e) => HarvestForecast.fromJson(e)).toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class ReportService {
  final Dio _dio;

  ReportService({required Dio dio}) : _dio = dio;

  Future<ReportSummary> fetchSummary(String farmId) async {
    final response = await _dio.get(
      '/api/reports/summary',
      queryParameters: {'farmId': farmId},
    );
    return ReportSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> fetchPlanLimit(String farmId) async {
    final response = await _dio.get(
      '/api/reports/plan-limit',
      queryParameters: {'farmId': farmId},
    );
    return (response.data['maxTanks'] ?? 1) as int;
  }
}
