class Tank {
  final String id;
  final String name;
  final String fishSpecies;
  final int fishCapacity;

  Tank({
    required this.id,
    required this.name,
    required this.fishSpecies,
    required this.fishCapacity,
  });

  factory Tank.fromJson(Map<String, dynamic> json) {
    return Tank(
      id: json['id'],
      name: json['name'],
      fishSpecies: json['fishSpecies'],
      fishCapacity: json['fishCapacity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fishSpecies': fishSpecies,
      'fishCapacity': fishCapacity,
    };
  }
}
