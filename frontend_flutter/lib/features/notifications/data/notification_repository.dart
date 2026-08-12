import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/api/dio_client.dart';
import 'notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<SystemNotification>> fetchMyNotifications() async {
    try {
      final response = await _dio.get('/api/notifications/me');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => SystemNotification.fromJson(item))
            .toList();
      }
    } catch (_) {
      // Retorna lista vazia em caso de offline/erro
    }
    return [];
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _dio.put('/api/notifications/$id/read');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.put('/api/notifications/me/read-all');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _dio.delete('/api/notifications/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
