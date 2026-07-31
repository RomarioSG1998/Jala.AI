class SupplierProfile {
  final String id;
  final String farmId;
  final String companyName;
  final String? documentNumber;
  final String? stateRegistration;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pixKey;
  final String? pixKeyType;
  final bool verified;
  final String createdAt;

  SupplierProfile({
    required this.id,
    required this.farmId,
    required this.companyName,
    this.documentNumber,
    this.stateRegistration,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pixKey,
    this.pixKeyType,
    required this.verified,
    required this.createdAt,
  });

  factory SupplierProfile.fromJson(Map<String, dynamic> json) {
    return SupplierProfile(
      id: json['id']?.toString() ?? '',
      farmId: json['farmId']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? 'Fornecedor Local',
      documentNumber: json['documentNumber']?.toString(),
      stateRegistration: json['stateRegistration']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pixKey: json['pixKey']?.toString(),
      pixKeyType: json['pixKeyType']?.toString() ?? 'CPF_CNPJ',
      verified: json['verified'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
