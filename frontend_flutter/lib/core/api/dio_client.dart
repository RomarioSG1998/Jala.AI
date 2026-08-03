import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/secure_storage.dart';
import 'package:frontend_flutter/features/auth/providers/auth_provider.dart';

String _getEffectiveBaseUrl() {
  const envUrl = String.fromEnvironment('API_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }
  if (kIsWeb) {
    return 'http://localhost:8081';
  }
  return 'https://jala-ai.onrender.com';
}

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = _getEffectiveBaseUrl();
  debugPrint('[DioClient] Detected API baseUrl: $baseUrl');

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      contentType: 'application/json',
    ),
  );

  final tokenStorage = ref.watch(tokenStorageProvider);

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final isAuthEndpoint = options.path.contains('/api/auth/');
      if (!isAuthEndpoint) {
        final token = await tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      final statusCode = e.response?.statusCode;

      // Token expirado ou inválido em rotas protegidas (EXCETO /api/auth/) → fazer logout automático
      final isAuthEndpoint = e.requestOptions.path.contains('/api/auth/');
      if (!isAuthEndpoint && (statusCode == 401 || statusCode == 403)) {
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
