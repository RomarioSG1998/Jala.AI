class SaasPlan {
  final String id;
  final String name;
  final int maxTanks;
  final int maxUsers;
  final double priceMonthly;
  final String? stripeProductId;
  final String? stripePriceId;
  final String? description;
  final bool active;

  SaasPlan({
    required this.id,
    required this.name,
    required this.maxTanks,
    required this.maxUsers,
    required this.priceMonthly,
    this.stripeProductId,
    this.stripePriceId,
    this.description,
    this.active = true,
  });

  factory SaasPlan.fromJson(Map<String, dynamic> json) {
    return SaasPlan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Plano',
      maxTanks: (json['maxTanks'] as num?)?.toInt() ?? 3,
      maxUsers: (json['maxUsers'] as num?)?.toInt() ?? 2,
      priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0.0,
      stripeProductId: json['stripeProductId']?.toString(),
      stripePriceId: json['stripePriceId']?.toString(),
      description: json['description']?.toString(),
      active: json['active'] != false,
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

class SubscriptionDetails {
  final String? subscriptionId;
  final String? farmId;
  final String? planId;
  final String planName;
  final int maxTanks;
  final int maxUsers;
  final double priceMonthly;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? nextBillingDate;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? paymentMethodType;
  final String? cardBrand;
  final String? cardLast4;
  final bool cancelAtPeriodEnd;

  SubscriptionDetails({
    this.subscriptionId,
    this.farmId,
    this.planId,
    required this.planName,
    required this.maxTanks,
    required this.maxUsers,
    required this.priceMonthly,
    required this.status,
    this.startDate,
    this.endDate,
    this.nextBillingDate,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.paymentMethodType,
    this.cardBrand,
    this.cardLast4,
    required this.cancelAtPeriodEnd,
  });

  factory SubscriptionDetails.fromJson(Map<String, dynamic> json) {
    return SubscriptionDetails(
      subscriptionId: json['subscriptionId']?.toString(),
      farmId: json['farmId']?.toString(),
      planId: json['planId']?.toString(),
      planName: json['planName']?.toString() ?? 'Plano Gratuito',
      maxTanks: (json['maxTanks'] as num?)?.toInt() ?? 3,
      maxUsers: (json['maxUsers'] as num?)?.toInt() ?? 2,
      priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'FREE',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      nextBillingDate: json['nextBillingDate']?.toString(),
      stripeCustomerId: json['stripeCustomerId']?.toString(),
      stripeSubscriptionId: json['stripeSubscriptionId']?.toString(),
      paymentMethodType: json['paymentMethodType']?.toString(),
      cardBrand: json['cardBrand']?.toString(),
      cardLast4: json['cardLast4']?.toString(),
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] == true,
    );
  }
}

class SaasMasterOverview {
  final int totalFarms;
  final int activeSubscriptions;
  final int totalTanks;
  final double estimatedMRR;
  final double estimatedARR;
  final int upToDateTenantsCount;
  final int pastDueTenantsCount;
  final int freeTenantsCount;
  final double b2bEscrowVolume;

  SaasMasterOverview({
    required this.totalFarms,
    required this.activeSubscriptions,
    required this.totalTanks,
    required this.estimatedMRR,
    required this.estimatedARR,
    required this.upToDateTenantsCount,
    required this.pastDueTenantsCount,
    required this.freeTenantsCount,
    required this.b2bEscrowVolume,
  });

  factory SaasMasterOverview.fromJson(Map<String, dynamic> json) {
    return SaasMasterOverview(
      totalFarms: (json['totalFarms'] as num?)?.toInt() ?? 0,
      activeSubscriptions: (json['activeSubscriptions'] as num?)?.toInt() ?? 0,
      totalTanks: (json['totalTanks'] as num?)?.toInt() ?? 0,
      estimatedMRR: (json['estimatedMRR'] as num?)?.toDouble() ?? 0.0,
      estimatedARR: (json['estimatedARR'] as num?)?.toDouble() ?? 0.0,
      upToDateTenantsCount: (json['upToDateTenantsCount'] as num?)?.toInt() ?? 0,
      pastDueTenantsCount: (json['pastDueTenantsCount'] as num?)?.toInt() ?? 0,
      freeTenantsCount: (json['freeTenantsCount'] as num?)?.toInt() ?? 0,
      b2bEscrowVolume: (json['b2bEscrowVolume'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TenantFinancialStatus {
  final String farmId;
  final String farmName;
  final String cnpj;
  final String ownerName;
  final String ownerEmail;
  final String? planId;
  final String planName;
  final double priceMonthly;
  final String status;
  final String statusLabel;
  final String? nextBillingDate;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String paymentMethodType;

  TenantFinancialStatus({
    required this.farmId,
    required this.farmName,
    required this.cnpj,
    required this.ownerName,
    required this.ownerEmail,
    this.planId,
    required this.planName,
    required this.priceMonthly,
    required this.status,
    required this.statusLabel,
    this.nextBillingDate,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    required this.paymentMethodType,
  });

  factory TenantFinancialStatus.fromJson(Map<String, dynamic> json) {
    return TenantFinancialStatus(
      farmId: json['farmId']?.toString() ?? '',
      farmName: json['farmName']?.toString() ?? 'Fazenda',
      cnpj: json['cnpj']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? 'Produtor',
      ownerEmail: json['ownerEmail']?.toString() ?? 'N/A',
      planId: json['planId']?.toString(),
      planName: json['planName']?.toString() ?? 'Plano Gratuito',
      priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'FREE',
      statusLabel: json['statusLabel']?.toString() ?? 'Em dia',
      nextBillingDate: json['nextBillingDate']?.toString(),
      stripeCustomerId: json['stripeCustomerId']?.toString(),
      stripeSubscriptionId: json['stripeSubscriptionId']?.toString(),
      paymentMethodType: json['paymentMethodType']?.toString() ?? 'N/A',
    );
  }
}
