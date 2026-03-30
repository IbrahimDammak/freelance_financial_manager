import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/app_settings.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._settingsBox) {
    _settings = _settingsBox.get('app') as AppSettings? ?? AppSettings();
    _settingsBox.put('app', _settings);
    _sanitizeDashboardSections();
  }

  final Box _settingsBox;
  late AppSettings _settings;

  /// Wire this callback in main.dart to trigger NotificationScheduler.rescheduleAll()
  VoidCallback? onNotifPrefChanged;

  AppSettings get settings => _settings;
  String get userName => _settings.userName;
  bool get onboardingDone => _settings.onboardingDone;
  List<String> get serviceCategories =>
      List.unmodifiable(_settings.serviceCategories);

  List<String> get dashboardSections =>
      List.unmodifiable(_settings.dashboardSections);

  bool isSectionEnabled(String sectionId) {
    return _settings.dashboardSections.contains(sectionId);
  }

  DateTime? get lastExportDate {
    final raw = _settings.lastExportDate;
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  // ── NOTIFICATION PREFERENCE GETTERS ───────────────────────────────────────
  bool get notificationsEnabled => _settings.notificationsEnabled;
  bool get notifyDailyLog => _settings.notifyDailyLog;
  int get dailyReminderHour => _settings.dailyReminderHour;
  int get dailyReminderMinute => _settings.dailyReminderMinute;
  bool get notifyDeadline7Days => _settings.notifyDeadline7Days;
  bool get notifyDeadline1Day => _settings.notifyDeadline1Day;
  bool get notifyDeadlineDay => _settings.notifyDeadlineDay;
  bool get notifyOverdue => _settings.notifyOverdue;
  bool get notifyWeeklyDigest => _settings.notifyWeeklyDigest;
  bool get notifyOutstandingWeekly => _settings.notifyOutstandingWeekly;
  bool get notifyMaintenanceMonthly => _settings.notifyMaintenanceMonthly;
  bool get notifyNoIncome => _settings.notifyNoIncome;
  bool get notifyNewProjectIdle => _settings.notifyNewProjectIdle;
  bool get notifyIdleProject => _settings.notifyIdleProject;
  bool get notifyProjectComplete => _settings.notifyProjectComplete;
  bool get notifyClientAnniversary => _settings.notifyClientAnniversary;

  Future<void> updateHourlyRate(double rate) async {
    if (rate.isNaN || rate.isInfinite || rate < 0) return;
    _settings.hourlyRate = rate;
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    if (!AppSettings.supportedCurrencies.contains(currency)) return;
    _settings.currency = currency;
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }

  Future<void> updateUserName(String name) async {
    _settings.userName = name;
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _settings.onboardingDone = true;
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }

  Future<void> toggleSection(String sectionId) async {
    final sections = List<String>.from(_settings.dashboardSections);
    if (sections.contains(sectionId)) {
      if (sections.length == 1) return;
      sections.remove(sectionId);
    } else {
      sections.add(sectionId);
    }
    _settings.dashboardSections = sections;
    _applySectionBools(sections);
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }

  Future<void> reorderSections(List<String> newOrder) async {
    if (newOrder.isEmpty) return;
    _settings.dashboardSections = List<String>.from(newOrder);
    _applySectionBools(_settings.dashboardSections);
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }

  // ── UNIFIED NOTIFICATION PREFERENCE TOGGLE ────────────────────────────────
  /// Toggle any boolean notification preference by field name.
  /// After saving, triggers onNotifPrefChanged callback.
  Future<void> setNotifPref(String key, bool value) async {
    switch (key) {
      case 'all':
        _settings.notificationsEnabled = value;
        break;
      case 'dailyLog':
        _settings.notifyDailyLog = value;
        break;
      case '7days':
        _settings.notifyDeadline7Days = value;
        break;
      case '1day':
        _settings.notifyDeadline1Day = value;
        break;
      case 'day':
        _settings.notifyDeadlineDay = value;
        break;
      case 'overdue':
        _settings.notifyOverdue = value;
        break;
      case 'digest':
        _settings.notifyWeeklyDigest = value;
        break;
      case 'outstanding':
        _settings.notifyOutstandingWeekly = value;
        break;
      case 'maintenance':
        _settings.notifyMaintenanceMonthly = value;
        break;
      case 'noIncome':
        _settings.notifyNoIncome = value;
        break;
      case 'newProjectIdle':
        _settings.notifyNewProjectIdle = value;
        break;
      case 'idleProject':
        _settings.notifyIdleProject = value;
        break;
      case 'projectComplete':
        _settings.notifyProjectComplete = value;
        break;
      case 'clientAnniversary':
        _settings.notifyClientAnniversary = value;
        break;
      default:
        return;
    }
    await _settingsBox.put('app', _settings);
    notifyListeners();
    onNotifPrefChanged?.call(); // Trigger reschedule
  }

  /// Set daily reminder time. Also triggers reschedule.
  Future<void> setDailyReminderTime(int hour, int minute) async {
    _settings.dailyReminderHour = hour;
    _settings.dailyReminderMinute = minute;
    await _settingsBox.put('app', _settings);
    notifyListeners();
    onNotifPrefChanged?.call(); // Trigger reschedule
  }

  // ── BACKWARDS COMPATIBILITY ───────────────────────────────────────────────
  /// Legacy method for old code paths
  Future<void> updateNotificationPref(String key, bool value) async {
    await setNotifPref(key, value);
  }

  Future<void> updateLastExportDate(DateTime date) async {
    _settings.lastExportDate = date.toIso8601String();
    await _settingsBox.put('app', _settings);
    notifyListeners();
  }

  Future<void> addServiceCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final existing =
        _settings.serviceCategories.map((s) => s.toLowerCase()).toList();
    if (existing.contains(trimmed.toLowerCase())) return;
    _settings.serviceCategories = [..._settings.serviceCategories, trimmed];
    await _settings.save();
    notifyListeners();
  }

  Future<void> removeServiceCategory(String name) async {
    if (_settings.serviceCategories.length <= 1) return;
    _settings.serviceCategories =
        _settings.serviceCategories.where((s) => s != name).toList();
    await _settings.save();
    notifyListeners();
  }

  Future<void> renameServiceCategory(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    _settings.serviceCategories = _settings.serviceCategories
        .map((s) => s == oldName ? trimmed : s)
        .toList();
    await _settings.save();
    notifyListeners();
  }

  Future<void> reorderServiceCategories(List<String> categories) async {
    if (categories.isEmpty) return;
    _settings.serviceCategories = List<String>.from(categories);
    await _settings.save();
    notifyListeners();
  }

  void _sanitizeDashboardSections() {
    if (_settings.dashboardSections.isEmpty) {
      _settings.dashboardSections = [
        'active_projects',
        'client_strip',
        'owed_timer',
        'mrr_collected',
      ];
      _settingsBox.put('app', _settings);
    }
    _applySectionBools(_settings.dashboardSections);
  }

  void _applySectionBools(List<String> sections) {
    _settings.showActiveProjects = sections.contains('active_projects');
    _settings.showClientStrip = sections.contains('client_strip');
    _settings.showOwedTimer = sections.contains('owed_timer');
    _settings.showMrrCollected = sections.contains('mrr_collected');
  }
}

