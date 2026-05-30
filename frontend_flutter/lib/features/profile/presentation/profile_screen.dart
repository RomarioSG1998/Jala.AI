import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/employees/providers/employees_provider.dart';
import 'package:frontend_flutter/features/employees/providers/employee_permissions_provider.dart';
import 'package:frontend_flutter/core/theme/theme_provider.dart';
import 'dart:convert';
import 'package:frontend_flutter/features/profile/providers/profile_image_provider.dart';

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
    final profileImage = authState.userId != null
        ? ref.watch(profileImageProvider(authState.userId!))
        : null;

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

    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  Stack(
                    children: [
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
                          backgroundImage: profileImage != null
                              ? MemoryImage(base64Decode(profileImage))
                              : null,
                          child: profileImage == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (authState.userId != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () => _showImageOptions(context, ref, authState.userId!, profileImage != null),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _kGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
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
                  _buildSectionTitle(context, 'Informações da Conta'),
                  _buildInfoCard(context, [
                    _buildInfoTile(context, Icons.email_outlined, 'E-mail', authState.email ?? 'Não informado'),
                    _buildDivider(context),
                    _buildInfoTile(
                      context,
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
                    _buildSectionTitle(context, 'Minhas Permissões de Módulo'),
                    ref.watch(currentUserPermissionsProvider('${authState.userId}:$_kFarmId')).when(
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(color: isDark ? Colors.blue : _kNavyBlue),
                        ),
                      ),
                      error: (err, _) => _buildInfoCard(context, [
                        ListTile(
                          leading: const Icon(Icons.error_outline, color: Colors.red),
                          title: Text(
                            'Erro ao carregar permissões',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        )
                      ]),
                      data: (perms) {
                        if (perms.isEmpty) {
                          return _buildInfoCard(context, [
                            ListTile(
                              leading: const Icon(Icons.info_outline, color: Colors.grey),
                              title: Text(
                                'Nenhuma permissão configurada',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            )
                          ]);
                        }
                        return _buildInfoCard(context,
                          perms.map<Widget>((p) {
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
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
                                if (!isLast) _buildDivider(context),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Settings Section
                  _buildSectionTitle(context, 'Configurações'),
                  _buildInfoCard(context, [
                    ListTile(
                      leading: Icon(
                        themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                        color: isDark ? Colors.blue.shade300 : _kNavyBlue.withOpacity(0.7),
                      ),
                      title: Text(
                        'Tema Escuro',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        themeMode == ThemeMode.dark ? 'Ativado' : 'Desativado',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.grey,
                        ),
                      ),
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        activeColor: _kGreen,
                        onChanged: (val) {
                          ref.read(themeNotifierProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Actions Section
                  _buildSectionTitle(context, 'Ações'),
                  InkWell(
                    onTap: () {
                      ref.read(authNotifierProvider.notifier).logout();
                      context.go('/login');
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.red.shade900.withOpacity(0.5) : Colors.red.shade100, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.transparent : Colors.red.shade50.withOpacity(0.5),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF263350), width: 1) : null,
        boxShadow: [
          if (!isDark)
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

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value, {Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.blue.shade200 : _kNavyBlue.withOpacity(0.7), size: 22),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF263350) : const Color(0xFFF1F3F6));
  }

  void _showImageOptions(BuildContext context, WidgetRef ref, String userId, bool hasImage) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.photo_library, color: isDark ? Colors.blue.shade300 : _kNavyBlue),
                title: Text(
                  'Escolher da Galeria',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(profileImageProvider(userId).notifier).pickAndSetImage();
                },
              ),
              if (hasImage) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remover Foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(profileImageProvider(userId).notifier).clearImage();
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
