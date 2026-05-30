class Tank {
  final String id;
  final String name;
  final String fishSpecies;
  final int fishCapacity;
  final int averageWeightG;
  final int mortalityCount;
  final String? nextHarvestDate;
  final String status;

  Tank({
    required this.id,
    required this.name,
    required this.fishSpecies,
    required this.fishCapacity,
    required this.averageWeightG,
    required this.mortalityCount,
    this.nextHarvestDate,
    required this.status,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      fishSpecies: json['fishSpecies'] ?? '',
      fishCapacity: (json['fishCapacity'] as num?)?.toInt() ?? 0,
      averageWeightG: (json['averageWeightG'] as num?)?.toInt() ?? 0,
      mortalityCount: (json['mortalityCount'] as num?)?.toInt() ?? 0,
      nextHarvestDate: json['nextHarvestDate'],
      status: json['status'] ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fishSpecies': fishSpecies,
      'fishCapacity': fishCapacity,
      'averageWeightG': averageWeightG,
      'mortalityCount': mortalityCount,
      'nextHarvestDate': nextHarvestDate,
      'status': status,
    };
  }
}
