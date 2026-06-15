class BiometricsRecord {
  final String id;
  final String farmId;
  final String tankId;
  final int weightG;
  final String recordDate;

  BiometricsRecord({
    required this.id,
    required this.farmId,
    required this.tankId,
    required this.weightG,
    required this.recordDate,
  });

  factory BiometricsRecord.fromJson(Map<String, dynamic> json) {
    return BiometricsRecord(
      id: json['id'] ?? '',
      farmId: json['farmId'] ?? '',
      tankId: json['tankId'] ?? '',
      weightG: json['weightG'] ?? 0,
      recordDate: json['recordDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'tankId': tankId,
      'weightG': weightG,
      'recordDate': recordDate,
    };
  }
}
