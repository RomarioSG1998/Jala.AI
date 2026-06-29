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
  final String? name;
  final String? accountType;
  final String? userId;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.email,
    this.name,
    this.accountType,
    this.userId,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    String? email,
    String? name,
    String? accountType,
    String? userId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      email: email ?? this.email,
      name: name ?? this.name,
      accountType: accountType ?? this.accountType,
      userId: userId ?? this.userId,
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
    // Check auth state in background — router starts at /login immediately
    _checkInitialAuth();
    return AuthState();
  }

  Future<void> _checkInitialAuth() async {
    try {
      final token = await _tokenStorage.getToken();
      final email = await _tokenStorage.getEmail();
      final userId = await _tokenStorage.getUserId();
      final name = await _tokenStorage.getName();
      // Prefer accountType from JWT payload (authoritative), fall back to stored value
      String? accountType = _extractAccountTypeFromToken(token);
      accountType ??= await _tokenStorage.getAccountType();

      if (token != null && !_isTokenExpired(token)) {
        // Sync storage with JWT value if needed
        if (accountType != null) {
          await _tokenStorage.saveUserDetails(email ?? '', accountType, userId: userId, name: name);
        }
        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          email: email,
          name: name,
          accountType: accountType,
          userId: userId,
        );
        return;
      }

      // Clear stale/invalid session data to avoid "logged-in but unauthorized" requests.
      if (token != null) {
        await _tokenStorage.clearAll();
      }
    } catch (e) {
      // Storage unavailable (e.g. browser blocks IndexedDB in incognito) — treat as logged out.
    }

    // Auth check complete — not authenticated
    state = AuthState(isLoading: false, isAuthenticated: false);
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
      final resName = response['name'];
      final resAccountType = response['accountType'];

      if (token != null) {
        // Always clear any stale session before writing new credentials
        await _tokenStorage.clearAll();
        await _tokenStorage.saveToken(token);
        await _tokenStorage.saveUserDetails(
          resEmail ?? email,
          resAccountType ?? 'UNKNOWN',
          userId: response['userId']?.toString(),
          name: resName,
          farmId: response['farmId']?.toString(),
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          email: resEmail ?? email,
          name: resName,
          accountType: resAccountType,
          userId: response['userId']?.toString(),
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

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String accountType = 'CLIENT',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
        accountType: accountType,
      );
      
      final token = response['token'];
      final resEmail = response['email'];
      final resName = response['name'];
      final resAccountType = response['accountType'];

      if (token != null) {
        await _tokenStorage.clearAll();
        await _tokenStorage.saveToken(token);
        await _tokenStorage.saveUserDetails(
          resEmail ?? email,
          resAccountType ?? accountType,
          userId: response['userId']?.toString(),
          name: resName ?? name,
          farmId: response['farmId']?.toString(),
        );

        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          email: resEmail ?? email,
          name: resName ?? name,
          accountType: resAccountType ?? accountType,
          userId: response['userId']?.toString(),
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

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    final userId = state.userId;
    if (userId == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.updateProfile(
        userId: userId,
        name: name,
        email: email,
        password: password,
      );

      final token = response['token'];
      final resEmail = response['email'];
      final resName = response['name'];
      final resAccountType = response['accountType'];

      if (token != null) {
        await _tokenStorage.saveToken(token);
        await _tokenStorage.saveUserDetails(
          resEmail ?? email,
          resAccountType ?? state.accountType ?? 'UNKNOWN',
          userId: userId,
          name: resName ?? name,
          farmId: response['farmId']?.toString(),
        );

        state = state.copyWith(
          isLoading: false,
          email: resEmail ?? email,
          name: resName ?? name,
          accountType: resAccountType ?? state.accountType,
          error: null,
        );
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Resposta inválida do servidor.');
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

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
