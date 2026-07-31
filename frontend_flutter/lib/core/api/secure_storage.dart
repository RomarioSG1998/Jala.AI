import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Provides a singleton instance of FlutterSecureStorage
// On Web, uses localStorage via WebOptions (flutter_secure_storage >= 5.0)
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  if (kIsWeb) {
    // No publicKey = no crypto overhead — avoids IndexedDB initialization hangs on web
    return const FlutterSecureStorage(
      webOptions: WebOptions(dbName: 'aquasertao_secure'),
    );
  }
  return const FlutterSecureStorage();
});

class TokenStorage {
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'jwt_token';

  TokenStorage(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> saveUserDetails(String email, String accountType, {String? userId, String? name, String? farmId}) async {
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_account_type', value: accountType);
    if (userId != null) {
      await _storage.write(key: 'user_id', value: userId);
    }
    if (name != null) {
      await _storage.write(key: 'user_name', value: name);
    }
    if (farmId != null) {
      await _storage.write(key: 'farm_id', value: farmId);
    }
  }

  Future<String?> getName() async {
    return await _storage.read(key: 'user_name');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: 'user_email');
  }

  Future<String?> getAccountType() async {
    return await _storage.read(key: 'user_account_type');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String?> getFarmId() async {
    return await _storage.read(key: 'farm_id');
  }

  Future<void> saveRememberMeCredentials(String email, String password) async {
    await _storage.write(key: 'remember_email', value: email);
    await _storage.write(key: 'remember_password', value: password);
    await _storage.write(key: 'remember_me_enabled', value: 'true');
  }

  Future<void> clearRememberMeCredentials() async {
    await _storage.delete(key: 'remember_email');
    await _storage.delete(key: 'remember_password');
    await _storage.write(key: 'remember_me_enabled', value: 'false');
  }

  Future<Map<String, String>?> getRememberMeCredentials() async {
    final email = await _storage.read(key: 'remember_email');
    final password = await _storage.read(key: 'remember_password');
    final enabled = await _storage.read(key: 'remember_me_enabled');
    if (enabled == 'true' && email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<bool> isRememberMeEnabled() async {
    final enabled = await _storage.read(key: 'remember_me_enabled');
    return enabled == 'true';
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_account_type');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'farm_id');
  }
}

// Provides the TokenStorage wrapper class
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TokenStorage(storage);
});
