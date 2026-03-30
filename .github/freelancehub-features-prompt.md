# FEATURE UPDATE — FreelanceHub
## Onboarding · Dashboard Customization · Push Notifications

## SCOPE
This update adds three new features to the existing app. Files to create or modify are listed per feature. All other files remain unchanged unless explicitly mentioned.

---

# FEATURE 1 — ONBOARDING SCREEN & PERSONALIZED GREETING

## 1A. Update `lib/models/app_settings.dart`

Add the following new `@HiveField` entries. **Do not change existing field indices (0, 1). Only append.**

```dart
@HiveType(typeId: 0)
class AppSettings extends HiveObject {
  @HiveField(0) double hourlyRate    = 50.0;
  @HiveField(1) String currency      = 'TND';
  @HiveField(2) String userName      = '';       // set during onboarding
  @HiveField(3) bool   onboardingDone = false;   // false = show onboarding on launch
}
```

## 1B. Create `lib/screens/onboarding_screen.dart`

Full-screen onboarding shown only once — on the very first app launch, before `MainShell`.

### Visual layout

Background: `kSurface` (matches app theme).

Content centered vertically with `Column(mainAxisAlignment: MainAxisAlignment.center)`:

```
┌─────────────────────────────────────────┐
│                                         │
│        [App logo / icon — 80px]         │
│                                         │
│        Welcome to FreelanceHub          │  ← kStyleHeading
│   Your freelance command center         │  ← kStyleBody, centered
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  What should we call you?         │  │  ← label
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Your name...               │  │  │  ← TextFormField
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
│                                         │
│       [ Let's go →  ]                   │  ← primary button, kBlack bg
│                                         │
│  · · ●  (page dots, if multi-step)      │
└─────────────────────────────────────────┘
```

### Behavior

- Single text field: `TextFormField` with `autofocus: true`, `textCapitalization: TextCapitalization.words`, `keyboardType: TextInputType.name`
- Hint text: `"Your name..."`
- Validation: name must not be empty and must be at least 2 characters
- On tap "Let's go →" button:
  1. Validate form
  2. Call `settingsProvider.updateUserName(name.trim())`
  3. Call `settingsProvider.completeOnboarding()`
  4. Navigate to `MainShell` using `Navigator.pushReplacement` — no back arrow

### App logo widget

Create a simple logo widget: a `Container` of 80×80, `BorderRadius.circular(22)`, background `kBlack`, centered bold white "F." text in Space Grotesk 36px weight 800. (This replaces any app icon for in-app display.)

---

## 1C. Update `lib/providers/settings_provider.dart`

Add two new methods:

```dart
Future<void> updateUserName(String name) async {
  _settings.userName = name;
  await _settings.save();
  notifyListeners();
}

Future<void> completeOnboarding() async {
  _settings.onboardingDone = true;
  await _settings.save();
  notifyListeners();
}

// Convenience getter
String get userName => _settings.userName;
bool get onboardingDone => _settings.onboardingDone;
```

---

## 1D. Update `main.dart` — Route to Onboarding or MainShell

After reading settings from Hive, determine the initial route:

```dart
final settings = settingsBox.get('settings') as AppSettings?;
final showOnboarding = settings == null || !settings.onboardingDone;

runApp(
  MultiProvider(
    providers: [...],
    child: MaterialApp(
      theme: appTheme,
      home: showOnboarding ? const OnboardingScreen() : const MainShell(),
    ),
  ),
);
```

---

## 1E. Update `lib/screens/dashboard_screen.dart` — Section 1A Header

Replace the static "FreelanceHub" title with a personalized greeting:

```dart
// BEFORE
Text('FreelanceHub', style: kStyleHeading.copyWith(fontSize: 30))

// AFTER
Consumer<SettingsProvider>(
  builder: (context, sp, _) {
    final name = sp.userName.isNotEmpty ? sp.userName : 'there';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting().toUpperCase(), style: kStyleLabel),
        SizedBox(height: 2),
        Text(
          name,                                          // just the name, large
          style: kStyleHeading.copyWith(fontSize: 30),
        ),
      ],
    );
  },
)
```

Result: header now reads:
```
GOOD AFTERNOON
Ahmed
```
instead of:
```
GOOD AFTERNOON
FreelanceHub
```

---

# FEATURE 2 — DASHBOARD LAYOUT CUSTOMIZATION

Users can choose which sections appear on their dashboard and reorder them.

## 2A. Update `lib/models/app_settings.dart`

Add dashboard layout config fields:

```dart
@HiveField(4) List<String> dashboardSections = const [
  'active_projects',
  'client_strip',
  'owed_timer',
  'mrr_collected',
];
// Ordered list of enabled section IDs. User can reorder and toggle.
// All 4 sections are shown by default.

@HiveField(5) bool showActiveProjects  = true;
@HiveField(6) bool showClientStrip     = true;
@HiveField(7) bool showOwedTimer       = true;
@HiveField(8) bool showMrrCollected    = true;
```

Valid section IDs and their labels:

| ID                | Label                     | Default |
|-------------------|---------------------------|---------|
| `active_projects` | Active Projects           | ✅ on   |
| `client_strip`    | Client Overview           | ✅ on   |
| `owed_timer`      | Money Owed & Today's Time | ✅ on   |
| `mrr_collected`   | Revenue Summary           | ✅ on   |

---

## 2B. Update `lib/providers/settings_provider.dart`

Add dashboard customization methods:

```dart
List<String> get dashboardSections => List.unmodifiable(_settings.dashboardSections);

bool isSectionEnabled(String sectionId) {
  return _settings.dashboardSections.contains(sectionId);
}

Future<void> toggleSection(String sectionId) async {
  final sections = List<String>.from(_settings.dashboardSections);
  if (sections.contains(sectionId)) {
    if (sections.length == 1) return; // always keep at least 1 section
    sections.remove(sectionId);
  } else {
    sections.add(sectionId);
  }
  _settings.dashboardSections = sections;
  await _settings.save();
  notifyListeners();
}

Future<void> reorderSections(List<String> newOrder) async {
  _settings.dashboardSections = newOrder;
  await _settings.save();
  notifyListeners();
}
```

---

## 2C. Update `lib/screens/dashboard_screen.dart` — Dynamic Section Rendering

Replace the static section sequence with a dynamic builder that reads from `SettingsProvider.dashboardSections`:

```dart
// In DashboardScreen build method:
final sections = context.watch<SettingsProvider>().dashboardSections;

// Build ordered list of section widgets based on user config
final sectionWidgets = <Widget>[];
for (final id in sections) {
  switch (id) {
    case 'active_projects':
      sectionWidgets.add(_buildActiveProjectsSection(context));
      break;
    case 'client_strip':
      sectionWidgets.add(_buildClientStripSection(context));
      break;
    case 'owed_timer':
      sectionWidgets.add(_buildOwedTimerSection(context));
      break;
    case 'mrr_collected':
      sectionWidgets.add(_buildMrrCollectedSection(context));
      break;
  }
}

// Render them inside the SingleChildScrollView
return SingleChildScrollView(
  physics: const BouncingScrollPhysics(),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader(context),       // always shown, not customizable
      ...sectionWidgets,
      const SizedBox(height: 100), // bottom nav space
    ],
  ),
);
```

---

## 2D. Create `lib/screens/dashboard_customize_screen.dart`

A dedicated screen for reordering and toggling dashboard sections.

### Navigation

Accessible from Settings screen via a "Customize Dashboard" list tile. Also reachable by tapping an "Edit" icon button in the dashboard header (small `Icons.tune_rounded` icon, right of the header, next to the `+ Client` button).

### Layout

```
AppBar: "Customize Dashboard", back arrow

Body: SingleChildScrollView
  ├── SectionLabel("VISIBLE SECTIONS")
  │   Description text: "Drag to reorder. Tap toggle to show or hide."
  │
  └── ReorderableListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        onReorder: (oldIndex, newIndex) => settingsProvider.reorderSections(...),
        itemBuilder: (context, index) => _SectionTile(sectionId)
      )
```

### `_SectionTile` widget (inside the customize screen file)

```dart
// Each row:
// [≡ drag handle] [section icon] [section label] [spacer] [Toggle Switch]

// Section icons:
// active_projects  → Icons.folder_open_rounded
// client_strip     → Icons.people_alt_rounded
// owed_timer       → Icons.account_balance_wallet_rounded
// mrr_collected    → Icons.bar_chart_rounded

// Toggle Switch:
// onChanged: (val) => settingsProvider.toggleSection(sectionId)
// value: settingsProvider.isSectionEnabled(sectionId)
// activeColor: kLime (or kBlack for dark theme)

// If section is disabled (toggled off):
// Row opacity: 0.4
// The section is removed from dashboardSections list

// Drag handle: ReorderableDragStartListener wrapping Icon(Icons.drag_handle_rounded)
// color: kTextMuted
```

### Disabled state guard

Show an inline warning banner if the user tries to disable ALL sections:

```dart
if (sections.length == 1) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('At least one section must remain visible'))
  );
  return; // don't toggle
}
```

---

## 2E. Update `lib/screens/settings_screen.dart`

Add a "Dashboard" section above the existing settings card:

```dart
// New section in settings screen body, above the hourly rate card:

SectionLabel('DASHBOARD')
ListTile(
  leading: Icon(Icons.tune_rounded, color: kTextSecondary),
  title: Text('Customize Dashboard', style: kStyleBodyBold),
  subtitle: Text('Reorder and show/hide sections', style: kStyleBody),
  trailing: Icon(Icons.chevron_right_rounded, color: kTextMuted),
  onTap: () => Navigator.push(context, CupertinoPageRoute(
    builder: (_) => const DashboardCustomizeScreen()
  )),
)
Divider(color: kBorder, height: 1)
```

---

# FEATURE 3 — PUSH NOTIFICATIONS

## 3A. Add Package to `pubspec.yaml`

```yaml
dependencies:
  # ... existing packages ...
  flutter_local_notifications: ^17.2.2
  timezone: ^0.9.4
```

---

## 3B. Platform Setup

### Android — `android/app/src/main/AndroidManifest.xml`

Add inside `<application>`:
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```

Add inside `<manifest>` (alongside existing permissions):
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### iOS — `ios/Runner/AppDelegate.swift`

Add to `didFinishLaunchingWithOptions`:
```swift
UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
```

### iOS — `ios/Runner/Info.plist`

Add:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

---

## 3C. Create `lib/services/notification_service.dart`

A singleton service that wraps `flutter_local_notifications` and `timezone`.

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  // ── INIT ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,  // request separately via requestPermissions()
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // ── PERMISSION REQUEST ────────────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true, badge: true, sound: true,
    ) ?? false;

    // Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission() ?? false;

    return iosGranted || androidGranted;
  }

  // ── NOTIFICATION CHANNEL DETAILS ─────────────────────────────────────────
  AndroidNotificationDetails get _androidDetails => const AndroidNotificationDetails(
    'freelancehub_main',             // channel id
    'FreelanceHub',                  // channel name
    channelDescription: 'Project deadlines and payment reminders',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  DarwinNotificationDetails get _iosDetails => const DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  NotificationDetails get _notifDetails => NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  // ── SHOW IMMEDIATE NOTIFICATION ──────────────────────────────────────────
  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _notifDetails);
  }

  // ── SCHEDULE A NOTIFICATION ───────────────────────────────────────────────
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── CANCEL ────────────────────────────────────────────────────────────────
  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── RESCHEDULE ALL DEADLINE NOTIFICATIONS ────────────────────────────────
  /// Call this whenever projects are added, updated, or deleted.
  /// Cancels all existing scheduled notifications then re-creates them
  /// for every active project with a deadline in the future.
  Future<void> rescheduleDeadlineNotifications(List<Project> activeProjects) async {
    await cancelAll();
    int notifId = 1000; // start from 1000 to avoid collisions with other notif IDs

    for (final project in activeProjects) {
      final deadline = DateFormat('yyyy-MM-dd').parse(project.deadline);
      final now = DateTime.now();

      // 7-day warning
      final sevenDayWarning = deadline.subtract(const Duration(days: 7));
      if (sevenDayWarning.isAfter(now)) {
        await schedule(
          id: notifId++,
          title: '⏳ Deadline in 7 days',
          body: '"${project.name}" is due in 7 days. Stay on track!',
          scheduledDate: DateTime(
            sevenDayWarning.year, sevenDayWarning.month, sevenDayWarning.day,
            9, 0,  // 9:00 AM
          ),
        );
      }

      // 1-day warning
      final oneDayWarning = deadline.subtract(const Duration(days: 1));
      if (oneDayWarning.isAfter(now)) {
        await schedule(
          id: notifId++,
          title: '🚨 Deadline tomorrow!',
          body: '"${project.name}" is due tomorrow. Final push!',
          scheduledDate: DateTime(
            oneDayWarning.year, oneDayWarning.month, oneDayWarning.day,
            9, 0,
          ),
        );
      }

      // On deadline day
      final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day, 8, 0);
      if (deadlineDay.isAfter(now)) {
        await schedule(
          id: notifId++,
          title: '📅 Due today',
          body: '"${project.name}" is due today!',
          scheduledDate: deadlineDay,
        );
      }
    }
  }

  // ── PAYMENT REMINDER ──────────────────────────────────────────────────────
  /// Schedule a payment reminder 3 days after project creation if remaining > 0.
  Future<void> schedulePaymentReminder({
    required String projectName,
    required double remaining,
    required String currency,
    required int notifId,
  }) async {
    final reminderDate = DateTime.now().add(const Duration(days: 3));
    await schedule(
      id: notifId,
      title: '💰 Payment pending',
      body: '$projectName has an outstanding balance of ${fmtCurrency(remaining, currency)}',
      scheduledDate: DateTime(
        reminderDate.year, reminderDate.month, reminderDate.day, 10, 0,
      ),
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigation on tap can be implemented later with a global navigator key
    // For now, log the payload
    debugPrint('Notification tapped: ${response.payload}');
  }
}
```

---

## 3D. Update `main.dart` — Initialize NotificationService

Add `NotificationService` initialization to the bootstrap sequence, after Hive init:

```dart
// Step 3.5 — init notification service (after Hive, before runApp)
final notificationService = NotificationService();
await notificationService.init();
```

Add `NotificationService` as a `Provider` so screens can access it:

```dart
Provider<NotificationService>.value(value: notificationService),
```

---

## 3E. Update `lib/providers/data_provider.dart`

Trigger notification rescheduling on every project mutation:

```dart
// Add NotificationService as a dependency injected in constructor
final NotificationService _notifService;
DataProvider(this._notifService);  // update constructor

// After every addProject, updateProjectStatus, deleteProject call:
Future<void> _syncNotifications() async {
  final activeProjects = activeProjectsSorted.map((e) => e.project).toList();
  await _notifService.rescheduleDeadlineNotifications(activeProjects);
}

// Call _syncNotifications() at the end of:
// - addProject()
// - updateProjectStatus()
// - deleteProject()
```

Update `MultiProvider` in `main.dart`:

```dart
ChangeNotifierProvider(
  create: (_) => DataProvider(NotificationService()),
),
```

---

## 3F. Update `lib/screens/onboarding_screen.dart` — Request Permissions

At the end of onboarding (after `completeOnboarding()`), request notification permission:

```dart
// After completeOnboarding():
final granted = await NotificationService().requestPermissions();
if (granted) {
  await NotificationService().showImmediate(
    id: 1,
    title: '👋 Welcome to FreelanceHub!',
    body: 'You\'re all set. Add your first client to get started.',
  );
}
// Then navigate to MainShell regardless of permission result
Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
```

---

## 3G. Create `lib/screens/notification_settings_screen.dart`

A simple screen in Settings for managing notification preferences.

Add `@HiveField(9) bool notificationsEnabled = true;` to `AppSettings`.
Add `@HiveField(10) bool notifyDeadline7Days = true;` to `AppSettings`.
Add `@HiveField(11) bool notifyDeadline1Day  = true;` to `AppSettings`.
Add `@HiveField(12) bool notifyPayments      = true;` to `AppSettings`.

Add `updateNotificationPref(String key, bool value)` to `SettingsProvider`.

Screen layout:

```
AppBar: "Notifications"

Body:
  SectionLabel("DEADLINE REMINDERS")
  SwitchListTile(
    title: '7 days before deadline',
    subtitle: 'Get reminded a week in advance',
    value: settings.notifyDeadline7Days,
    onChanged: (v) => settingsProvider.updateNotificationPref('7days', v),
  )
  SwitchListTile(
    title: '1 day before deadline',
    subtitle: 'Last-minute reminder',
    value: settings.notifyDeadline1Day,
    onChanged: ...
  )
  SwitchListTile(
    title: 'On deadline day',
    subtitle: 'Morning reminder on the due date',
    value: settings.notifyDeadlineDay (add @HiveField(13)),
    onChanged: ...
  )

  Divider

  SectionLabel("FINANCIAL")
  SwitchListTile(
    title: 'Payment reminders',
    subtitle: 'Remind when a project has unpaid balance',
    value: settings.notifyPayments,
    onChanged: ...
  )

  Divider

  SectionLabel("ALL NOTIFICATIONS")
  SwitchListTile(
    title: 'Enable all notifications',
    subtitle: 'Master toggle — turns off all reminders',
    value: settings.notificationsEnabled,
    onChanged: (v) {
      settingsProvider.updateNotificationPref('all', v);
      if (!v) NotificationService().cancelAll();
    },
  )
```

---

## 3H. Update `lib/screens/settings_screen.dart`

Add a Notifications entry under the Dashboard section:

```dart
ListTile(
  leading: Icon(Icons.notifications_outlined, color: kTextSecondary),
  title: Text('Notifications', style: kStyleBodyBold),
  subtitle: Text('Deadlines & payment reminders', style: kStyleBody),
  trailing: Icon(Icons.chevron_right_rounded, color: kTextMuted),
  onTap: () => Navigator.push(context, CupertinoPageRoute(
    builder: (_) => const NotificationSettingsScreen()
  )),
)
```

---

# FEATURE 4 — EXCEL DATA EXPORT

Users can export all their data (clients, projects, sessions, and financial summary) as a `.xlsx` file and share or save it directly from the app.

---

## 4A. Add Packages to `pubspec.yaml`

```yaml
dependencies:
  # ... existing packages ...
  excel: ^4.0.3              # Excel file generation — pure Dart, no native code
  path_provider: ^2.1.3      # Save file to device temp directory
  share_plus: ^9.0.0         # Native share sheet to send file via email, Drive, etc.
```

---

## 4B. Platform Setup

### Android — `android/app/src/main/AndroidManifest.xml`

Add inside `<application>` (required for `share_plus` to attach files):
```xml
<provider
  android:name="androidx.core.content.FileProvider"
  android:authorities="${applicationId}.fileprovider"
  android:exported="false"
  android:grantUriPermissions="true">
  <meta-data
    android:name="android.support.FILE_PROVIDER_PATHS"
    android:resource="@xml/file_paths"/>
</provider>
```

Create `android/app/src/main/res/xml/file_paths.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
  <cache-path name="cache" path="."/>
  <external-cache-path name="external_cache" path="."/>
</paths>
```

### iOS — No additional setup required for `share_plus` file sharing.

---

## 4C. Create `lib/services/export_service.dart`

A service class that builds the Excel workbook from all app data and returns the file path.

```dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/client.dart';
import '../utils.dart';

class ExportService {

  /// Builds a complete .xlsx workbook from all client/project/session data.
  /// Returns the saved File ready to be shared.
  /// Throws an [ExportException] if writing fails.
  Future<File> exportAllData({
    required List<Client> clients,
    required String currency,
    required String userName,
  }) async {
    final excel = Excel.createExcel();

    // Remove the default empty sheet Excel creates
    excel.delete('Sheet1');

    _buildSummarySheet(excel, clients, currency, userName);
    _buildClientsSheet(excel, clients);
    _buildProjectsSheet(excel, clients, currency);
    _buildSessionsSheet(excel, clients);
    _buildFinancialSheet(excel, clients, currency);

    // Save to temp directory
    final dir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final fileName = 'FreelanceHub_Export_$timestamp.xlsx';
    final file = File('${dir.path}/$fileName');

    final bytes = excel.encode();
    if (bytes == null) throw ExportException('Failed to encode workbook');
    await file.writeAsBytes(bytes);

    return file;
  }

  // ── SHEET 1: SUMMARY ──────────────────────────────────────────────────────
  void _buildSummarySheet(Excel excel, List<Client> clients, String currency, String userName) {
    final sheet = excel['Summary'];

    // ── Header branding block ──
    _writeCell(sheet, 0, 0, 'FreelanceHub — Data Export', bold: true, fontSize: 16);
    _writeCell(sheet, 1, 0, 'Exported by: $userName');
    _writeCell(sheet, 2, 0, 'Export date: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}');
    _writeCell(sheet, 3, 0, 'Currency: $currency');

    // ── Blank spacer row ──
    sheet.appendRow([]);

    // ── KPI summary block ──
    final allProjects = clients.expand((c) => c.projects).toList();
    final totalCollected  = allProjects.fold(0.0, (s, p) => s + p.upfront);
    final totalOwed       = allProjects.fold(0.0, (s, p) => s + p.remaining);
    final totalMrr        = allProjects.where((p) => p.maintenanceActive).fold(0.0, (s, p) => s + p.maintenanceFee);
    final totalProjects   = allProjects.length;
    final activeProjects  = allProjects.where((p) => p.status == 'active').length;
    final completedCount  = allProjects.where((p) => p.status == 'completed').length;
    final totalMinutes    = allProjects.expand((p) => p.sessions).fold(0, (s, s2) => s + s2.durationMins);

    final summaryRows = [
      ['Metric', 'Value'],
      ['Total Clients', clients.length.toString()],
      ['Total Projects', totalProjects.toString()],
      ['Active Projects', activeProjects.toString()],
      ['Completed Projects', completedCount.toString()],
      ['Total Collected', fmtCurrency(totalCollected, currency)],
      ['Total Outstanding', fmtCurrency(totalOwed, currency)],
      ['Monthly Recurring (MRR)', fmtCurrency(totalMrr, currency)],
      ['Lifetime Value (est.)', fmtCurrency(totalCollected + totalOwed + totalMrr * 12, currency)],
      ['Total Hours Logged', fmtDuration(totalMinutes)],
    ];

    for (var i = 0; i < summaryRows.length; i++) {
      final row = summaryRows[i];
      final isHeader = i == 0;
      _writeCell(sheet, 5 + i, 0, row[0], bold: isHeader, backgroundHex: isHeader ? 'FF202020' : null, fontColorHex: isHeader ? 'FFFFFFFF' : null);
      _writeCell(sheet, 5 + i, 1, row[1], bold: isHeader, backgroundHex: isHeader ? 'FF202020' : null, fontColorHex: isHeader ? 'FFFFFFFF' : null);
    }

    // Column widths
    sheet.setColumnWidth(0, 30);
    sheet.setColumnWidth(1, 25);
  }

  // ── SHEET 2: CLIENTS ──────────────────────────────────────────────────────
  void _buildClientsSheet(Excel excel, List<Client> clients) {
    final sheet = excel['Clients'];

    final headers = ['Name', 'Company', 'Type', 'Email', 'Phone', 'Projects', 'Active', 'Member Since', 'Notes'];
    _writeHeaderRow(sheet, headers);

    for (final c in clients) {
      sheet.appendRow([
        TextCellValue(c.name),
        TextCellValue(c.company),
        TextCellValue(c.type == 'website' ? 'Website' : 'Graphic Design'),
        TextCellValue(c.email),
        TextCellValue(c.phone),
        IntCellValue(c.projects.length),
        IntCellValue(c.activeCount),
        TextCellValue(c.createdAt),
        TextCellValue(c.notes),
      ]);
    }

    _setColumnWidths(sheet, [22, 20, 16, 28, 18, 10, 8, 14, 40]);
  }

  // ── SHEET 3: PROJECTS ─────────────────────────────────────────────────────
  void _buildProjectsSheet(Excel excel, List<Client> clients, String currency) {
    final sheet = excel['Projects'];

    final headers = [
      'Client', 'Project Name', 'Type', 'Status', 'Pricing',
      'Total Value', 'Upfront Paid', 'Remaining', 'Maintenance/mo', 'Maintenance Active',
      'Est. Hours', 'Logged Hours', 'Progress %',
      'Start Date', 'Deadline', 'Days Left',
      'Services', 'Notes',
    ];
    _writeHeaderRow(sheet, headers);

    for (final c in clients) {
      for (final p in c.projects) {
        final days = daysLeft(p.deadline);
        final progress = p.estimatedHours > 0
            ? '${(p.loggedHours / p.estimatedHours * 100).round().clamp(0, 100)}%'
            : '0%';
        final daysLeftStr = days < 0 ? 'Overdue by ${days.abs()} days' : '$days days';

        sheet.appendRow([
          TextCellValue(c.name),
          TextCellValue(p.name),
          TextCellValue(p.type == 'website' ? 'Website' : 'Graphic Design'),
          TextCellValue(_statusLabel(p.status)),
          TextCellValue(p.pricingType == 'fixed' ? 'Fixed Price' : 'Hourly'),
          TextCellValue(fmtCurrency(p.upfront + p.remaining, currency)),
          TextCellValue(fmtCurrency(p.upfront, currency)),
          TextCellValue(fmtCurrency(p.remaining, currency)),
          TextCellValue(p.maintenanceFee > 0 ? fmtCurrency(p.maintenanceFee, currency) : '—'),
          TextCellValue(p.maintenanceActive ? 'Yes' : 'No'),
          DoubleCellValue(p.estimatedHours),
          DoubleCellValue(double.parse(p.loggedHours.toStringAsFixed(2))),
          TextCellValue(progress),
          TextCellValue(p.startDate),
          TextCellValue(p.deadline),
          TextCellValue(daysLeftStr),
          TextCellValue(p.services.join(', ')),
          TextCellValue(p.notes),
        ]);
      }
    }

    _setColumnWidths(sheet, [20, 24, 16, 12, 10, 14, 14, 14, 14, 10, 10, 12, 10, 12, 12, 16, 30, 36]);
  }

  // ── SHEET 4: WORK SESSIONS ────────────────────────────────────────────────
  void _buildSessionsSheet(Excel excel, List<Client> clients) {
    final sheet = excel['Work Sessions'];

    final headers = ['Client', 'Project', 'Date', 'Duration (min)', 'Duration (h)', 'Note'];
    _writeHeaderRow(sheet, headers);

    for (final c in clients) {
      for (final p in c.projects) {
        // Sort sessions by date ascending
        final sorted = List.of(p.sessions)
          ..sort((a, b) => a.date.compareTo(b.date));

        for (final s in sorted) {
          sheet.appendRow([
            TextCellValue(c.name),
            TextCellValue(p.name),
            TextCellValue(s.date),
            IntCellValue(s.durationMins),
            TextCellValue(fmtDuration(s.durationMins)),
            TextCellValue(s.note),
          ]);
        }
      }
    }

    _setColumnWidths(sheet, [20, 24, 14, 14, 12, 40]);
  }

  // ── SHEET 5: FINANCIAL BREAKDOWN ─────────────────────────────────────────
  void _buildFinancialSheet(Excel excel, List<Client> clients, String currency) {
    final sheet = excel['Financial'];

    // ── Per-client financial summary ──
    _writeCell(sheet, 0, 0, 'Per-Client Financial Breakdown', bold: true, fontSize: 13);
    sheet.appendRow([]);

    final clientHeaders = ['Client', 'Total Value', 'Collected', 'Outstanding', 'MRR', 'Projects'];
    _writeHeaderRow(sheet, clientHeaders, startRow: 2);

    var row = 3;
    for (final c in clients) {
      final totalVal = c.projects.fold(0.0, (s, p) => s + p.upfront + p.remaining);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(c.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(fmtCurrency(totalVal, currency));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(fmtCurrency(c.totalPaid, currency));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(fmtCurrency(c.totalOwed, currency));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(c.totalMrr > 0 ? fmtCurrency(c.totalMrr, currency) + '/mo' : '—');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = IntCellValue(c.projects.length);
      row++;
    }

    // ── Totals row ──
    final grandTotal    = clients.fold(0.0, (s, c) => s + c.totalPaid + c.totalOwed);
    final grandPaid     = clients.fold(0.0, (s, c) => s + c.totalPaid);
    final grandOwed     = clients.fold(0.0, (s, c) => s + c.totalOwed);
    final grandMrr      = clients.fold(0.0, (s, c) => s + c.totalMrr);

    _writeCell(sheet, row, 0, 'TOTAL', bold: true, backgroundHex: 'FFc9f158');
    _writeCell(sheet, row, 1, fmtCurrency(grandTotal, currency), bold: true, backgroundHex: 'FFc9f158');
    _writeCell(sheet, row, 2, fmtCurrency(grandPaid, currency), bold: true, backgroundHex: 'FFc9f158');
    _writeCell(sheet, row, 3, fmtCurrency(grandOwed, currency), bold: true, backgroundHex: 'FFc9f158');
    _writeCell(sheet, row, 4, fmtCurrency(grandMrr, currency) + '/mo', bold: true, backgroundHex: 'FFc9f158');
    _writeCell(sheet, row, 5, clients.length.toString(), bold: true, backgroundHex: 'FFc9f158');

    _setColumnWidths(sheet, [22, 16, 16, 16, 14, 10]);
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  void _writeHeaderRow(Sheet sheet, List<String> headers, {int startRow = 0}) {
    // If startRow == 0, appendRow; otherwise write to specific row index
    if (startRow == 0) {
      // Find the next empty row
      final rowIdx = sheet.maxRows;
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('FF202020'),
          fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
          fontSize: 11,
        );
      }
    } else {
      for (var col = 0; col < headers.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: startRow));
        cell.value = TextCellValue(headers[col]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('FF202020'),
          fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
          fontSize: 11,
        );
      }
    }
  }

  void _writeCell(
    Sheet sheet, int row, int col, String value, {
    bool bold = false,
    int? fontSize,
    String? backgroundHex,
    String? fontColorHex,
  }) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    cell.cellStyle = CellStyle(
      bold: bold,
      fontSize: fontSize,
      backgroundColorHex: backgroundHex != null ? ExcelColor.fromHexString(backgroundHex) : null,
      fontColorHex: fontColorHex != null ? ExcelColor.fromHexString(fontColorHex) : null,
    );
  }

  void _setColumnWidths(Sheet sheet, List<double> widths) {
    for (var i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  String _statusLabel(String status) => switch (status) {
    'active'    => 'Active',
    'completed' => 'Completed',
    'paused'    => 'Paused',
    'cancelled' => 'Cancelled',
    _           => status,
  };
}

class ExportException implements Exception {
  final String message;
  ExportException(this.message);
  @override String toString() => 'ExportException: $message';
}
```

---

## 4D. Create `lib/screens/export_screen.dart`

A dedicated screen for previewing what will be exported and triggering the download.

### Navigation

Accessible from Settings screen via an "Export Data" list tile.

### Layout

```
AppBar: "Export Data", back arrow

Body: SingleChildScrollView, padding 20
  ├── [Export summary card]         ← shows count of what will be exported
  ├── [Sheets preview list]         ← shows which sheets will be in the file
  ├── [Export button]               ← triggers generation + share sheet
  └── [Last export info]            ← shows date/time of last export if any
```

### Export Summary Card

```dart
Container(
  decoration: kCardDecoration(),
  padding: EdgeInsets.all(20),
  child: Column(children: [
    SectionLabel('WHAT GETS EXPORTED'),
    SizedBox(height: 12),
    // 4 rows:
    _ExportStat(icon: Icons.people_alt_rounded,         label: 'Clients',       value: '${clients.length}'),
    _ExportStat(icon: Icons.folder_open_rounded,        label: 'Projects',      value: '${totalProjects}'),
    _ExportStat(icon: Icons.timer_outlined,             label: 'Work Sessions', value: '${totalSessions}'),
    _ExportStat(icon: Icons.account_balance_wallet_rounded, label: 'Financial Records', value: 'Full breakdown'),
  ]),
)
```

`_ExportStat` is a `Row` with icon + label in `kStyleBody` + spacer + bold value in `kStyleBodyBold`.

### Sheets Preview List

```dart
Container(
  decoration: kCardDecoration(),
  padding: EdgeInsets.all(20),
  child: Column(children: [
    SectionLabel('EXCEL SHEETS INCLUDED'),
    SizedBox(height: 12),
    _SheetPreviewTile(number: '1', name: 'Summary',             desc: 'KPIs, totals, export metadata'),
    _SheetPreviewTile(number: '2', name: 'Clients',             desc: 'All client contact & profile info'),
    _SheetPreviewTile(number: '3', name: 'Projects',            desc: 'All projects with financial details'),
    _SheetPreviewTile(number: '4', name: 'Work Sessions',       desc: 'Every logged session with duration'),
    _SheetPreviewTile(number: '5', name: 'Financial',           desc: 'Per-client revenue breakdown + totals'),
  ]),
)
```

`_SheetPreviewTile`: Row with a `kLime`-tinted circle containing the sheet number, then column of name (bold) + description (caption).

### Export Button

```dart
// Full-width primary button (kBlack background, white text)
// Label: "Download Excel File"
// Leading icon: Icons.download_rounded

// State machine:
// idle     → shows "Download Excel File" with download icon
// loading  → shows CircularProgressIndicator (white, size 20) with "Generating..." label
// done     → briefly shows "✓ File Ready" in kGreen for 1.5s then resets to idle
// error    → shows "Export failed — Try again" in kRed

ElevatedButton.icon(
  onPressed: _isLoading ? null : _handleExport,
  icon: _isLoading
    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: kWhite, strokeWidth: 2))
    : Icon(Icons.download_rounded),
  label: Text(_buttonLabel),
)
```

### Export handler method

```dart
Future<void> _handleExport() async {
  setState(() { _isLoading = true; _buttonLabel = 'Generating...'; });

  try {
    final dataProvider   = context.read<DataProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    final file = await ExportService().exportAllData(
      clients:  dataProvider.clients,
      currency: settingsProvider.settings.currency,
      userName: settingsProvider.userName,
    );

    // Save last export timestamp to settings
    await settingsProvider.updateLastExportDate(DateTime.now());

    // Open system share sheet
    await SharePlus.instance.shareXFiles(
      [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
      subject: 'FreelanceHub Export',
      text: 'My FreelanceHub data export — ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
    );

    setState(() { _isLoading = false; _buttonLabel = '✓ File Ready'; });
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() { _buttonLabel = 'Download Excel File'; });

  } on ExportException catch (e) {
    setState(() { _isLoading = false; _buttonLabel = 'Export failed — Try again'; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export error: ${e.message}'), backgroundColor: kRed),
    );
  } catch (e) {
    setState(() { _isLoading = false; _buttonLabel = 'Export failed — Try again'; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unexpected error. Please try again.'), backgroundColor: kRed),
    );
  }
}
```

### Last Export Info

Below the export button, show a muted caption if a previous export date is stored:

```dart
if (lastExportDate != null)
  Padding(
    padding: EdgeInsets.only(top: 12),
    child: Text(
      'Last exported: ${DateFormat('MMM d, yyyy — HH:mm').format(lastExportDate!)}',
      style: kStyleCaption,
      textAlign: TextAlign.center,
    ),
  )
```

---

## 4E. Update `lib/models/app_settings.dart`

Add last export date field. **Append only — do not change existing indices:**

```dart
@HiveField(14) String? lastExportDate;   // ISO datetime string, nullable
```

---

## 4F. Update `lib/providers/settings_provider.dart`

Add export date methods:

```dart
DateTime? get lastExportDate {
  final raw = _settings.lastExportDate;
  return raw != null ? DateTime.parse(raw) : null;
}

Future<void> updateLastExportDate(DateTime date) async {
  _settings.lastExportDate = date.toIso8601String();
  await _settings.save();
  notifyListeners();
}
```

---

## 4G. Update `lib/screens/settings_screen.dart`

Add an "Export" section at the top of the settings screen body, before the Dashboard section:

```dart
SectionLabel('DATA')
ListTile(
  leading: Icon(Icons.download_rounded, color: kTextSecondary),
  title: Text('Export Data', style: kStyleBodyBold),
  subtitle: Text('Download all data as Excel (.xlsx)', style: kStyleBody),
  trailing: Icon(Icons.chevron_right_rounded, color: kTextMuted),
  onTap: () => Navigator.push(context, CupertinoPageRoute(
    builder: (_) => const ExportScreen()
  )),
)
Divider(color: kBorder, height: 1)
```

---

## 4H. Add Quick Export to Finance Screen

On `lib/screens/finance_screen.dart`, add a small export icon button in the AppBar `actions`:

```dart
AppBar(
  title: Text('Revenue'),
  actions: [
    IconButton(
      icon: Icon(Icons.download_rounded),
      tooltip: 'Export to Excel',
      onPressed: () => Navigator.push(context, CupertinoPageRoute(
        builder: (_) => const ExportScreen()
      )),
    ),
  ],
)
```

---

# FILES TO CREATE OR MODIFY

| File | Action |
|------|--------|
| `lib/models/app_settings.dart` | Modify — add fields 2–14 |
| `lib/providers/settings_provider.dart` | Modify — add userName, onboarding, dashboard, notification, export methods |
| `lib/providers/data_provider.dart` | Modify — inject NotificationService, call _syncNotifications |
| `lib/screens/onboarding_screen.dart` | **Create new** |
| `lib/screens/dashboard_screen.dart` | Modify — personalized header + dynamic sections |
| `lib/screens/dashboard_customize_screen.dart` | **Create new** |
| `lib/screens/notification_settings_screen.dart` | **Create new** |
| `lib/screens/export_screen.dart` | **Create new** |
| `lib/screens/settings_screen.dart` | Modify — add Data, Dashboard, and Notifications list tiles |
| `lib/screens/finance_screen.dart` | Modify — add export icon button to AppBar |
| `lib/services/notification_service.dart` | **Create new** |
| `lib/services/export_service.dart` | **Create new** |
| `main.dart` | Modify — onboarding routing + NotificationService init |
| `pubspec.yaml` | Modify — add flutter_local_notifications, timezone, excel, path_provider, share_plus |
| `android/app/src/main/AndroidManifest.xml` | Modify — notification receivers + FileProvider |
| `android/app/src/main/res/xml/file_paths.xml` | **Create new** |
| `ios/Runner/Info.plist` | Modify — add background modes |

---

# FINAL CHECKLIST

- [ ] `AppSettings` new HiveFields start at index 2 — existing indices 0 and 1 are unchanged
- [ ] Last export date stored at `@HiveField(14)` as nullable ISO string
- [ ] After adding new `@HiveField` entries, run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] `OnboardingScreen` shown only when `settings.onboardingDone == false`
- [ ] After onboarding completes, `MainShell` is shown with `Navigator.pushReplacement` (no back arrow)
- [ ] Dashboard header shows `userName` from `SettingsProvider`, falls back to `"there"` if empty
- [ ] `dashboardSections` list controls section order AND visibility — a section not in the list is not rendered
- [ ] `toggleSection` prevents removing the last section (minimum 1 always visible)
- [ ] `reorderSections` saves new order to Hive immediately
- [ ] `DashboardCustomizeScreen` uses `ReorderableListView` with drag handles
- [ ] `NotificationService` is a singleton — `NotificationService()` always returns the same instance
- [ ] `tz.initializeTimeZones()` called once in `NotificationService.init()`
- [ ] Notification permissions requested at end of onboarding, not on app launch
- [ ] `rescheduleDeadlineNotifications()` called after every project add/update/delete
- [ ] Master notification toggle calls `cancelAll()` when turned off
- [ ] Notification settings respect individual toggles (7days/1day/payment) inside `rescheduleDeadlineNotifications`
- [ ] `SwitchListTile` in notification settings uses `kLime` (or `kBlack`) as `activeColor`
- [ ] All new screens use `SafeArea`, `BouncingScrollPhysics`, Space Grotesk font, light theme colors
- [ ] `ExportService` creates exactly 5 sheets: Summary, Clients, Projects, Work Sessions, Financial
- [ ] Header rows in all sheets use `FF202020` background (near-black) with `FFFFFFFF` white text
- [ ] Totals row in Financial sheet uses `FFc9f158` background (lime green) to match brand
- [ ] `ExportService.exportAllData()` saves file to `getTemporaryDirectory()` — not Documents (avoids permission issues on both platforms)
- [ ] `SharePlus.instance.shareXFiles()` called with correct MIME type `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- [ ] Export button shows 3-state feedback: loading spinner → "✓ File Ready" → reset
- [ ] `ExportException` caught separately from generic exceptions in the UI handler
- [ ] `android/app/src/main/res/xml/file_paths.xml` created with `<cache-path>` entry for `share_plus` FileProvider
- [ ] Finance screen AppBar has export icon button that navigates to `ExportScreen`
- [ ] Sessions in Work Sessions sheet are sorted by date ascending per project
- [ ] `fmtCurrency` and `fmtDuration` from `utils.dart` reused inside `ExportService` — no duplicate formatting logic
