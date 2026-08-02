import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';
import 'package:frontend_flutter/features/auth/data/auth_repository.dart';

class PasswordConfirmationDialog extends StatefulWidget {
  final WidgetRef ref;
  const PasswordConfirmationDialog({super.key, required this.ref});

  static Future<bool> confirm(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordConfirmationDialog(ref: ref),
    );
    return result ?? false;
  }

  @override
  State<PasswordConfirmationDialog> createState() => _PasswordConfirmationDialogState();
}

class _PasswordConfirmationDialogState extends State<PasswordConfirmationDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'A senha não pode ser vazia.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = widget.ref.read(authNotifierProvider);
      final email = authState.email;
      if (email == null) {
        setState(() {
          _errorMessage = 'Usuário não autenticado.';
          _isLoading = false;
        });
        return;
      }

      final response = await widget.ref.read(authRepositoryProvider).login(email, password);
      if (response['token'] != null) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = 'Senha incorreta.';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Senha incorreta.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: Theme.of(context).brightness == Brightness.dark
            ? const BorderSide(color: Color(0xFF263350), width: 1.0)
            : BorderSide.none,
      ),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text('Confirmar Exclusão', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Por motivos de segurança, confirme sua senha de acesso para autorizar a exclusão.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Sua Senha',
                errorText: _errorMessage,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.password),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
              onSubmitted: (_) => _confirm,
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isLoading ? null : _confirm,
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
