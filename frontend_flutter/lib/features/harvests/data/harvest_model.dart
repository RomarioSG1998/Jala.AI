class Harvest {
  final String id;
  final String farmId;
  final String tankId;
  final String date;
  final double quantityKg;
  final String destination;

  Harvest({
    required this.id,
    required this.farmId,
    required this.tankId,
    required this.date,
    required this.quantityKg,
    required this.destination,
  });

  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      id: json['id'] ?? '',
      farmId: json['farmId'] ?? '',
      tankId: json['tankId'] ?? '',
      date: json['date'] ?? '',
      quantityKg: (json['quantityKg'] as num?)?.toDouble() ?? 0.0,
      destination: json['destination'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'tankId': tankId,
        'date': date,
        'quantityKg': quantityKg,
        'destination': destination,
      };
}
