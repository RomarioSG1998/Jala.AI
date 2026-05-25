class SaasPlan {
  final String id;
  final String name;
  final int maxTanks;
  final int maxUsers;
  final double priceMonthly;

  SaasPlan({
    required this.id,
    required this.name,
    required this.maxTanks,
    required this.maxUsers,
    required this.priceMonthly,
  });

  factory SaasPlan.fromJson(Map<String, dynamic> json) {
    return SaasPlan(
      id: json['id'],
      name: json['name'],
      maxTanks: json['maxTanks'] ?? 0,
      maxUsers: json['maxUsers'] ?? 0,
      priceMonthly: (json['priceMonthly'] as num).toDouble(),
    );
  }
}

class FarmTenant {
  final String id;
  final String name;
  final String cnpj;
  final String ownerId;
  final String createdAt;

  FarmTenant({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.ownerId,
    required this.createdAt,
  });

  factory FarmTenant.fromJson(Map<String, dynamic> json) {
    return FarmTenant(
      id: json['id'],
      name: json['name'] ?? 'Unknown Farm',
      cnpj: json['cnpj'] ?? '',
      ownerId: json['ownerId'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
