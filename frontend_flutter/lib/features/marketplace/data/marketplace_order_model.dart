class MarketplaceOrder {
  final String id;
  final String announcementId;
  final String announcementTitle;
  final String category;
  final String buyerFarmId;
  final String sellerFarmId;
  final String sellerName;
  final String? buyerName;
  final String? buyerPhone;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryNotes;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final String status; // PENDING_PAYMENT | PAID_HELD | DELIVERED_RELEASED | CANCELLED
  final String paymentMethod; // PIX | CARD
  final String? stripePaymentIntentId;
  final String? stripeClientSecret;
  final String? pixQrCode;
  final String? pixCopyPaste;
  final String createdAt;
  final String? deliveredAt;

  MarketplaceOrder({
    required this.id,
    required this.announcementId,
    required this.announcementTitle,
    required this.category,
    required this.buyerFarmId,
    required this.sellerFarmId,
    required this.sellerName,
    this.buyerName,
    this.buyerPhone,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryNotes,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    this.stripePaymentIntentId,
    this.stripeClientSecret,
    this.pixQrCode,
    this.pixCopyPaste,
    required this.createdAt,
    this.deliveredAt,
  });

  factory MarketplaceOrder.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrder(
      id: json['id']?.toString() ?? '',
      announcementId: json['announcementId']?.toString() ?? '',
      announcementTitle: json['announcementTitle']?.toString() ?? 'Produto',
      category: json['category']?.toString() ?? 'GERAL',
      buyerFarmId: json['buyerFarmId']?.toString() ?? '',
      sellerFarmId: json['sellerFarmId']?.toString() ?? '',
      sellerName: json['sellerName']?.toString() ?? 'Fornecedor Local',
      buyerName: json['buyerName']?.toString(),
      buyerPhone: json['buyerPhone']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString(),
      deliveryCity: json['deliveryCity']?.toString(),
      deliveryState: json['deliveryState']?.toString(),
      deliveryNotes: json['deliveryNotes']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING_PAYMENT',
      paymentMethod: json['paymentMethod']?.toString() ?? 'PIX',
      stripePaymentIntentId: json['stripePaymentIntentId']?.toString(),
      stripeClientSecret: json['stripeClientSecret']?.toString(),
      pixQrCode: json['pixQrCode']?.toString(),
      pixCopyPaste: json['pixCopyPaste']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      deliveredAt: json['deliveredAt']?.toString(),
    );
  }
}
