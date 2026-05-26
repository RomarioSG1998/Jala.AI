import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/auth/data/auth_repository.dart';
import 'dart:convert';

// Represents the authentication state of the app
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final String? email;
  final String? accountType;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.email,
    this.accountType,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    String? email,
    String? accountType,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      email: email ?? this.email,
      accountType: accountType ?? this.accountType,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;
  late final TokenStorage _tokenStorage;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _tokenStorage = ref.watch(tokenStorageProvider);
    
    // Check initial auth state asynchronously without blocking build
    _checkInitialAuth();
    
    return AuthState();
  }

  Future<void> _checkInitialAuth() async {
    final token = await _tokenStorage.getToken();
    final email = await _tokenStorage.getEmail();
    // Prefer accountType from JWT payload (authoritative), fall back to stored value
    String? accountType = _extractAccountTypeFromToken(token);
    accountType ??= await _tokenStorage.getAccountType();

    if (token != null && !_isTokenExpired(token)) {
      // Sync storage with JWT value if needed
      if (accountType != null) {
        await _tokenStorage.saveUserDetails(email ?? '', accountType);
      }
      state = state.copyWith(
        isAuthenticated: true,
        email: email,
        accountType: accountType,
      );
      return;
    }

    // Clear stale/invalid session data to avoid "logged-in but unauthorized" requests.
    if (token != null) {
      await _tokenStorage.clearAll();
    }
  }

  String? _extractAccountTypeFromToken(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payload =
          json.decode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      return payload['accountType'] as String?;
    } catch (_) {
      return null;
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final normalized = base64Url.normalize(parts[1]);
      final payload =
          json.decode(utf8.decode(base64Url.decode(normalized))) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! num) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _repository.login(email, password);
      
      final token = response['token'];
      final resEmail = response['email'];
      final resAccountType = response['accountType'];

      if (token != null) {
        // Always clear any stale session before writing new credentials
        await _tokenStorage.clearAll();
        await _tokenStorage.saveToken(token);
        await _tokenStorage.saveUserDetails(resEmail ?? email, resAccountType ?? 'UNKNOWN');

        state = state.copyWith(
          isLoading: false, 
          isAuthenticated: true,
          email: resEmail ?? email,
          accountType: resAccountType,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Invalid response from server.');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearAll();
    // Reset state entirely
    state = AuthState();
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
