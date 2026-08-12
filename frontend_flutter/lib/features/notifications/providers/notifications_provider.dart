import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_model.dart';
import '../data/notification_repository.dart';

final userNotificationsProvider = FutureProvider<List<SystemNotification>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.fetchMyNotifications();
});
