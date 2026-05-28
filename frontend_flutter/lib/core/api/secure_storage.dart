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

  Future<void> saveUserDetails(String email, String accountType, {String? userId}) async {
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_account_type', value: accountType);
    if (userId != null) {
      await _storage.write(key: 'user_id', value: userId);
    }
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

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_account_type');
    await _storage.delete(key: 'user_id');
  }
}

// Provides the TokenStorage wrapper class
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return TokenStorage(storage);
});
