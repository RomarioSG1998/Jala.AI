class Employee {
  final String id;
  final String name;
  final String email;
  final String accountType;
  final String? farmId;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.accountType,
    this.farmId,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      accountType: json['accountType'] as String,
      farmId: json['farmId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'accountType': accountType,
      if (farmId != null) 'farmId': farmId,
    };
  }
}
