class ApprovalRequestModel {
  final String id;
  final String farmId;
  final String requesterId;
  final String requestedAction;
  final String status; // PENDING, APPROVED, REJECTED
  final String requestDate;

  ApprovalRequestModel({
    required this.id,
    required this.farmId,
    required this.requesterId,
    required this.requestedAction,
    required this.status,
    required this.requestDate,
  });

  factory ApprovalRequestModel.fromJson(Map<String, dynamic> json) {
    return ApprovalRequestModel(
      id: json['id']?.toString() ?? '',
      farmId: json['farmId']?.toString() ?? '',
      requesterId: json['requesterId']?.toString() ?? '',
      requestedAction: json['requestedAction']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      requestDate: json['requestDate']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmId': farmId,
      'requesterId': requesterId,
      'requestedAction': requestedAction,
      'status': status,
      'requestDate': requestDate,
    };
  }
}
