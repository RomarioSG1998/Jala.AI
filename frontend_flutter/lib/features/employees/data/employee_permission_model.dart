class EmployeePermission {
  final String moduleName;
  final bool isEnabled;

  const EmployeePermission({required this.moduleName, required this.isEnabled});

  factory EmployeePermission.fromJson(Map<String, dynamic> json) {
    return EmployeePermission(
      moduleName: json['moduleName'] as String,
      isEnabled: json['isEnabled'] as bool,
    );
  }

  EmployeePermission copyWith({bool? isEnabled}) {
    return EmployeePermission(
      moduleName: moduleName,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Human-readable info for each module key
class ModuleInfo {
  final String key;
  final String label;
  final String description;

  const ModuleInfo({required this.key, required this.label, required this.description});
}

const kAvailableModules = [
  ModuleInfo(key: 'tanks',          label: 'Tanques',            description: 'Visualizar e operar tanques'),
  ModuleInfo(key: 'water_quality',  label: 'Qualidade da Água',  description: 'Registrar leituras de pH e oxigênio'),
  ModuleInfo(key: 'inventory',      label: 'Estoque',            description: 'Consultar e movimentar estoque'),
  ModuleInfo(key: 'feeding_records',label: 'Alimentação',        description: 'Registrar tratos diários'),
  ModuleInfo(key: 'harvests',       label: 'Colheitas',          description: 'Registrar e consultar despescas'),
  ModuleInfo(key: 'maintenance',    label: 'Manutenção',         description: 'Ver e atualizar tarefas de manutenção'),
];
