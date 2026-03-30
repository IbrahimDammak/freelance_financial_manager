import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      backgroundColor: kBg,
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          final settings = settingsProvider.settings;
          final notifEnabled = settings.notificationsEnabled;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ──────────────────────────────────────────────────────────────
                // MASTER TOGGLE CARD
                // ──────────────────────────────────────────────────────────────
                Container(
                  decoration: kCardDecoration(),
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Enable all notifications', style: kStyleBodyBold),
                            const SizedBox(height: 4),
                            Text(
                              'Master toggle - turns off all reminders',
                              style: kStyleCaption,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        activeColor: kLime,
                        activeTrackColor: kLime.withOpacity(0.3),
                        value: notifEnabled,
                        onChanged: (v) =>
                            settingsProvider.setNotifPref('all', v),
                      ),
                    ],
                  ),
                ),

                // When master is OFF, dim everything else
                AnimatedOpacity(
                  opacity: notifEnabled ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !notifEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─────────────────────────────────────────────────────
                        // DAILY REMINDERS SECTION
                        // ─────────────────────────────────────────────────────
                        const SizedBox(height: 8),
                        Text(
                          'DAILY REMINDERS',
                          style: kStyleLabel,
                        ),
                        const SizedBox(height: 8),

                        Container(
                          decoration: kCardDecoration(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              _NotifTile(
                                title: 'Daily work log reminder',
                                subtitle: 'Nudge to log your day\'s sessions',
                                value: settings.notifyDailyLog,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref('dailyLog', v),
                              ),
                              if (settings.notifyDailyLog)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Remind me at',
                                          style: kStyleBody,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showTimePicker(
                                          context,
                                          settings.dailyReminderHour,
                                          settings.dailyReminderMinute,
                                          settingsProvider,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: kBgCardAlt,
                                            border:
                                                Border.all(color: kBorder),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            '${settings.dailyReminderHour.toString().padLeft(2, '0')}:${settings.dailyReminderMinute.toString().padLeft(2, '0')}',
                                            style: kStyleBodyBold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ─────────────────────────────────────────────────────
                        // DEADLINE SECTION
                        // ─────────────────────────────────────────────────────
                        const SizedBox(height: 8),
                        Text(
                          'PROJECT DEADLINES',
                          style: kStyleLabel,
                        ),
                        const SizedBox(height: 8),

                        Container(
                          decoration: kCardDecoration(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              _NotifTile(
                                title: '7 days before deadline',
                                subtitle: 'Get reminded a week in advance',
                                value: settings.notifyDeadline7Days,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref('7days', v),
                              ),
                              _NotifTile(
                                title: '1 day before deadline',
                                subtitle: 'Final day alert',
                                value: settings.notifyDeadline1Day,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref('1day', v),
                              ),
                              _NotifTile(
                                title: 'Deadline day morning',
                                subtitle: 'Due today reminder',
                                value: settings.notifyDeadlineDay,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref('day', v),
                              ),
                              _NotifTile(
                                title: 'Overdue daily alert',
                                subtitle: 'Daily notification for past due',
                                value: settings.notifyOverdue,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref('overdue', v),
                              ),
                            ],
                          ),
                        ),

                        // ─────────────────────────────────────────────────────
                        // FINANCIAL SECTION
                        // ─────────────────────────────────────────────────────
                        const SizedBox(height: 8),
                        Text(
                          'FINANCIAL',
                          style: kStyleLabel,
                        ),
                        const SizedBox(height: 8),

                        Container(
                          decoration: kCardDecoration(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            children: [
                              _NotifTile(
                                title: 'Weekly revenue digest',
                                subtitle: 'Monday morning summary',
                                value: settings.notifyWeeklyDigest,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref('digest', v),
                              ),
                              _NotifTile(
                                title: 'Outstanding payments',
                                subtitle: 'Weekly Wednesday reminder',
                                value: settings.notifyOutstandingWeekly,
                                onChanged: (v) => settingsProvider
                                    .setNotifPref('outstanding', v),
                              ),
                              _NotifTile(
                                title: 'Maintenance fee reminders',
                                subtitle: 'Monthly recurring fees',
                                value: settings.notifyMaintenanceMonthly,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref(
                                      'maintenance',
                                      v,
                                    ),
                              ),
                              _NotifTile(
                                title: 'No income mid-month alert',
                                subtitle: 'Check-in if slow on cash',
                                value: settings.notifyNoIncome,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref('noIncome', v),
                              ),
                            ],
                          ),
                        ),

                        // ─────────────────────────────────────────────────────
                        // PROJECT ACTIVITY SECTION
                        // ─────────────────────────────────────────────────────
                        const SizedBox(height: 8),
                        Text(
                          'PROJECT ACTIVITY',
                          style: kStyleLabel,
                        ),
                        const SizedBox(height: 8),

                        Container(
                          decoration: kCardDecoration(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            children: [
                              _NotifTile(
                                title: 'New project idle check',
                                subtitle: 'Remind if no progress in 7 days',
                                value: settings.notifyNewProjectIdle,
                                onChanged: (v) => settingsProvider
                                    .setNotifPref('newProjectIdle', v),
                              ),
                              _NotifTile(
                                title: 'Idle project weekly',
                                subtitle: 'Thursday reminder for stalled work',
                                value: settings.notifyIdleProject,
                                onChanged: (v) =>
                                    settingsProvider.setNotifPref(
                                      'idleProject',
                                      v,
                                    ),
                              ),
                              _NotifTile(
                                title: 'Project completion',
                                subtitle: 'Celebration when projects finish',
                                value: settings.notifyProjectComplete,
                                onChanged: (v) => settingsProvider
                                    .setNotifPref('projectComplete', v),
                              ),
                              _NotifTile(
                                title: 'Client anniversary',
                                subtitle: 'Yearly working relationship milestone',
                                value: settings.notifyClientAnniversary,
                                onChanged: (v) => settingsProvider
                                    .setNotifPref('clientAnniversary', v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    int hour,
    int minute,
    SettingsProvider sp,
  ) async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (result != null) {
      await sp.setDailyReminderTime(result.hour, result.minute);
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// HELPER: _NotifTile
// ────────────────────────────────────────────────────────────────────────────
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kStyleBodyBold),
                const SizedBox(height: 2),
                Text(subtitle, style: kStyleCaption),
              ],
            ),
          ),
          Switch(
            activeColor: kLime,
            activeTrackColor: kLime.withOpacity(0.3),
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

