class FinancialTransaction {
  final String id;
  final String farmId;
  final String type; // Income, Expense
  final double amount;
  final String transactionDate;
  final String? category;
  final String? clientName;
  final String? fishSpecies;
  final double? quantityKg;

  FinancialTransaction({
    required this.id,
    required this.farmId,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.category,
    this.clientName,
    this.fishSpecies,
    this.quantityKg,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] ?? '',
      farmId: json['farmId'] ?? '',
      type: json['type'] ?? 'Expense',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionDate: json['transactionDate'] ?? json['createdAt'] ?? '',
      category: json['category'],
      clientName: json['clientName'],
      fishSpecies: json['fishSpecies'],
      quantityKg: (json['quantityKg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'type': type,
      'amount': amount,
      'transactionDate': transactionDate,
      'category': category,
      'clientName': clientName,
      'fishSpecies': fishSpecies,
      'quantityKg': quantityKg,
    };
  }
}
