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
