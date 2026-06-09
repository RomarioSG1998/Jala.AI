import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://aquagestor.onrender.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );

  final tokenStorage = ref.watch(tokenStorageProvider);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await tokenStorage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      final statusCode = e.response?.statusCode;

      // Token expirado ou inválido → fazer logout automático
      if (statusCode == 401 || statusCode == 403) {
        try {
          await ref.read(authNotifierProvider.notifier).logout();
        } catch (_) {
          // Se o notifier já foi dispose, ignorar
          await tokenStorage.clearAll();
        }

        // Rejeitar com mensagem clara para o provider exibir
        return handler.reject(
          DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: DioExceptionType.badResponse,
            error: 'Sessão expirada. Por favor, faça login novamente.',
          ),
        );
      }

      return handler.next(e);
    },
  ));

  return dio;
});
