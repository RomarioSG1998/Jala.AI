import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:ui';

/// Centralized notification service for AquaGestor.
/// Manages local scheduled notifications for feeding, biometry, water renewal and harvest alerts.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Notification channel IDs ──────────────────────────────────────────────
  static const String _feedingChannelId = 'aqua_feeding';
  static const String _biometryChannelId = 'aqua_biometry';
  static const String _waterChannelId = 'aqua_water';
  static const String _harvestChannelId = 'aqua_harvest';

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Fortaleza'));

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Android 13+ runtime permission request
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Schedule helpers ──────────────────────────────────────────────────────

  /// Schedule daily feeding reminder at a specific hour and minute.
  Future<void> scheduleDailyFeeding({
    required int hour,
    required int minute,
    String tankName = '',
  }) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      1001,
      '🐟 Hora de Alimentar!',
      tankName.isNotEmpty ? 'Alimente os peixes do $tankName agora.' : 'Hora do arraçoamento dos seus tanques!',
      _nextInstanceOfTime(hour, minute),
      _androidDetails(_feedingChannelId, 'Alimentação'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule weekly biometry reminder (every 15 days starting from now).
  Future<void> scheduleBiometryReminder({String tankName = ''}) async {
    await _ensureInitialized();
    final next = tz.TZDateTime.now(tz.local).add(const Duration(days: 15));
    await _plugin.zonedSchedule(
      1002,
      '📏 Faça a Biometria!',
      tankName.isNotEmpty ? 'Registre o peso médio no $tankName.' : 'É hora de medir o peso médio dos seus peixes.',
      next,
      _androidDetails(_biometryChannelId, 'Biometria'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule water renewal reminder in N days.
  Future<void> scheduleWaterRenewal({int inDays = 7}) async {
    await _ensureInitialized();
    final next = tz.TZDateTime.now(tz.local).add(Duration(days: inDays));
    await _plugin.zonedSchedule(
      1003,
      '💧 Renovação de Água',
      'Hora de verificar e renovar a água dos tanques.',
      next,
      _androidDetails(_waterChannelId, 'Qualidade da Água'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule a harvest alert on the expected date.
  Future<void> scheduleHarvestAlert({
    required DateTime harvestDate,
    required String tankName,
    int daysBeforeAlert = 7,
  }) async {
    await _ensureInitialized();
    final alertDate = harvestDate.subtract(Duration(days: daysBeforeAlert));
    if (alertDate.isBefore(DateTime.now())) return; // Already past

    await _plugin.zonedSchedule(
      1004 + tankName.hashCode.abs() % 100,
      '🎣 Despesca se Aproxima!',
      'O $tankName tem despesca prevista em $daysBeforeAlert dias. Prepare-se!',
      tz.TZDateTime.from(alertDate, tz.local),
      _androidDetails(_harvestChannelId, 'Despesca'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Show an immediate local notification (for testing or urgent alerts).
  Future<void> showImmediate({
    required String title,
    required String body,
    int id = 9999,
  }) async {
    await _ensureInitialized();
    await _plugin.show(id, title, body, _androidDetails(_feedingChannelId, 'Alertas'));
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  NotificationDetails _androidDetails(String channelId, String channelName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/launcher_icon',
        color: const Color(0xFF13A538),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
