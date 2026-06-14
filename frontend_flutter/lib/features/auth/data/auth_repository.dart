import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      
      // Returns { "token": "...", "email": "...", "accountType": "..." }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Login failed. Please check your credentials.');
      }
      throw Exception('Network error. Please try again later.');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'accountType': 'CLIENT',
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Registration failed.');
      }
      throw Exception('Network error. Please try again later.');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
