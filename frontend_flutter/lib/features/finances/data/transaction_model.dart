class FinancialTransaction {
  final String id;
  final String farmId;
  final String type; // Income, Expense
  final double amount;
  final String transactionDate;

  FinancialTransaction({
    required this.id,
    required this.farmId,
    required this.type,
    required this.amount,
    required this.transactionDate,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] ?? '',
      farmId: json['farmId'] ?? '',
      type: json['type'] ?? 'Expense',
      amount: (json['amount'] as num).toDouble(),
      transactionDate: json['transactionDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'type': type,
      'amount': amount,
      'transactionDate': transactionDate,
    };
  }
}
