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
    String accountType = 'CLIENT',
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'accountType': accountType,
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

  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String name,
    String? photoUrl,
    String? idToken,
    String accountType = 'CLIENT',
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/google',
        data: {
          'email': email,
          'name': name,
          'photoUrl': photoUrl,
          'idToken': idToken,
          'accountType': accountType,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Falha ao autenticar com a Conta Google.');
      }
      throw Exception('Erro de conexão ao entrar com o Google.');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String name,
    required String email,
    String? password,
  }) async {
    try {
      final response = await _dio.put(
        '/api/auth/profile/$userId',
        data: {
          'name': name,
          'email': email,
          if (password != null && password.trim().isNotEmpty) 'password': password,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['message'] ?? 'Falha ao atualizar o perfil.');
      }
      throw Exception('Erro de rede. Tente novamente mais tarde.');
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
