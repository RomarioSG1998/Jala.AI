import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/core/theme/theme_provider.dart';
import 'package:frontend_flutter/core/api/server_ping_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_isLoginMode) {
      await ref.read(authNotifierProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      if (_passwordController.text != _confirmPasswordController.text) {
        ref.read(authNotifierProvider.notifier).state =
            ref.read(authNotifierProvider.notifier).state.copyWith(error: 'As senhas não coincidem!');
        return;
      }
      await ref.read(authNotifierProvider.notifier).register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    ref.watch(themeNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final serverStatus = ref.watch(serverPingProvider);
                        if (serverStatus == ServerStatus.sleeping) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? const Color(0xFF1E293B) 
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark 
                                    ? Colors.orange.shade800.withOpacity(0.5) 
                                    : Colors.orange.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? const Color(0xFF00FF66) : const Color(0xFF13A538)
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Acordando servidor no Render... Por favor, aguarde cerca de 1 minuto.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    Center(
                      child: SizedBox(
                        height: 160,
                        width: 160,
                        child: Image.asset(
                          'web/logo_emblem.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark 
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFF003366), const Color(0xFF005599)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              Icons.water, 
                              size: 64, 
                              color: isDark ? const Color(0xFF00FF66) : const Color(0xFF13A538),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Aqua', 
                            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003366)),
                          ),
                          TextSpan(
                            text: 'Sertão', 
                            style: TextStyle(color: isDark ? const Color(0xFF00FF66) : const Color(0xFF13A538)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PISCICULTURA INTELIGENTE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Error Message
                    if (authState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.red.shade900.withOpacity(0.2)
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                                ? Colors.red.shade800.withOpacity(0.5)
                                : Colors.red.shade300,
                          ),
                        ),
                        child: Text(
                          authState.error!,
                          style: TextStyle(
                            color: isDark ? const Color(0xFFFFB4AB) : Colors.red.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Name Field (Register only)
                    if (!_isLoginMode) ...[
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        onTap: () => _nameFocusNode.requestFocus(),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        autofillHints: const [AutofillHints.name],
                        decoration: InputDecoration(
                          labelText: 'Nome Completo',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          prefixIcon: Icon(Icons.person, color: isDark ? Colors.white70 : Colors.black54),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF003366), 
                              width: 2,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, digite seu nome completo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      onTap: () => _emailFocusNode.requestFocus(),
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        prefixIcon: Icon(Icons.email, color: isDark ? Colors.white70 : Colors.black54),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF003366), 
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite seu email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      onTap: () => _passwordFocusNode.requestFocus(),
                      obscureText: true,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        prefixIcon: Icon(Icons.lock, color: isDark ? Colors.white70 : Colors.black54),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF003366), 
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite sua senha';
                        }
                        if (!_isLoginMode && value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),

                    // Confirm Password Field (Register only)
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        onTap: () => _confirmPasswordFocusNode.requestFocus(),
                        obscureText: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          prefixIcon: Icon(Icons.lock_outline, color: isDark ? Colors.white70 : Colors.black54),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.white30 : Colors.black26),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF003366), 
                              width: 2,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirme sua senha';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: isDark ? const Color(0xFF00FF66) : const Color(0xFF13A538),
                        foregroundColor: isDark ? const Color(0xFF030D1B) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: authState.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: isDark ? const Color(0xFF030D1B) : Colors.white,
                              ),
                            )
                          : Text(
                              _isLoginMode ? 'ENTRAR' : 'CADASTRAR',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                    ),

                    // Toggle Link
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLoginMode ? 'Não tem uma conta?' : 'Já tem uma conta?',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLoginMode = !_isLoginMode;
                              // Clear errors when toggling
                              ref.read(authNotifierProvider.notifier).clearError();
                            });
                          },
                          child: Text(
                            _isLoginMode ? 'Cadastre-se' : 'Entrar',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF00FF66) : const Color(0xFF13A538),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
