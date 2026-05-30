class NationalSupplier {
  final String id;
  final String companyName;
  final String cnpj;
  final String supplyType;
  final bool isApproved;

  NationalSupplier({
    required this.id,
    required this.companyName,
    required this.cnpj,
    required this.supplyType,
    required this.isApproved,
  });

  factory NationalSupplier.fromJson(Map<String, dynamic> json) {
    return NationalSupplier(
      id: json['id'] ?? '',
      companyName: json['companyName'] ?? '',
      cnpj: json['cnpj'] ?? '',
      supplyType: json['supplyType'] ?? '',
      isApproved: json['isApproved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'cnpj': cnpj,
      'supplyType': supplyType,
      'isApproved': isApproved,
    };
  }
}
