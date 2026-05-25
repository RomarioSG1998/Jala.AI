import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/auth/data/auth_repository.dart';

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
    final accountType = await _tokenStorage.getAccountType();

    if (token != null) {
      state = state.copyWith(
        isAuthenticated: true,
        email: email,
        accountType: accountType,
      );
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
