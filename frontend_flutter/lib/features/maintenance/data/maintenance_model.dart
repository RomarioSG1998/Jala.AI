class MaintenanceTask {
  final String id;
  final String farmId;
  final String tankId;
  final String description;
  final String status;
  final String scheduledDate;

  MaintenanceTask({
    required this.id,
    required this.farmId,
    required this.tankId,
    required this.description,
    required this.status,
    required this.scheduledDate,
  });

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'],
      farmId: json['farmId'] ?? '',
      tankId: json['tankId'] ?? '',
      description: json['description'],
      status: json['status'],
      scheduledDate: json['scheduledDate'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmId': farmId,
        'tankId': tankId,
        'description': description,
        'status': status,
        'scheduledDate': scheduledDate,
      };
}
