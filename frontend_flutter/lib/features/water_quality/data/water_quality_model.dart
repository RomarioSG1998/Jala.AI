class WaterQuality {
  final String id;
  final String tankId;
  final double ph;
  final double temperature;
  final double dissolvedOxygen;
  final double? ammonia;
  final double? nitrite;
  final double? alkalinity;
  final double? hardness;
  final double? solids;
  final String measurementTime;

  WaterQuality({
    required this.id,
    required this.tankId,
    required this.ph,
    required this.temperature,
    required this.dissolvedOxygen,
    this.ammonia,
    this.nitrite,
    this.alkalinity,
    this.hardness,
    this.solids,
    required this.measurementTime,
  });

  factory WaterQuality.fromJson(Map<String, dynamic> json) {
    return WaterQuality(
      id: json['id'] ?? '',
      tankId: json['tankId'] ?? json['tank']?['id'] ?? '',
      ph: (json['ph'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      dissolvedOxygen: (json['dissolvedOxygen'] as num?)?.toDouble() ?? 0.0,
      ammonia: json['ammonia'] != null ? (json['ammonia'] as num).toDouble() : null,
      nitrite: json['nitrite'] != null ? (json['nitrite'] as num).toDouble() : null,
      alkalinity: json['alkalinity'] != null ? (json['alkalinity'] as num).toDouble() : null,
      hardness: json['hardness'] != null ? (json['hardness'] as num).toDouble() : null,
      solids: json['solids'] != null ? (json['solids'] as num).toDouble() : null,
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
      if (ammonia != null) 'ammonia': ammonia,
      if (nitrite != null) 'nitrite': nitrite,
      if (alkalinity != null) 'alkalinity': alkalinity,
      if (hardness != null) 'hardness': hardness,
      if (solids != null) 'solids': solids,
      'measurementTime': measurementTime,
    };
  }
}
