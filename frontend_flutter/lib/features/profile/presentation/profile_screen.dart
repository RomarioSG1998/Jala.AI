import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/employees/providers/employees_provider.dart';
import 'package:frontend_flutter/features/employees/providers/employee_permissions_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _kNavyBlue = Color(0xFF003366);
  static const _kGreen = Color(0xFF13A538);
  static const _kFarmId = '55555555-5555-5555-5555-555555555555';

  String _formatRole(String? role) {
    if (role == null) return 'Nenhum';
    switch (role) {
      case 'SAAS_ADMIN':
        return 'Administrador SaaS';
      case 'FARM_OWNER':
        return 'Dono da Fazenda';
      case 'CLIENT':
        return 'Cliente';
      case 'FIELD_OPERATOR':
        return 'Operador de Campo';
      default:
        return role;
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'SAAS_ADMIN':
        return Colors.indigo;
      case 'FARM_OWNER':
        return _kGreen;
      case 'CLIENT':
        return Colors.blue;
      case 'FIELD_OPERATOR':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatModuleName(String moduleName) {
    switch (moduleName) {
      case 'tanks':
        return 'Tanques';
      case 'water_quality':
        return 'Qualidade da Água';
      case 'feeding_records':
        return 'Alimentação';
      case 'inventory':
        return 'Estoque';
      case 'harvests':
        return 'Colheitas';
      case 'maintenance':
        return 'Manutenção';
      default:
        return moduleName;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final employeesAsync = ref.watch(employeesProvider);

    // Try to find full name from the employee list
    String displayName = authState.email?.split('@').first ?? 'Usuário';
    if (employeesAsync.hasValue && authState.userId != null) {
      final match = employeesAsync.value!.where((emp) => emp.id == authState.userId).firstOrNull;
      if (match != null) {
        displayName = match.name;
      } else {
        // format email prefix
        displayName = displayName
            .split('.')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '')
            .join(' ');
      }
    }

    final initials = displayName.isNotEmpty
        ? displayName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'U';

    final roleLabel = _formatRole(authState.accountType);
    final roleColor = _getRoleColor(authState.accountType);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _kNavyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Top Header Gradient
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kNavyBlue, Color(0xFF004488)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                children: [
                  // Profile Photo
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.2),
                      border: Border.all(color: roleColor.withOpacity(0.5), width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Cards
                  _buildSectionTitle('Informações da Conta'),
                  _buildInfoCard([
                    _buildInfoTile(Icons.email_outlined, 'E-mail', authState.email ?? 'Não informado'),
                    _buildDivider(),
                    _buildInfoTile(Icons.vpn_key_outlined, 'ID de Usuário', authState.userId ?? 'Não informado'),
                    _buildDivider(),
                    _buildInfoTile(
                      Icons.check_circle_outline,
                      'Status da Conta',
                      'Ativo',
                      trailing: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kGreen,
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // Display operator permissions if they are a FIELD_OPERATOR
                  if (authState.accountType == 'FIELD_OPERATOR' && authState.userId != null) ...[
                    _buildSectionTitle('Minhas Permissões de Módulo'),
                    ref.watch(currentUserPermissionsProvider('${authState.userId}:$_kFarmId')).when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: _kNavyBlue),
                        ),
                      ),
                      error: (err, _) => _buildInfoCard([
                        ListTile(
                          leading: const Icon(Icons.error_outline, color: Colors.red),
                          title: const Text('Erro ao carregar permissões', style: TextStyle(fontSize: 14)),
                        )
                      ]),
                      data: (perms) {
                        if (perms.isEmpty) {
                          return _buildInfoCard([
                            const ListTile(
                              leading: Icon(Icons.info_outline, color: Colors.grey),
                              title: Text('Nenhuma permissão configurada', style: TextStyle(fontSize: 14)),
                            )
                          ]);
                        }
                        return _buildInfoCard(
                          perms.map((p) {
                            final idx = perms.indexOf(p);
                            final isLast = idx == perms.length - 1;
                            return Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    p.isEnabled ? Icons.check_circle : Icons.cancel,
                                    color: p.isEnabled ? _kGreen : Colors.red,
                                  ),
                                  title: Text(
                                    _formatModuleName(p.moduleName),
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: p.isEnabled ? _kGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.isEnabled ? 'Permitido' : 'Bloqueado',
                                      style: TextStyle(
                                        color: p.isEnabled ? _kGreen : Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!isLast) _buildDivider(),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions Section
                  _buildSectionTitle('Ações'),
                  InkWell(
                    onTap: () {
                      ref.read(authNotifierProvider.notifier).logout();
                      context.go('/login');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade100, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade50.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout, color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Sair da Conta',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: _kNavyBlue.withOpacity(0.7), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F6));
  }
}
