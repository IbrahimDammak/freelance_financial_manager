import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 0)
class AppSettings extends HiveObject {
  @HiveField(0)
  double hourlyRate = 50.0;

  @HiveField(1)
  String currency = 'TND';

  @HiveField(2)
  String userName = '';

  @HiveField(3)
  bool onboardingDone = false;

  @HiveField(4)
  List<String> dashboardSections = const [
    'active_projects',
    'client_strip',
    'owed_timer',
    'mrr_collected',
  ];

  @HiveField(5)
  bool showActiveProjects = true;

  @HiveField(6)
  bool showClientStrip = true;

  @HiveField(7)
  bool showOwedTimer = true;

  @HiveField(8)
  bool showMrrCollected = true;

  // ── DAILY REMINDER ────────────────────────────────────────────────────────
  @HiveField(9)
  bool notificationsEnabled = true;

  @HiveField(10)
  bool notifyDailyLog = true;

  @HiveField(11)
  int dailyReminderHour = 19;

  @HiveField(12)
  int dailyReminderMinute = 0;

  // ── DEADLINE ──────────────────────────────────────────────────────────────
  @HiveField(13)
  bool notifyDeadline7Days = true;

  @HiveField(14)
  bool notifyDeadline1Day = true;

  @HiveField(15)
  bool notifyDeadlineDay = true;

  @HiveField(16)
  bool notifyOverdue = true;

  // ── FINANCIAL ─────────────────────────────────────────────────────────────
  @HiveField(17)
  bool notifyWeeklyDigest = true;

  @HiveField(18)
  bool notifyOutstandingWeekly = true;

  @HiveField(19)
  bool notifyMaintenanceMonthly = true;

  @HiveField(20)
  bool notifyNoIncome = true;

  // ── PROJECT ACTIVITY ──────────────────────────────────────────────────────
  @HiveField(21)
  bool notifyNewProjectIdle = true;

  @HiveField(22)
  bool notifyIdleProject = true;

  @HiveField(23)
  bool notifyProjectComplete = true;

  @HiveField(24)
  bool notifyClientAnniversary = true;

  @HiveField(25)
  String? lastExportDate;

  @HiveField(26)
  List<String> serviceCategories = const [
    'Web Development',
    'Graphic Design',
    'UI/UX Design',
    'Mobile App',
    'SEO',
    'Branding',
    'Copywriting',
    'Video Editing',
  ];

  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'NGN',
    'TND',
    'CAD'
  ];
}
