import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/client.dart';
import '../models/project.dart';
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
    // Cancel all existing notifications first
    await _svc.cancelAll();

    // If master toggle is off, stop here (all notifications cancelled)
    if (!settings.notificationsEnabled) {
      return;
    }

    // Collect all projects
    final allProjects = <Project>[];
    for (final client in clients) {
      allProjects.addAll(client.projects);
    }

    // Schedule periodic notifications
    if (settings.notifyDailyLog) {
      await _scheduleDailyLogReminder(settings, allProjects);
    }

    if (settings.notifyWeeklyDigest) {
      await _scheduleWeeklyDigest(clients, settings);
    }

    if (settings.notifyOutstandingWeekly) {
      await _scheduleOutstandingPaymentsWeekly(clients, settings);
    }

    if (settings.notifyMaintenanceMonthly) {
      await _scheduleMaintenanceReminders(clients, settings);
    }

    // Schedule per-project notifications
    var projectIdx = 0;
    for (final project in allProjects) {
      // Only for active projects
      if (project.status == 'active') {
        await _scheduleDeadlineNotifications(project, projectIdx, settings);
        if (daysLeft(project.deadline) < 0) {
          // Overdue
          await _scheduleOverdueDaily(project, projectIdx, settings);
        }
      }

      // New project idle check
      if (settings.notifyNewProjectIdle && project.sessions.isEmpty) {
        await _scheduleNewProjectIdleCheck(project, projectIdx, settings);
      }

      // Idle project weekly check
      if (settings.notifyIdleProject) {
        final hasRecentSession = project.sessions.any((s) {
          final sessionDate = DateFormat('yyyy-MM-dd').parse(s.date);
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          return sessionDate.isAfter(sevenDaysAgo);
        });
        if (!hasRecentSession) {
          await _scheduleIdleProjectWarning(project, projectIdx);
        }
      }

      projectIdx++;
    }

    // No income mid-month alert
    if (settings.notifyNoIncome &&
        DateTime.now().day > 7 &&
        DateTime.now().day <= 15) {
      final totalCollected = clients.fold<double>(
        0,
        (sum, c) =>
            sum +
            c.projects.fold<double>(
              0,
              (ps, p) => ps + p.upfront,
            ),
      );

      if (totalCollected == 0) {
        await _scheduleNoIncomeAlert(settings);
      }
    }

    // Client anniversaries
    if (settings.notifyClientAnniversary) {
      var clientIdx = 0;
      for (final client in clients) {
        await _scheduleClientAnniversary(client, clientIdx);
        clientIdx++;
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 1 — Daily Work Log Reminder
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleDailyLogReminder(
      AppSettings settings, List<Project> allProjects) async {
    await _svc.scheduleDaily(
      id: 10,
      title: 'Did you log your work today?',
      body: 'Quick reminder to log any sessions from today.',
      hour: settings.dailyReminderHour,
      minute: settings.dailyReminderMinute,
      channel: 'fh_reminders',
      channelName: 'Daily & Periodic Reminders',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 2 — Weekly Revenue Digest (every Monday 9:00 AM)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleWeeklyDigest(
      List<Client> clients, AppSettings settings) async {
    final collected = clients
        .fold<double>(
          0,
          (sum, c) =>
              sum +
              c.projects.fold<double>(
                0,
                (ps, p) => ps + p.upfront,
              ),
        )
        .toStringAsFixed(2);

    final owed = clients
        .fold<double>(
          0,
          (sum, c) =>
              sum +
              c.projects.fold<double>(
                0,
                (ps, p) => ps + p.remaining,
              ),
        )
        .toStringAsFixed(2);

    await _svc.scheduleWeekly(
      id: 20,
      title: 'Weekly Revenue Summary',
      body: 'Collected: $collected | Outstanding: $owed',
      weekday: 1, // Monday
      hour: 9,
      minute: 0,
      channel: 'fh_financial',
      channelName: 'Financial & Payments',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 3 — Unlogged Timer Warning
  // Scheduled as a one-time +4h from now when a timer starts.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> scheduleTimerWarning(String projectName) async {
    final warnAt = DateTime.now().add(const Duration(hours: 4));
    await _svc.scheduleOnce(
      id: 11,
      title: 'Timer still running',
      body: '$projectName timer has been running for 4 hours',
      scheduledDate: warnAt,
      channel: 'fh_reminders',
      channelName: 'Daily & Periodic Reminders',
    );
  }

  /// Cancel the timer warning — called when timer is stopped.
  Future<void> cancelTimerWarning() => _svc.cancel(11);

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS 4, 5, 6 — Deadline –7d / –1d / Day-of
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleDeadlineNotifications(
      Project p, int idx, AppSettings settings) async {
    final idxOffset = stableIndex(p.id);

    final deadline = DateFormat('yyyy-MM-dd').parse(p.deadline);
    final now = DateTime.now();

    // 7-day warning
    if (settings.notifyDeadline7Days) {
      final sevenDayWarning = deadline.subtract(const Duration(days: 7));
      if (sevenDayWarning.isAfter(now)) {
        await _svc.scheduleOnce(
          id: 1000 + idxOffset,
          title: 'Deadline in 7 days',
          body: '"${p.name}" is due in 7 days. Stay on track!',
          scheduledDate: DateTime(sevenDayWarning.year, sevenDayWarning.month,
              sevenDayWarning.day, 9, 0),
          channel: 'fh_deadlines',
          channelName: 'Deadlines',
        );
      }
    }

    // 1-day warning
    if (settings.notifyDeadline1Day) {
      final oneDayWarning = deadline.subtract(const Duration(days: 1));
      if (oneDayWarning.isAfter(now)) {
        await _svc.scheduleOnce(
          id: 2000 + idxOffset,
          title: 'Deadline tomorrow',
          body: '"${p.name}" is due tomorrow at EOD.',
          scheduledDate: DateTime(oneDayWarning.year, oneDayWarning.month,
              oneDayWarning.day, 14, 0),
          channel: 'fh_deadlines',
          channelName: 'Deadlines',
        );
      }
    }

    // Deadline day morning
    if (settings.notifyDeadlineDay) {
      if (deadline.isAfter(now)) {
        await _svc.scheduleOnce(
          id: 3000 + idxOffset,
          title: 'Deadline TODAY',
          body: '"${p.name}" must be completed by end of day.',
          scheduledDate:
              DateTime(deadline.year, deadline.month, deadline.day, 8, 0),
          channel: 'fh_deadlines',
          channelName: 'Deadlines',
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 7 — Overdue Project Daily Alert
  // Fires every day at 9 AM for projects past their deadline still active.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleOverdueDaily(
      Project p, int idx, AppSettings settings) async {
    final idxOffset = stableIndex(p.id);
    if (settings.notifyOverdue) {
      await _svc.scheduleDaily(
        id: 4000 + idxOffset,
        title: 'Project OVERDUE',
        body: '"${p.name}" is ${daysLeft(p.deadline).abs()} days overdue.',
        hour: 9,
        minute: 0,
        channel: 'fh_deadlines',
        channelName: 'Deadlines',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 8 — Payment Complete (Immediate, event-based)
  // Called directly when project.remaining becomes 0.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> notifyPaymentComplete({
    required String projectName,
    required String clientName,
    required String amount,
    required String currency,
  }) async {
    await _svc.showImmediate(
      id: 5000,
      title: '✓ Payment Received',
      body: '$clientName paid for $projectName ($amount)',
      channel: 'fh_financial',
      channelName: 'Financial & Payments',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 9 — Outstanding Payments Weekly (Wednesday 10:00 AM)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleOutstandingPaymentsWeekly(
      List<Client> clients, AppSettings settings) async {
    final outstanding = clients
        .fold<double>(
          0,
          (sum, c) =>
              sum +
              c.projects.fold<double>(
                0,
                (ps, p) => ps + p.remaining,
              ),
        )
        .toStringAsFixed(2);

    await _svc.scheduleWeekly(
      id: 30,
      title: 'Outstanding payments',
      body: 'You have $outstanding waiting to be collected.',
      weekday: 3, // Wednesday
      hour: 10,
      minute: 0,
      channel: 'fh_financial',
      channelName: 'Financial & Payments',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 10 — Maintenance Reminders (monthly on 1st at 9 AM)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleMaintenanceReminders(
      List<Client> clients, AppSettings settings) async {
    var clientIdx = 0;
    for (final client in clients) {
      if (clientIdx >= 50) break; // Cap at 50 clients
      final maintenanceProjects = client.projects
          .where((p) => p.maintenanceActive && p.status == 'completed')
          .toList();
      if (maintenanceProjects.isNotEmpty) {
        final totalMrr = maintenanceProjects.fold<double>(
          0,
          (sum, p) => sum + p.maintenanceFee,
        );
        await _svc.scheduleWeekly(
          id: 50 + clientIdx,
          title: 'Maintenance fee due',
          body: '${client.name}: ${fmtCurrency(totalMrr, 'TND')}/mo',
          weekday: 1, // Monday
          hour: 9,
          minute: 0,
          channel: 'fh_financial',
          channelName: 'Financial & Payments',
        );
      }
      clientIdx++;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 11 — No Income Mid-Month Alert
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleNoIncomeAlert(AppSettings settings) async {
    // Only on days 8-15 of the month
    if (DateTime.now().day <= 7 || DateTime.now().day > 15) {
      return;
    }
    await _svc.showImmediate(
      id: 40,
      title: 'No income this month yet',
      body: 'Mid-month check: add a client or project to get started.',
      channel: 'fh_financial',
      channelName: 'Financial & Payments',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 12 — New Project Idle Check (7 days after creation)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleNewProjectIdleCheck(
      Project p, int idx, AppSettings settings) async {
    final idxOffset = stableIndex(p.id);
    final checkAt = DateTime.now().add(const Duration(days: 7));
    await _svc.scheduleOnce(
      id: 200 + idxOffset,
      title: 'No progress on ${p.name}?',
      body: 'Start logging time when you begin work.',
      scheduledDate: checkAt,
      channel: 'fh_activity',
      channelName: 'Project Activity',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 13 — Idle Project Weekly Warning
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleIdleProjectWarning(Project p, int idx) async {
    final idxOffset = stableIndex(p.id);
    await _svc.scheduleWeekly(
      id: 300 + idxOffset,
      title: '${p.name} has been idle',
      body: 'No sessions logged in the last 7 days.',
      weekday: 5, // Thursday
      hour: 10,
      minute: 0,
      channel: 'fh_activity',
      channelName: 'Project Activity',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 14 — Project Completion Celebration (Immediate, event-based)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> notifyProjectComplete({
    required String projectName,
    required String clientName,
  }) async {
    await _svc.showImmediate(
      id: 5001,
      title: '🎉 Project Complete',
      body: '$projectName for $clientName is marked done!',
      channel: 'fh_activity',
      channelName: 'Project Activity',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTIFICATION 15 — Client Anniversary (yearly on signup anniversary)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _scheduleClientAnniversary(Client c, int idx) async {
    try {
      final createdDate = DateFormat('yyyy-MM-dd').parse(c.createdAt);
      final nextAnniversary =
          DateTime(DateTime.now().year, createdDate.month, createdDate.day);
      if (nextAnniversary.isBefore(DateTime.now())) {
        // Anniversary already passed this year, schedule for next year
        // (we don't schedule — skip it)
        return;
      }
      await _svc.scheduleOnce(
        id: 100 + idx,
        title: 'Happy ${c.name} anniversary! 🎂',
        body: 'You\'ve been working together for 1 year!',
        scheduledDate: nextAnniversary,
        channel: 'fh_activity',
        channelName: 'Project Activity',
      );
    } catch (_) {
      // Date parsing failed, skip
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Stable index from ID hash
  // ─────────────────────────────────────────────────────────────────────────
  static int stableIndex(String id) => id.hashCode.abs() % 900;
}
