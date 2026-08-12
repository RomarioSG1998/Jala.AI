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
  if (kDebugMode) {
    return 'http://10.0.2.2:8081';
  }
  return 'https://jala-ai.onrender.com';
}

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = _getEffectiveBaseUrl();
  debugPrint('[DioClient] Detected API baseUrl: $baseUrl');

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 120), // 120s para aguardar o spin-up do Render
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 120),
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
      final isAuthEndpoint = e.requestOptions.path.contains('/api/auth/');

      // 1. Token expirado ou inválido em rotas protegidas (EXCETO /api/auth/) → fazer logout automático
      if (!isAuthEndpoint && (statusCode == 401 || statusCode == 403)) {
        try {
          await ref.read(authNotifierProvider.notifier).logout();
        } catch (_) {
          await tokenStorage.clearAll();
        }

        return handler.reject(
          DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: DioExceptionType.badResponse,
            error: 'Sessão expirada. Por favor, faça login novamente.',
          ),
        );
      }

      // 2. Tratar Render Cold-Start (Tempo de inicialização do servidor Render: Timeout, Erro de Conexão, 502, 503, 504)
      final isNetworkOrTimeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError ||
          statusCode == 502 ||
          statusCode == 503 ||
          statusCode == 504;

      final retriesCount = (e.requestOptions.extra['retries'] as int? ?? 0);
      const maxRetries = 3;

      if (isNetworkOrTimeout && retriesCount < maxRetries) {
        e.requestOptions.extra['retries'] = retriesCount + 1;
        final delaySeconds = (retriesCount + 1) * 3; // 3s, 6s, 9s
        debugPrint('[DioClient] Servidor em inicialização/standby (Render). Tentativa ${retriesCount + 1}/$maxRetries aguardando $delaySeconds segundos...');

        await Future.delayed(Duration(seconds: delaySeconds));

        try {
          final response = await dio.fetch(e.requestOptions);
          return handler.resolve(response);
        } catch (retryErr) {
          if (retryErr is DioException) {
            return handler.next(retryErr);
          }
        }
      }

      return handler.next(e);
    },
  ));

  return dio;
});
