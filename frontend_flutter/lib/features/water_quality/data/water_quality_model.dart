class WaterQuality {
  final String id;
  final String tankId;
  final double phLevel;
  final double temperature;
  final double dissolvedOxygen;
  final String recordedAt;

  WaterQuality({
    required this.id,
    required this.tankId,
    required this.phLevel,
    required this.temperature,
    required this.dissolvedOxygen,
    required this.recordedAt,
  });

  factory WaterQuality.fromJson(Map<String, dynamic> json) {
    return WaterQuality(
      id: json['id'],
      tankId: json['tankId'] ?? json['tank']?['id'] ?? '',
      phLevel: (json['phLevel'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      dissolvedOxygen: (json['dissolvedOxygen'] as num).toDouble(),
      recordedAt: json['recordedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tankId': tankId,
      'phLevel': phLevel,
      'temperature': temperature,
      'dissolvedOxygen': dissolvedOxygen,
      'recordedAt': recordedAt,
    };
  }
}
