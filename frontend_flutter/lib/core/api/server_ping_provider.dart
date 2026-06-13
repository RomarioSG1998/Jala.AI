import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';

enum ServerStatus { checking, sleeping, awake, error }

class ServerPingNotifier extends Notifier<ServerStatus> {
  @override
  ServerStatus build() {
    checkServer();
    return ServerStatus.checking;
  }

  Future<void> checkServer() async {
    final dio = ref.read(dioProvider);
    
    // 1. Quick initial ping (timeout 3 seconds)
    try {
      final tempDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      await tempDio.get('/api/auth/health');
      state = ServerStatus.awake;
      return;
    } catch (e) {
      if (e is DioException && e.response != null) {
        state = ServerStatus.awake;
        return;
      }
      // If it fails or times out, the server is likely sleeping
      state = ServerStatus.sleeping;
    }

    // 2. Perform wake-up loop with long timeout (60 seconds)
    _wakeUpLoop(dio);
  }

  Future<void> _wakeUpLoop(Dio dio) async {
    int attempts = 0;
    while (state == ServerStatus.sleeping && attempts < 3) {
      attempts++;
      try {
        final tempDio = Dio(BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ));
        await tempDio.get('/api/auth/health');
        state = ServerStatus.awake;
        break;
      } catch (e) {
        if (e is DioException && e.response != null) {
          state = ServerStatus.awake;
          break;
        }
        if (attempts >= 3) {
          state = ServerStatus.error;
        } else {
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }
  }
}

final serverPingProvider = NotifierProvider<ServerPingNotifier, ServerStatus>(
  ServerPingNotifier.new,
);
