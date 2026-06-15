class MortalityRecord {
  final String id;
  final String farmId;
  final String tankId;
  final int quantity;
  final String? cause;
  final String recordDate;

  MortalityRecord({
    required this.id,
    required this.farmId,
    required this.tankId,
    required this.quantity,
    this.cause,
    required this.recordDate,
  });

  factory MortalityRecord.fromJson(Map<String, dynamic> json) {
    return MortalityRecord(
      id: json['id'] ?? '',
      farmId: json['farmId'] ?? '',
      tankId: json['tankId'] ?? '',
      quantity: json['quantity'] ?? 0,
      cause: json['cause'],
      recordDate: json['recordDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'tankId': tankId,
      'quantity': quantity,
      if (cause != null) 'cause': cause,
      'recordDate': recordDate,
    };
  }
}
