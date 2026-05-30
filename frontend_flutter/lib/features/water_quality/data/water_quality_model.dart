class WaterQuality {
  final String id;
  final String tankId;
  final double ph;
  final double temperature;
  final double dissolvedOxygen;
  final String measurementTime;

  WaterQuality({
    required this.id,
    required this.tankId,
    required this.ph,
    required this.temperature,
    required this.dissolvedOxygen,
    required this.measurementTime,
  });

  factory WaterQuality.fromJson(Map<String, dynamic> json) {
    return WaterQuality(
      id: json['id'] ?? '',
      tankId: json['tankId'] ?? json['tank']?['id'] ?? '',
      ph: (json['ph'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      dissolvedOxygen: (json['dissolvedOxygen'] as num?)?.toDouble() ?? 0.0,
      measurementTime: json['measurementTime'] ?? json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tankId': tankId,
      'ph': ph,
      'temperature': temperature,
      'dissolvedOxygen': dissolvedOxygen,
      'measurementTime': measurementTime,
    };
  }
}
