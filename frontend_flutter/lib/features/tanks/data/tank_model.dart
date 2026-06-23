class Tank {
  final String id;
  final String name;
  final String fishSpecies;
  final int fishCapacity;
  final int averageWeightG;
  final int mortalityCount;
  final String? nextHarvestDate;
  final String? stockingDate;
  final int? initialStockingQty;
  final int? initialAverageWeightG;
  final String? supplier;
  final String status;
  final String? customImage;

  Tank({
    required this.id,
    required this.name,
    required this.fishSpecies,
    required this.fishCapacity,
    required this.averageWeightG,
    required this.mortalityCount,
    this.nextHarvestDate,
    this.stockingDate,
    this.initialStockingQty,
    this.initialAverageWeightG,
    this.supplier,
    required this.status,
    this.customImage,
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
      stockingDate: json['stockingDate'],
      initialStockingQty: (json['initialStockingQty'] as num?)?.toInt(),
      initialAverageWeightG: (json['initialAverageWeightG'] as num?)?.toInt(),
      supplier: json['supplier'],
      status: json['status'] ?? 'ACTIVE',
      customImage: json['customImage'],
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
      'stockingDate': stockingDate,
      'initialStockingQty': initialStockingQty,
      'initialAverageWeightG': initialAverageWeightG,
      'supplier': supplier,
      'status': status,
      'customImage': customImage,
    };
  }
}
