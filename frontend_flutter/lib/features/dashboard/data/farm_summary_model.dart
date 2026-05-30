class FarmSummary {
  final int totalTanks;
  final int activeTanks;
  final int totalFishCapacity;
  final double feedingTodayKg;
  final int pendingMaintenanceTasks;

  FarmSummary({
    required this.totalTanks,
    required this.activeTanks,
    required this.totalFishCapacity,
    required this.feedingTodayKg,
    required this.pendingMaintenanceTasks,
  });

  factory FarmSummary.fromJson(Map<String, dynamic> json) {
    return FarmSummary(
      totalTanks: json['totalTanks'] ?? 0,
      activeTanks: json['activeTanks'] ?? 0,
      totalFishCapacity: json['totalFishCapacity'] ?? 0,
      feedingTodayKg: (json['feedingTodayKg'] as num?)?.toDouble() ?? 0.0,
      pendingMaintenanceTasks: json['pendingMaintenanceTasks'] ?? 0,
    );
  }
}
