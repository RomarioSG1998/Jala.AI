class FeedingRecord {
  final String id;
  final String farmId;
  final String tankId;
  final String userId;
  final String feedId;
  final double quantity;
  final String feedingTime;
  final double? unitCost;

  FeedingRecord({
    required this.id,
    required this.farmId,
    required this.tankId,
    required this.userId,
    required this.feedId,
    required this.quantity,
    required this.feedingTime,
    this.unitCost,
  });

  factory FeedingRecord.fromJson(Map<String, dynamic> json) {
    return FeedingRecord(
      id: json['id'] ?? '',
      farmId: json['farmId'] ?? '',
      tankId: json['tankId'] ?? '',
      userId: json['userId'] ?? '',
      feedId: json['feedId'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      feedingTime: json['feedingTime'] ?? '',
      unitCost: (json['unitCost'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'tankId': tankId,
      'userId': userId,
      'feedId': feedId,
      'quantity': quantity,
      'feedingTime': feedingTime,
      if (unitCost != null) 'unitCost': unitCost,
    };
  }
}
