class SystemNotification {
  final String id;
  final String? targetUserId;
  final String title;
  final String type;
  final String message;
  final bool isRead;
  final String? createdAt;

  SystemNotification({
    required this.id,
    this.targetUserId,
    required this.title,
    required this.type,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  factory SystemNotification.fromJson(Map<String, dynamic> json) {
    return SystemNotification(
      id: json['id']?.toString() ?? '',
      targetUserId: json['targetUserId']?.toString(),
      title: json['title'] != null && json['title'].toString().isNotEmpty
          ? json['title'].toString()
          : _formatTypeTitle(json['type']?.toString()),
      type: json['type']?.toString() ?? 'SYSTEM',
      message: json['message']?.toString() ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt']?.toString(),
    );
  }

  static String _formatTypeTitle(String? type) {
    if (type == null) return 'Aviso do Sistema';
    switch (type.toUpperCase()) {
      case 'TENANT_REGISTERED': return 'Novo Cliente Cadastrado';
      case 'SUPPLIER_APPROVED': return 'Fornecedor Aprovado';
      case 'WATER_QUALITY_ALERT': return 'Alerta de Qualidade da Água';
      case 'MAINTENANCE': return 'Alerta de Manutenção';
      case 'USER_STATUS': return 'Status da Conta Atualizado';
      default: return 'Notificação';
    }
  }
}
