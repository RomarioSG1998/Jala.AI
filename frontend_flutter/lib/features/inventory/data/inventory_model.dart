class InventoryItem {
  final String id;
  final String farmId;
  final String itemName;
  final double quantity;
  final String unit;
  final String type;
  final String? power;
  final double? unitCost;

  InventoryItem({
    required this.id,
    required this.farmId,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.type,
    this.power,
    this.unitCost,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? '',
      farmId: json['farmId'] ?? '',
      itemName: json['itemName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
      type: json['type'] ?? '',
      power: json['power'],
      unitCost: (json['unitCost'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'itemName': itemName,
        'quantity': quantity,
        'unit': unit,
        'type': type,
        if (power != null) 'power': power,
        if (unitCost != null) 'unitCost': unitCost,
      };
}
