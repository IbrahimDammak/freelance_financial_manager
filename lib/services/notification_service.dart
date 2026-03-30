import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // ── SINGLETON ─────────────────────────────────────────────────────────────
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── CHANNEL IDS ───────────────────────────────────────────────────────────
  static const _chDeadlines = 'fh_deadlines';
  static const _chFinancial = 'fh_financial';
  static const _chActivity = 'fh_activity';
  static const _chReminders = 'fh_reminders';

  // ── INIT ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    // Create Android notification channels
    if (Platform.isAndroid) {
      const channel1 = AndroidNotificationChannel(
        _chDeadlines,
        'Deadlines',
        description: 'Deadline reminders and overdue alerts',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel1);

      const channel2 = AndroidNotificationChannel(
        _chFinancial,
        'Financial & Payments',
        description: 'Payment and financial alerts',
        importance: Importance.high,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel2);

      const channel3 = AndroidNotificationChannel(
        _chActivity,
        'Project Activity',
        description: 'Project status and activity updates',
        importance: Importance.defaultImportance,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel3);

      const channel4 = AndroidNotificationChannel(
        _chReminders,
        'Daily & Periodic Reminders',
        description: 'Routine work log and periodic reminders',
        importance: Importance.defaultImportance,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel4);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTapped,
    );

    _initialized = true;
  }

  // ── PERMISSIONS ───────────────────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? false;

    return iosGranted || androidGranted;
  }

  // ── NOTIFICATION DETAIL BUILDERS ──────────────────────────────────────────
  NotificationDetails _details(String androidChannelId, String androidChannelName) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          importance: androidChannelId == _chDeadlines || androidChannelId == _chFinancial
              ? Importance.high
              : Importance.defaultImportance,
          priority: androidChannelId == _chDeadlines || androidChannelId == _chFinancial
              ? Priority.high
              : Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  // ── CORE PRIMITIVES ───────────────────────────────────────────────────────

  /// Fire an immediate notification.
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
    String channel = _chReminders,
    String channelName = 'Daily Reminders',
  }) async {
    await _plugin.show(id, title, body, _details(channel, channelName));
  }

  /// Schedule a one-time notification at an exact DateTime.
  /// If [scheduledDate] is in the past, does nothing silently.
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channel = _chReminders,
    String channelName = 'Daily Reminders',
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      return; // Silent no-op if in the past
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      _details(channel, channelName),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule a repeating daily notification at [hour]:[minute].
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String channel = _chReminders,
    String channelName = 'Daily Reminders',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _details(channel, channelName),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a repeating weekly notification on [weekday] (1=Mon … 7=Sun).
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    String channel = _chReminders,
    String channelName = 'Daily Reminders',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Adjust to the target weekday
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If that date is in the past, move to next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _details(channel, channelName),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancel a single notification by id.
  Future<void> cancel(int id) => _plugin.cancel(id);

  /// Cancel all scheduled and delivered notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Cancel a range of IDs (inclusive).
  Future<void> cancelRange(int from, int to) async {
    for (var id = from; id <= to; id++) {
      await _plugin.cancel(id);
    }
  }

  void _onTapped(NotificationResponse response) {
    debugPrint('[NotificationService] tapped id=${response.id} payload=${response.payload}');
    // Deep-link navigation can be wired here via a GlobalKey<NavigatorState>
  }
}
