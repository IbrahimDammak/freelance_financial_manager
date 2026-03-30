# FEATURE 5 — COMPREHENSIVE PUSH NOTIFICATION SYSTEM
## Periodic + Event-Based Notifications (All 15 Use Cases)

## SCOPE
This prompt expands the existing `NotificationService` (defined in Feature 3) with all 15 notification use cases. It replaces the `rescheduleDeadlineNotifications()` method and adds a complete notification engine covering periodic reminders, deadline tracking, financial alerts, project health checks, and milestone events.

**Files to modify or create:**
- `lib/services/notification_service.dart` — full replacement
- `lib/models/app_settings.dart` — add new preference fields
- `lib/providers/settings_provider.dart` — add new preference methods
- `lib/providers/data_provider.dart` — add event-based trigger calls
- `lib/screens/notification_settings_screen.dart` — full replacement with all toggles
- `lib/services/notification_scheduler.dart` — **create new** (orchestrator)

All other files remain unchanged.

---

## NOTIFICATION ID RESERVATION TABLE

Every notification must use a **globally unique, stable integer ID**. Never reuse IDs across categories. Use these exact ranges:

| Range | Category |
|---|---|
| `1` | Welcome (onboarding) |
| `10` | Daily work log reminder |
| `11` | Unlogged timer warning |
| `20` | Weekly revenue digest |
| `30` | Outstanding payments weekly |
| `40` | No income mid-month alert |
| `50–99` | Maintenance fee reminders (50 + client index, max 50 clients) |
| `100–199` | Client anniversary (100 + client index) |
| `200–299` | New project idle check (200 + project index) |
| `300–399` | Idle project weekly (300 + project index) |
| `1000–1999` | Deadline –7 days (1000 + project index) |
| `2000–2999` | Deadline –1 day (2000 + project index) |
| `3000–3999` | Deadline day morning (3000 + project index) |
| `4000–4999` | Overdue daily (4000 + project index) |
| `5000` | Payment complete (immediate — reused, auto-dismissed) |
| `5001` | Project completion celebration (immediate — reused) |

**Project index** = stable integer derived from project id hash:
```dart
int stableIndex(String id) => id.hashCode.abs() % 900;
```

**Client index** = same pattern:
```dart
int stableClientIndex(String id) => id.hashCode.abs() % 50;
```

---

## ANDROID NOTIFICATION CHANNELS

Replace the single `'freelancehub_main'` channel with **4 separate channels** for better user control in Android settings:

```dart
// Channel definitions — create all 4 during init()
static const _chDeadlines   = 'fh_deadlines';    // Deadlines
static const _chFinancial   = 'fh_financial';    // Financial & Payments
static const _chActivity    = 'fh_activity';     // Project Activity
static const _chReminders   = 'fh_reminders';    // Daily & Periodic Reminders

AndroidNotificationDetails _androidChannel(String channelId, String channelName, {
  Importance importance = Importance.high,
  Priority priority = Priority.high,
}) => AndroidNotificationDetails(
  channelId, channelName,
  importance: importance,
  priority: priority,
  icon: '@mipmap/ic_launcher',
  styleInformation: const BigTextStyleInformation(''),
);
```

Use the correct channel per notification type:
- Deadline notifications → `_chDeadlines`
- Payment / financial → `_chFinancial`
- Project activity, idle warnings → `_chActivity`
- Daily log reminder, weekly digest, timer warning → `_chReminders`

---

## FULL `lib/services/notification_service.dart` REPLACEMENT

Replace the entire file with the following. Do not keep any code from the previous version.

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/client.dart';
import '../models/project.dart';
import '../utils.dart';

class NotificationService {
  // ── SINGLETON ─────────────────────────────────────────────────────────────
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── CHANNEL IDS ───────────────────────────────────────────────────────────
  static const _chDeadlines  = 'fh_deadlines';
  static const _chFinancial  = 'fh_financial';
  static const _chActivity   = 'fh_activity';
  static const _chReminders  = 'fh_reminders';

  // ── INIT ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onTapped,
    );

    // Create Android channels
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _chDeadlines, 'Deadlines',
        description: 'Project deadline warnings and reminders',
        importance: Importance.high,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _chFinancial, 'Financial',
        description: 'Payment reminders and revenue summaries',
        importance: Importance.defaultImportance,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _chActivity, 'Project Activity',
        description: 'Project health checks and milestones',
        importance: Importance.defaultImportance,
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _chReminders, 'Daily Reminders',
        description: 'Work log reminders and periodic digests',
        importance: Importance.low,
      ));
    }
    _initialized = true;
  }

  // ── PERMISSIONS ───────────────────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true, badge: true, sound: true,
    ) ?? false;

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
          androidChannelId, androidChannelName,
          importance: androidChannelId == _chDeadlines
              ? Importance.high : Importance.defaultImportance,
          priority: androidChannelId == _chDeadlines
              ? Priority.high : Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
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
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id, title, body, tzDate,
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
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id, title, body, scheduled,
      _details(channel, channelName),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
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
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id, title, body, scheduled,
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
```

---

## NEW FILE: `lib/services/notification_scheduler.dart`

This class is the **orchestrator** — it reads app data and preferences, then calls `NotificationService` to schedule or cancel the right notifications. `DataProvider` calls `NotificationScheduler.rescheduleAll()` after any data mutation. `SettingsProvider` calls `NotificationScheduler.rescheduleAll()` after any preference change.

```dart
import '../models/client.dart';
import '../models/project.dart';
import '../models/app_settings.dart';
import '../utils.dart';
import 'notification_service.dart';

class NotificationScheduler {
  static final NotificationScheduler _i = NotificationScheduler._();
  factory NotificationScheduler() => _i;
  NotificationScheduler._();

  final _svc = NotificationService();

  // ── MASTER RESCHEDULE ─────────────────────────────────────────────────────
  /// Call this after ANY data or settings change.
  /// Cancels all existing notifications and rebuilds from scratch.
  Future<void> rescheduleAll({
    required List<Client> clients,
    required AppSettings settings,
  }) async {
    // If master toggle is off, cancel everything and stop
    if (!settings.notificationsEnabled) {
      await _svc.cancelAll();
      return;
    }

    await _svc.cancelAll();

    final allProjects = clients.expand((c) => c.projects).toList();
    final activeProjects = allProjects.where((p) => p.status == 'active').toList();

    // ── PERIODIC ────────────────────────────────────────────────
    if (settings.notifyDailyLog) {
      await _scheduleDailyLogReminder(settings, allProjects);
    }
    if (settings.notifyWeeklyDigest) {
      await _scheduleWeeklyDigest(clients, settings);
    }

    // ── DEADLINE ────────────────────────────────────────────────
    for (var i = 0; i < activeProjects.length; i++) {
      final p = activeProjects[i];
      final idx = stableIndex(p.id);
      await _scheduleDeadlineNotifications(p, idx, settings);
      await _scheduleOverdueDaily(p, idx, settings);
    }

    // ── FINANCIAL ───────────────────────────────────────────────
    if (settings.notifyOutstandingWeekly) {
      await _scheduleOutstandingWeekly(allProjects, settings);
    }
    if (settings.notifyMaintenanceMonthly) {
      await _scheduleMaintenanceReminders(clients, settings);
    }
    if (settings.notifyNoIncome) {
      await _scheduleNoIncomeAlert(allProjects, settings);
    }

    // ── PROJECT ACTIVITY ────────────────────────────────────────
    if (settings.notifyIdleProject) {
      for (var i = 0; i < activeProjects.length; i++) {
        final p = activeProjects[i];
        await _scheduleIdleProjectWarning(p, stableIndex(p.id), settings);
      }
    }
    if (settings.notifyNewProjectIdle) {
      for (final p in activeProjects) {
        await _scheduleNewProjectIdleCheck(p, stableIndex(p.id), settings);
      }
    }

    // ── CLIENT MILESTONES ───────────────────────────────────────
    if (settings.notifyClientAnniversary) {
      for (var i = 0; i < clients.length; i++) {
        await _scheduleClientAnniversary(clients[i], stableClientIndex(clients[i].id));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 1 — Daily Work Log Reminder
  // Every day at user-chosen time. Condition checked at runtime inside app
  // (if today sessions > 0, the user opens the app and the notif is auto-
  //  dismissed — we still schedule it daily and rely on the user dismissing).
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleDailyLogReminder(AppSettings settings, List<Project> allProjects) async {
    await _svc.scheduleDaily(
      id: 10,
      title: '📝 Log your work today',
      body: "Don't forget to track your time. Tap to open FreelanceHub.",
      hour:   settings.dailyReminderHour,    // user-configurable, default 19
      minute: settings.dailyReminderMinute,  // user-configurable, default 0
      channel: 'fh_reminders',
      channelName: 'Daily Reminders',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 2 — Weekly Revenue Digest (every Monday 9:00 AM)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleWeeklyDigest(List<Client> clients, AppSettings settings) async {
    final collected = clients
        .expand((c) => c.projects)
        .fold(0.0, (s, p) => s + p.upfront);
    final owed = clients
        .expand((c) => c.projects)
        .fold(0.0, (s, p) => s + p.remaining);
    final cur = settings.currency;

    await _svc.scheduleWeekly(
      id: 20,
      title: '📊 Weekly revenue update',
      body: 'Collected: ${fmtCurrency(collected, cur)} · Outstanding: ${fmtCurrency(owed, cur)}',
      weekday: DateTime.monday,
      hour: 9,
      minute: 0,
      channel: 'fh_financial',
      channelName: 'Financial',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 3 — Unlogged Timer Warning
  // Scheduled as a one-time +4h from now when a timer starts.
  // Called directly from TimerProvider.startTimer() — NOT from rescheduleAll().
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> scheduleTimerWarning(String projectName) async {
    final warnAt = DateTime.now().add(const Duration(hours: 4));
    await _svc.scheduleOnce(
      id: 11,
      title: '⏱ Timer still running',
      body: '"$projectName" timer has been running for 4 hours. Did you forget to stop it?',
      scheduledDate: warnAt,
      channel: 'fh_reminders',
      channelName: 'Daily Reminders',
    );
  }

  /// Cancel the timer warning — called when timer is stopped.
  Future<void> cancelTimerWarning() => _svc.cancel(11);

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS 4, 5, 6 — Deadline –7d / –1d / Day-of
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleDeadlineNotifications(
      Project p, int idx, AppSettings settings) async {
    final deadline = DateFormat('yyyy-MM-dd').parse(p.deadline);
    final now = DateTime.now();

    if (settings.notifyDeadline7Days) {
      final d = deadline.subtract(const Duration(days: 7));
      await _svc.scheduleOnce(
        id: 1000 + idx,
        title: '⏳ Deadline in 7 days',
        body: '"${p.name}" is due on ${DateFormat('MMM d').format(deadline)}. Stay on track!',
        scheduledDate: DateTime(d.year, d.month, d.day, 9, 0),
        channel: 'fh_deadlines',
        channelName: 'Deadlines',
      );
    }

    if (settings.notifyDeadline1Day) {
      final d = deadline.subtract(const Duration(days: 1));
      await _svc.scheduleOnce(
        id: 2000 + idx,
        title: '🚨 Deadline tomorrow',
        body: '"${p.name}" is due tomorrow. Final push!',
        scheduledDate: DateTime(d.year, d.month, d.day, 9, 0),
        channel: 'fh_deadlines',
        channelName: 'Deadlines',
      );
    }

    if (settings.notifyDeadlineDay) {
      await _svc.scheduleOnce(
        id: 3000 + idx,
        title: '📅 Due today',
        body: '"${p.name}" is due today. You\'ve got this!',
        scheduledDate: DateTime(deadline.year, deadline.month, deadline.day, 8, 0),
        channel: 'fh_deadlines',
        channelName: 'Deadlines',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 7 — Overdue Project Daily Alert
  // Fires every day at 9 AM for projects past their deadline still active.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleOverdueDaily(
      Project p, int idx, AppSettings settings) async {
    if (!settings.notifyOverdue) return;
    final days = daysLeft(p.deadline);
    if (days >= 0) return; // not overdue yet

    await _svc.scheduleDaily(
      id: 4000 + idx,
      title: '⚠ Project overdue',
      body: '"${p.name}" is ${days.abs()} day${days.abs() == 1 ? '' : 's'} overdue. Update the deadline or mark it complete.',
      hour: 9,
      minute: 0,
      channel: 'fh_deadlines',
      channelName: 'Deadlines',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 8 — Payment Complete (Immediate, event-based)
  // Called directly from DataProvider when project.remaining is set to 0.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> notifyPaymentComplete({
    required String projectName,
    required String clientName,
    required double amount,
    required String currency,
  }) async {
    await _svc.showImmediate(
      id: 5000,
      title: '💰 Payment received!',
      body: 'Full payment of ${fmtCurrency(amount, currency)} received for "$projectName" · $clientName',
      channel: 'fh_financial',
      channelName: 'Financial',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 9 — Outstanding Payments Weekly (every Monday 9 AM)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleOutstandingWeekly(
      List<Project> allProjects, AppSettings settings) async {
    final owing = allProjects.where((p) => p.remaining > 0).toList();
    if (owing.isEmpty) return;

    final total = owing.fold(0.0, (s, p) => s + p.remaining);
    final cur = settings.currency;

    await _svc.scheduleWeekly(
      id: 30,
      title: '💸 Outstanding payments',
      body: '${fmtCurrency(total, cur)} owed across ${owing.length} project${owing.length == 1 ? '' : 's'}. Time to follow up?',
      weekday: DateTime.monday,
      hour: 9,
      minute: 30,
      channel: 'fh_financial',
      channelName: 'Financial',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 10 — Maintenance Fee Monthly (1st of each month, 9 AM)
  // One notification per active maintenance project.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleMaintenanceReminders(
      List<Client> clients, AppSettings settings) async {
    var baseId = 50;
    for (final c in clients) {
      for (final p in c.projects) {
        if (!p.maintenanceActive || p.maintenanceFee <= 0) continue;
        final now = DateTime.now();
        // Schedule for the 1st of next month at 9:00 AM
        final nextFirst = now.day == 1
            ? DateTime(now.year, now.month, 1, 9, 0)
            : DateTime(now.year, now.month + 1, 1, 9, 0);

        await _svc.scheduleOnce(
          id: baseId++,
          title: '📋 Invoice reminder',
          body: 'Send monthly invoice to ${c.name} for "${p.name}" — ${fmtCurrency(p.maintenanceFee, settings.currency)}/mo',
          scheduledDate: nextFirst,
          channel: 'fh_financial',
          channelName: 'Financial',
        );
        if (baseId >= 100) break; // safety cap
      }
      if (baseId >= 100) break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 11 — No Income Mid-Month (15th of month, 10 AM)
  // Only fires if no upfront payment added this month.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleNoIncomeAlert(
      List<Project> allProjects, AppSettings settings) async {
    if (!settings.notifyNoIncome) return;
    final now = DateTime.now();
    // Don't schedule if already past the 15th
    if (now.day > 15) return;

    final alertDate = DateTime(now.year, now.month, 15, 10, 0);
    await _svc.scheduleOnce(
      id: 40,
      title: '📉 Halfway through the month',
      body: 'No new income recorded yet this month. How are things going?',
      scheduledDate: alertDate,
      channel: 'fh_financial',
      channelName: 'Financial',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 12 — New Project Idle Check (+3 days after creation)
  // Fires 3 days after project added if loggedHours == 0.
  // Called directly from DataProvider.addProject() — NOT from rescheduleAll().
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> scheduleNewProjectIdleCheck(Project p) async {
    final checkAt = DateTime.now().add(const Duration(days: 3));
    await _svc.scheduleOnce(
      id: 200 + stableIndex(p.id),
      title: '🚀 Ready to start?',
      body: 'No time logged on "${p.name}" yet. Tap to start your first session.',
      scheduledDate: DateTime(checkAt.year, checkAt.month, checkAt.day, 9, 0),
      channel: 'fh_activity',
      channelName: 'Project Activity',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 13 — Idle Project Weekly Warning
  // Every Monday for active projects with no sessions in the last 7 days.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleIdleProjectWarning(
      Project p, int idx, AppSettings settings) async {
    if (!settings.notifyIdleProject) return;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final hasRecentSession = p.sessions.any((s) {
      final date = DateFormat('yyyy-MM-dd').parse(s.date);
      return date.isAfter(sevenDaysAgo);
    });
    if (hasRecentSession) return; // don't nag if they're active

    await _svc.scheduleWeekly(
      id: 300 + idx,
      title: '😴 Project going quiet?',
      body: '"${p.name}" hasn\'t had any work logged in 7 days. Still on track?',
      weekday: DateTime.monday,
      hour: 10,
      minute: 0,
      channel: 'fh_activity',
      channelName: 'Project Activity',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 14 — Project Completion Celebration (Immediate, event-based)
  // Called directly from DataProvider.updateProjectStatus() when → 'completed'.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> notifyProjectComplete({
    required String projectName,
    required String clientName,
  }) async {
    await _svc.showImmediate(
      id: 5001,
      title: '🎉 Project delivered!',
      body: '"$projectName" for $clientName is complete. Great work!',
      channel: 'fh_activity',
      channelName: 'Project Activity',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 15 — Client Anniversary (Yearly on createdAt date)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleClientAnniversary(Client c, int idx) async {
    final created = DateFormat('yyyy-MM-dd').parse(c.createdAt);
    final now = DateTime.now();
    var anniversary = DateTime(now.year, created.month, created.day, 9, 0);
    if (anniversary.isBefore(now)) {
      anniversary = DateTime(now.year + 1, created.month, created.day, 9, 0);
    }
    final years = anniversary.year - created.year;
    await _svc.scheduleOnce(
      id: 100 + idx,
      title: '🎂 Client anniversary!',
      body: 'You\'ve been working with ${c.name} for $years year${years == 1 ? '' : 's'}. Thanks for the partnership!',
      scheduledDate: anniversary,
      channel: 'fh_activity',
      channelName: 'Project Activity',
    );
  }

  // ── STABLE INDEX HELPERS ──────────────────────────────────────────────────
  int stableIndex(String id) => id.hashCode.abs() % 900;
  int stableClientIndex(String id) => id.hashCode.abs() % 50;
}
```

---

## UPDATE `lib/models/app_settings.dart`

Replace all previous notification-related `@HiveField` entries (9–13) with the complete expanded set. **Existing fields 0–8 and 14 remain unchanged.**

```dart
// ── DAILY REMINDER ────────────────────────────────────────────────────────
@HiveField(9)  bool notificationsEnabled  = true;   // master toggle
@HiveField(10) bool notifyDailyLog        = true;   // #1 daily log reminder
@HiveField(11) int  dailyReminderHour     = 19;     // 7:00 PM default
@HiveField(12) int  dailyReminderMinute   = 0;

// ── DEADLINE ──────────────────────────────────────────────────────────────
@HiveField(13) bool notifyDeadline7Days   = true;   // #4
@HiveField(14) bool notifyDeadline1Day    = true;   // #5
@HiveField(15) bool notifyDeadlineDay     = true;   // #6
@HiveField(16) bool notifyOverdue         = true;   // #7

// ── FINANCIAL ─────────────────────────────────────────────────────────────
@HiveField(17) bool notifyWeeklyDigest       = true;  // #2
@HiveField(18) bool notifyOutstandingWeekly  = true;  // #9
@HiveField(19) bool notifyMaintenanceMonthly = true;  // #10
@HiveField(20) bool notifyNoIncome           = true;  // #11

// ── PROJECT ACTIVITY ──────────────────────────────────────────────────────
@HiveField(21) bool notifyNewProjectIdle    = true;  // #12
@HiveField(22) bool notifyIdleProject       = true;  // #13
@HiveField(23) bool notifyProjectComplete   = true;  // #14
@HiveField(24) bool notifyClientAnniversary = true;  // #15

// NOTE: lastExportDate is at @HiveField(25) — was previously 14, shift up
@HiveField(25) String? lastExportDate;
```

> **IMPORTANT:** `lastExportDate` was previously `@HiveField(14)`. It must be updated to `@HiveField(25)`. This is a breaking change — add a Hive migration guard in `main.dart`:
> ```dart
> // In main.dart before opening boxes:
> // If the old 'lastExportDate' key exists at field 14, migrate it to 25
> // In practice: clear the settings box on first run with new schema
> // by adding a new seed key 'schema_v2' check
> ```

---

## UPDATE `lib/providers/settings_provider.dart`

Add getters and update method for every new preference:

```dart
// ── GETTERS ───────────────────────────────────────────────────────────────
bool get notificationsEnabled     => _s.notificationsEnabled;
bool get notifyDailyLog           => _s.notifyDailyLog;
int  get dailyReminderHour        => _s.dailyReminderHour;
int  get dailyReminderMinute      => _s.dailyReminderMinute;
bool get notifyDeadline7Days      => _s.notifyDeadline7Days;
bool get notifyDeadline1Day       => _s.notifyDeadline1Day;
bool get notifyDeadlineDay        => _s.notifyDeadlineDay;
bool get notifyOverdue            => _s.notifyOverdue;
bool get notifyWeeklyDigest       => _s.notifyWeeklyDigest;
bool get notifyOutstandingWeekly  => _s.notifyOutstandingWeekly;
bool get notifyMaintenanceMonthly => _s.notifyMaintenanceMonthly;
bool get notifyNoIncome           => _s.notifyNoIncome;
bool get notifyNewProjectIdle     => _s.notifyNewProjectIdle;
bool get notifyIdleProject        => _s.notifyIdleProject;
bool get notifyProjectComplete    => _s.notifyProjectComplete;
bool get notifyClientAnniversary  => _s.notifyClientAnniversary;

// ── UNIFIED TOGGLE METHOD ─────────────────────────────────────────────────
/// Toggle any boolean notification preference by field name.
/// After saving, triggers NotificationScheduler.rescheduleAll() via callback.
Future<void> setNotifPref(String key, bool value) async {
  switch (key) {
    case 'enabled':               _s.notificationsEnabled     = value; break;
    case 'dailyLog':              _s.notifyDailyLog           = value; break;
    case 'deadline7':             _s.notifyDeadline7Days      = value; break;
    case 'deadline1':             _s.notifyDeadline1Day       = value; break;
    case 'deadlineDay':           _s.notifyDeadlineDay        = value; break;
    case 'overdue':               _s.notifyOverdue            = value; break;
    case 'weeklyDigest':          _s.notifyWeeklyDigest       = value; break;
    case 'outstandingWeekly':     _s.notifyOutstandingWeekly  = value; break;
    case 'maintenanceMonthly':    _s.notifyMaintenanceMonthly = value; break;
    case 'noIncome':              _s.notifyNoIncome           = value; break;
    case 'newProjectIdle':        _s.notifyNewProjectIdle     = value; break;
    case 'idleProject':           _s.notifyIdleProject        = value; break;
    case 'projectComplete':       _s.notifyProjectComplete    = value; break;
    case 'clientAnniversary':     _s.notifyClientAnniversary  = value; break;
  }
  await _s.save();
  notifyListeners();
  onNotifPrefChanged?.call(); // callback to trigger rescheduleAll
}

/// Set daily reminder time. Also triggers reschedule.
Future<void> setDailyReminderTime(int hour, int minute) async {
  _s.dailyReminderHour   = hour;
  _s.dailyReminderMinute = minute;
  await _s.save();
  notifyListeners();
  onNotifPrefChanged?.call();
}

/// Wire this callback in main.dart to call NotificationScheduler.rescheduleAll()
VoidCallback? onNotifPrefChanged;
```

---

## UPDATE `lib/providers/data_provider.dart`

Replace the `_syncNotifications()` method and add event-based triggers:

```dart
// ── RESCHEDULE ALL (called after any data mutation) ───────────────────────
Future<void> _syncNotifications() async {
  await NotificationScheduler().rescheduleAll(
    clients: _clients,
    settings: _settingsProvider.settings, // inject SettingsProvider in constructor
  );
}

// ── EVENT: project added ──────────────────────────────────────────────────
// In addProject(), after saving to Hive:
if (_settingsProvider.settings.notifyNewProjectIdle) {
  await NotificationScheduler().scheduleNewProjectIdleCheck(project);
}
await _syncNotifications();

// ── EVENT: project status changed to 'completed' ─────────────────────────
// In updateProjectStatus(), after saving, when newStatus == 'completed':
if (_settingsProvider.settings.notifyProjectComplete) {
  final client = findClient(clientId)!;
  await NotificationScheduler().notifyProjectComplete(
    projectName: project.name,
    clientName: client.name,
  );
}
await _syncNotifications();

// ── EVENT: remaining set to 0 (payment complete) ─────────────────────────
// Detect in updateProject() or a new updateProjectFinancials() method:
// When the old remaining > 0 and the new remaining == 0:
if (_settingsProvider.settings.notificationsEnabled) {
  final client = findClient(clientId)!;
  await NotificationScheduler().notifyPaymentComplete(
    projectName: project.name,
    clientName: client.name,
    amount: project.upfront + project.remaining, // total project value
    currency: _settingsProvider.settings.currency,
  );
}
await _syncNotifications();
```

> **Update DataProvider constructor** to accept both `NotificationService` and `SettingsProvider`:
> ```dart
> DataProvider(this._settingsProvider);
> ```
> `NotificationScheduler` is a singleton accessed directly — no need to inject it.

---

## UPDATE `lib/providers/timer_provider.dart`

Wire the timer warning notification into `startTimer()` and `stopTimer()`:

```dart
// In startTimer():
await NotificationScheduler().scheduleTimerWarning(projectName);

// In stopTimer() / discardTimer():
await NotificationScheduler().cancelTimerWarning();
```

---

## FULL REPLACEMENT: `lib/screens/notification_settings_screen.dart`

Replace the existing basic version with a comprehensive settings screen organized into 4 sections.

### Layout

```
AppBar: "Notifications"

Body: SingleChildScrollView, BouncingScrollPhysics
  │
  ├── [Master toggle card]           ← full-width card, prominent
  │
  ├── SectionLabel("DAILY & PERIODIC")
  │   ├── SwitchListTile: Daily work log reminder
  │   │     └── [Time picker row — only visible when toggle is ON]
  │   └── SwitchListTile: Weekly revenue digest (Mondays)
  │
  ├── SectionLabel("DEADLINES")
  │   ├── SwitchListTile: 7 days before deadline
  │   ├── SwitchListTile: 1 day before deadline
  │   ├── SwitchListTile: On deadline day
  │   └── SwitchListTile: Overdue project daily alert
  │
  ├── SectionLabel("FINANCIAL")
  │   ├── SwitchListTile: Outstanding payments (weekly)
  │   ├── SwitchListTile: Monthly maintenance invoice reminder
  │   └── SwitchListTile: No income mid-month alert
  │
  └── SectionLabel("PROJECT & CLIENT ACTIVITY")
      ├── SwitchListTile: New project idle check (3 days)
      ├── SwitchListTile: Idle project warning (weekly)
      ├── SwitchListTile: Project completion celebration
      └── SwitchListTile: Client anniversary
```

### Master Toggle Card

Prominent card at the top. When toggled OFF, all other toggles visually dim (wrap the rest of the body in `IgnorePointer(ignoring: !notifEnabled)` + `AnimatedOpacity(opacity: notifEnabled ? 1.0 : 0.4)`).

```dart
Container(
  margin: EdgeInsets.fromLTRB(20, 16, 20, 8),
  decoration: kCardDecoration(
    borderColor: settings.notificationsEnabled ? kLime.withOpacity(0.4) : kBorder,
    background: settings.notificationsEnabled ? kLime.withOpacity(0.06) : kBgCard,
  ),
  padding: EdgeInsets.all(20),
  child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('All Notifications', style: kStyleBodyBold),
      SizedBox(height: 2),
      Text('Master switch for all FreelanceHub alerts', style: kStyleBody),
    ])),
    Switch(
      value: settings.notificationsEnabled,
      onChanged: (v) => sp.setNotifPref('enabled', v),
      activeColor: kBlack,
      activeTrackColor: kLime,
    ),
  ]),
)
```

### Daily Reminder Time Picker Row

Below the "Daily work log reminder" `SwitchListTile`, show a time picker row when the toggle is ON:

```dart
if (settings.notifyDailyLog)
  Padding(
    padding: EdgeInsets.fromLTRB(72, 0, 20, 8),
    child: Row(children: [
      Text('Reminder time:', style: kStyleBody),
      Spacer(),
      GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: settings.dailyReminderHour,
              minute: settings.dailyReminderMinute,
            ),
          );
          if (picked != null) {
            await sp.setDailyReminderTime(picked.hour, picked.minute);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: kCardDecoration(radius: 10, hasShadow: false),
          child: Text(
            TimeOfDay(hour: settings.dailyReminderHour, minute: settings.dailyReminderMinute)
                .format(context),
            style: kStyleBodyBold,
          ),
        ),
      ),
    ]),
  ),
```

### `_NotifTile` helper widget (private, inside this file)

```dart
// Reduce boilerplate — all 14 individual toggles use this
class _NotifTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(title, style: kStyleBodyBold),
    subtitle: Text(subtitle, style: kStyleBody),
    value: value,
    onChanged: onChanged,
    activeColor: kBlack,
    activeTrackColor: kLime,
    contentPadding: EdgeInsets.symmetric(horizontal: 20),
  );
}
```

---

## FILES TO CREATE OR MODIFY (THIS FEATURE ONLY)

| File | Action |
|---|---|
| `lib/services/notification_service.dart` | **Full replacement** |
| `lib/services/notification_scheduler.dart` | **Create new** |
| `lib/models/app_settings.dart` | Modify — replace fields 9–14 with fields 9–25 |
| `lib/providers/settings_provider.dart` | Modify — add all getters + `setNotifPref` + `onNotifPrefChanged` |
| `lib/providers/data_provider.dart` | Modify — replace `_syncNotifications`, add 3 event triggers |
| `lib/providers/timer_provider.dart` | Modify — add `scheduleTimerWarning` / `cancelTimerWarning` calls |
| `lib/screens/notification_settings_screen.dart` | **Full replacement** |

---

## FINAL CHECKLIST

- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs` after updating `AppSettings` fields
- [ ] `NotificationService` and `NotificationScheduler` are both singletons — `factory` constructors returning `_i`
- [ ] `NotificationService.init()` guards against double-init with `if (_initialized) return`
- [ ] 4 Android channels created during `init()` — `fh_deadlines`, `fh_financial`, `fh_activity`, `fh_reminders`
- [ ] `scheduleDaily()` uses `matchDateTimeComponents: DateTimeComponents.time` for true repeat
- [ ] `scheduleWeekly()` uses `matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime`
- [ ] `scheduleOnce()` silently returns if `scheduledDate` is in the past — no error thrown
- [ ] `rescheduleAll()` starts with `cancelAll()` — always rebuilds from clean state
- [ ] `rescheduleAll()` returns early (after `cancelAll()`) when `notificationsEnabled == false`
- [ ] Notification ID ranges never overlap — see reservation table at top of this prompt
- [ ] `stableIndex()` and `stableClientIndex()` used for all per-project / per-client IDs
- [ ] Timer warning (ID 11) is scheduled in `TimerProvider.startTimer()`, cancelled in `stopTimer()` and `discardTimer()`
- [ ] New project idle check (ID 200+) is scheduled in `DataProvider.addProject()` directly — not via `rescheduleAll()`
- [ ] Payment complete notification (ID 5000) fires immediately when `project.remaining` transitions from `> 0` to `== 0`
- [ ] Project completion notification (ID 5001) fires immediately when status set to `'completed'`
- [ ] `_scheduleIdleProjectWarning()` checks for recent sessions before scheduling — no notification if session in last 7 days
- [ ] `_scheduleNoIncomeAlert()` returns early if `now.day > 15` — no retroactive scheduling
- [ ] `_scheduleMaintenanceReminders()` caps at 50 clients (ID range 50–99)
- [ ] `SettingsProvider.onNotifPrefChanged` callback wired in `main.dart` to trigger `rescheduleAll()`
- [ ] Master toggle in notification settings screen dims all other tiles with `AnimatedOpacity(0.4)` + `IgnorePointer` when off
- [ ] Daily reminder time picker uses `showTimePicker` and saves via `setDailyReminderTime()`
- [ ] `_NotifTile` widget uses `kLime` as `activeTrackColor` and `kBlack` as `activeColor`
- [ ] All 15 notification use cases have individual toggles in the settings screen
- [ ] `lastExportDate` field moved from `@HiveField(14)` to `@HiveField(25)` — schema migration documented
