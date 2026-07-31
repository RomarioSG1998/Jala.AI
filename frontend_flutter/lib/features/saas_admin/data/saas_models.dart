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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Plano',
      maxTanks: (json['maxTanks'] as num?)?.toInt() ?? 3,
      maxUsers: (json['maxUsers'] as num?)?.toInt() ?? 2,
      priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0.0,
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
