# SYSTEM / ROLE FRAMING
You are an expert Flutter architect and senior mobile developer with 7+ years of production Flutter experience. You write clean, idiomatic Dart code following the official Flutter style guide. You never skip sections, never use placeholder comments like `// TODO` or `// implement this`, and never truncate code with `...`. Generate the complete, working implementation for every file listed. If the full output exceeds your context window, continue generating in sequential follow-up messages until every file is complete.

---

# TASK
Build a complete, production-ready Flutter mobile application called **FreelanceHub**. This is a client and project management tool for an independent freelancer who works on **website development** and **graphic design** projects. The app must work entirely offline — no network calls, no Firebase, no REST API. All data is persisted locally on the device using Hive and survives app restarts. Target: iOS and Android.

---

# OUTPUT INSTRUCTIONS
- Generate every file in the suggested file structure below, in order
- Output each file as a complete, runnable Dart file with all imports included
- Do not abbreviate, truncate, or summarise any section
- Do not ask clarifying questions — follow the spec exactly
- After generating all files, output the complete `pubspec.yaml`
- After `pubspec.yaml`, output the required Android manifest additions and iOS `Info.plist` additions

---

# PUBSPEC.YAML

```yaml
name: freelancehub
description: Offline freelancer client & project management app
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  provider: ^6.1.1
  uuid: ^4.3.3
  intl: ^0.19.0
  google_fonts: ^6.2.1
  flutter_slidable: ^3.1.0
  fl_chart: ^0.68.0
  url_launcher: ^6.2.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

---

# PLATFORM SETUP

## Android — `android/app/src/main/AndroidManifest.xml`
Add inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="mailto"/>
  </intent>
  <intent>
    <action android:name="android.intent.action.DIAL"/>
    <data android:scheme="tel"/>
  </intent>
</queries>
```

## iOS — `ios/Runner/Info.plist`
Add inside the root `<dict>`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>mailto</string>
  <string>tel</string>
</array>
```

---

# HIVE SETUP & CODE GENERATION

> **IMPORTANT**: All Hive model classes must use `@HiveType` and `@HiveField` annotations. After generating all model files, the developer must run `flutter pub run build_runner build --delete-conflicting-outputs` to generate the `.g.dart` adapter files. Each model file must include its corresponding `part '*.g.dart';` directive. Type IDs must be globally unique across all models.

Type ID assignments (never reuse these):
- `AppSettings` → typeId: 0
- `WorkSession` → typeId: 1
- `Project` → typeId: 2
- `Client` → typeId: 3

In `main.dart`, register all adapters before opening boxes:
```dart
Hive.registerAdapter(AppSettingsAdapter());
Hive.registerAdapter(WorkSessionAdapter());
Hive.registerAdapter(ProjectAdapter());
Hive.registerAdapter(ClientAdapter());
```

---

# MAIN.DART BOOTSTRAP SPEC

`main.dart` must do the following in order:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `await Hive.initFlutter()`
3. Register all four Hive type adapters (see above)
4. Open the `'settings'` box and the `'clients'` box
5. Run the seed data check — if `'seeded_v1'` key is absent from the settings box, write seed data and set that key to `true`
6. Wrap `runApp` in a `MultiProvider` with three providers:
   - `ChangeNotifierProvider` for `SettingsProvider`
   - `ChangeNotifierProvider` for `DataProvider`
   - `ChangeNotifierProvider` for `TimerProvider`
7. Use `SystemChrome.setSystemUIOverlayStyle` to make the status bar transparent with light icons (matches dark theme)

---

# DESIGN SYSTEM

## Color Palette — `lib/theme.dart`

```dart
// Backgrounds
const Color kBg         = Color(0xFF0F0F1A);
const Color kBgCard     = Color(0xFF16162A);
const Color kBgCardAlt  = Color(0xFF1C1C30);

// Accents
const Color kPurple     = Color(0xFFa78bfa);
const Color kBlue       = Color(0xFF60a5fa);
const Color kGreen      = Color(0xFF4ade80);
const Color kYellow     = Color(0xFFfacc15);
const Color kOrange     = Color(0xFFfb923c);
const Color kRed        = Color(0xFFf87171);
const Color kPink       = Color(0xFFf472b6);

// Text
const Color kTextPrimary   = Color(0xFFf0e6d3);
const Color kTextSecondary = Color(0x99f0e6d3);
const Color kTextMuted     = Color(0x44f0e6d3);

// Borders
const Color kBorder        = Color(0x1Affffff);
const Color kBorderStrong  = Color(0x30ffffff);
```

## Typography

All text styles are defined as top-level constants in `theme.dart`. Use `GoogleFonts.playfairDisplay()` for display/heading styles and `GoogleFonts.dmSans()` for all body text. Do NOT use `textTransform` — it does not exist in Flutter. Use `.toUpperCase()` on `String` values inside `Text()` widgets when all-caps display is needed.

```dart
TextStyle kStyleHeading = GoogleFonts.playfairDisplay(
  fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary,
);
TextStyle kStyleHeadingSm = GoogleFonts.playfairDisplay(
  fontSize: 20, fontWeight: FontWeight.w700, color: kTextPrimary,
);
TextStyle kStyleLabel = GoogleFonts.dmSans(
  fontSize: 11, fontWeight: FontWeight.w600,
  letterSpacing: 1.5, color: kTextMuted,
);
TextStyle kStyleBody = GoogleFonts.dmSans(
  fontSize: 14, color: kTextSecondary,
);
TextStyle kStyleBodyBold = GoogleFonts.dmSans(
  fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary,
);
TextStyle kStyleTimer = GoogleFonts.dmSans(
  fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary,
  fontFeatures: [FontFeature.tabularFigures()],
);
TextStyle kStyleCaption = GoogleFonts.dmSans(
  fontSize: 11, color: kTextMuted,
);
```

## Card / Container Decoration Helpers

Define these as helper functions in `theme.dart`:

```dart
BoxDecoration kCardDecoration({
  Color? borderColor,
  Color background = kBgCard,
  double radius = 18,
}) => BoxDecoration(
  color: background,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: borderColor ?? kBorder, width: 1),
);

BoxDecoration kInputDecoration = BoxDecoration(
  color: kBgCardAlt,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: kBorder),
);
```

## ThemeData

```dart
ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBg,
  colorScheme: ColorScheme.dark(
    primary: kPurple,
    secondary: kBlue,
    surface: kBgCard,
    error: kRed,
    onPrimary: kBg,
  ),
  textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
  appBarTheme: AppBarTheme(
    backgroundColor: kBg,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: GoogleFonts.playfairDisplay(
      fontSize: 20, fontWeight: FontWeight.w700, color: kTextPrimary,
    ),
    iconTheme: const IconThemeData(color: kTextSecondary),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kBgCardAlt,
    labelStyle: GoogleFonts.dmSans(
      fontSize: 11, letterSpacing: 1.5, color: kTextMuted,
    ),
    hintStyle: GoogleFonts.dmSans(fontSize: 14, color: kTextMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPurple, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kRed),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.transparent,
    selectedItemColor: kPurple,
    unselectedItemColor: kTextMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 0.5),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: kBgCard,
    titleTextStyle: GoogleFonts.playfairDisplay(
      fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary,
    ),
    contentTextStyle: GoogleFonts.dmSans(fontSize: 14, color: kTextSecondary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: kBgCard,
    contentTextStyle: GoogleFonts.dmSans(color: kTextPrimary),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
```

## Avatar Color Helper

```dart
const List<Color> kAvatarColors = [
  Color(0xFFE8A87C), Color(0xFF85C1E9), Color(0xFF82E0AA),
  Color(0xFFF1948A), Color(0xFFBB8FCE), Color(0xFF76D7C4),
  Color(0xFFF7DC6F),
];

Color avatarColorFor(String name) {
  int h = 0;
  for (final c in name.runes) {
    h = (h * 31 + c) % kAvatarColors.length;
  }
  return kAvatarColors[h];
}
```

## Ambient Glow Background Widget

Create a reusable `AmbientBackground` widget used as the root Stack layer on all screens:

```dart
// A fixed Stack overlay placed behind screen content on every scaffold.
// Purple glow top-left, blue glow bottom-right. Both use ImageFilter.blur.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(top: -100, left: -100, child: _glow(300, kPurple, 0.04)),
      Positioned(bottom: 50, right: -80, child: _glow(250, kBlue, 0.04)),
      child,
    ]);
  }

  Widget _glow(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(opacity),
    ),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: const SizedBox.expand(),
    ),
  );
}
```

---

# DATA MODELS

## `lib/models/work_session.dart`

```dart
import 'package:hive/hive.dart';
part 'work_session.g.dart';

@HiveType(typeId: 1)
class WorkSession extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String date;       // 'yyyy-MM-dd'
  @HiveField(2) late int durationMins;  // total minutes (always > 0)
  @HiveField(3) late String note;
}
```

## `lib/models/project.dart`

```dart
import 'package:hive/hive.dart';
import 'work_session.dart';
part 'project.g.dart';

@HiveType(typeId: 2)
class Project extends HiveObject {
  @HiveField(0)  late String id;
  @HiveField(1)  late String name;
  @HiveField(2)  late String status;          // 'active'|'completed'|'paused'|'cancelled'
  @HiveField(3)  late String type;            // 'website'|'graphic'
  @HiveField(4)  late String startDate;       // 'yyyy-MM-dd'
  @HiveField(5)  late String deadline;        // 'yyyy-MM-dd'
  @HiveField(6)  late String pricingType;     // 'fixed'|'hourly'
  @HiveField(7)  late double fixedPrice;
  @HiveField(8)  late double hourlyRate;
  @HiveField(9)  late double estimatedHours;
  @HiveField(10) late double loggedHours;     // recomputed from sessions on every mutation
  @HiveField(11) late double upfront;
  @HiveField(12) late double remaining;
  @HiveField(13) late double maintenanceFee;
  @HiveField(14) late bool maintenanceActive;
  @HiveField(15) late List<String> services;
  @HiveField(16) late List<WorkSession> sessions;
  @HiveField(17) late String notes;

  /// Always call this after adding/removing sessions
  void recomputeLoggedHours() {
    loggedHours = sessions.fold(0.0, (sum, s) => sum + s.durationMins / 60.0);
  }

  double get totalValue => upfront + remaining;
}
```

## `lib/models/client.dart`

```dart
import 'package:hive/hive.dart';
import 'project.dart';
part 'client.g.dart';

@HiveType(typeId: 3)
class Client extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late String company;
  @HiveField(3) late String email;
  @HiveField(4) late String phone;
  @HiveField(5) late String type;        // 'website'|'graphic'
  @HiveField(6) late String avatar;      // initials, max 2 chars
  @HiveField(7) late String createdAt;   // 'yyyy-MM-dd'
  @HiveField(8) late String notes;
  @HiveField(9) late List<Project> projects;

  double get totalPaid     => projects.fold(0, (s, p) => s + p.upfront);
  double get totalOwed     => projects.fold(0, (s, p) => s + p.remaining);
  double get totalMrr      => projects.where((p) => p.maintenanceActive).fold(0, (s, p) => s + p.maintenanceFee);
  int    get totalMins     => projects.expand((p) => p.sessions).fold(0, (s, s2) => s + s2.durationMins);
  int    get activeCount   => projects.where((p) => p.status == 'active').length;
}
```

## `lib/models/app_settings.dart`

```dart
import 'package:hive/hive.dart';
part 'app_settings.g.dart';

@HiveType(typeId: 0)
class AppSettings extends HiveObject {
  @HiveField(0) double hourlyRate = 50.0;
  @HiveField(1) String currency   = 'USD';

  static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'NGN', 'CAD'];
}
```

---

# PROVIDERS

## `lib/providers/settings_provider.dart`

Wraps `AppSettings` stored in Hive. Exposes:
- `AppSettings get settings`
- `Future<void> updateHourlyRate(double rate)`
- `Future<void> updateCurrency(String currency)`
- Validates currency is in `AppSettings.supportedCurrencies` before saving

## `lib/providers/data_provider.dart`

The main CRUD provider. Stores a `List<Client>` in memory, syncs to Hive box `'clients'` on every mutation. Exposes:

**Client operations:**
- `List<Client> get clients`
- `List<Client> get sortedClients` — alphabetical by name
- `Future<void> addClient(Client c)`
- `Future<void> deleteClient(String clientId)` — cascades deletes all associated projects/sessions
- `Client? findClient(String id)`

**Project operations:**
- `Future<void> addProject(String clientId, Project p)`
- `Future<void> updateProjectStatus(String clientId, String projectId, String status)`
- `Future<void> deleteProject(String clientId, String projectId)`
- `List<({Project project, Client client})> get activeProjectsSorted` — active projects sorted by deadline ascending

**Session operations:**
- `Future<void> addSession(String clientId, String projectId, WorkSession s)` — must call `project.recomputeLoggedHours()` after adding

**Computed aggregates:**
- `double get totalCollected` — sum of all `project.upfront`
- `double get totalOwed` — sum of all `project.remaining`
- `double get totalMrr` — sum of maintenance fees for active maintenance projects
- `int get todayMinutes` — sum of session durations where `session.date == todayStr()`
- `double get lifetimeValue` — `totalCollected + totalOwed + (totalMrr * 12)`

**Error handling:** Wrap all Hive writes in try/catch. On failure, call `notifyListeners()` anyway and optionally set an `String? lastError` field.

## `lib/providers/timer_provider.dart`

Global timer — only one project can have a running timer at any time.

Fields:
```dart
bool isRunning = false;
String? activeProjectId;
String? activeClientId;
String? activeProjectName;  // for display in conflict dialogs
DateTime? startTime;
int elapsedSeconds = 0;
Timer? _ticker;
```

Methods:
- `void startTimer(String clientId, String projectId, String projectName)` — sets `isRunning = true`, records `startTime = DateTime.now()`, starts `Timer.periodic(Duration(seconds: 1), ...)` that increments `elapsedSeconds` and calls `notifyListeners()`
- `WorkSession stopTimer()` — stops the ticker, computes `durationMins = max(1, (elapsedSeconds / 60).round())`, resets all fields to null/false/0, returns a `WorkSession` object with today's date, computed duration, and note `'Live session'`
- `void discardTimer()` — stops ticker, resets all state, does NOT return a session (used when elapsed < 60s)
- `String get displayTime` — returns `HH:MM:SS` string from `elapsedSeconds` with leading zeros
- `bool isTimerForProject(String projectId)` — returns `activeProjectId == projectId`

**Timer conflict handling:** `startTimer()` must first check `isRunning`. If already running, throw a custom `TimerConflictException(activeProjectName)`. The UI catches this exception and shows the conflict dialog.

---

# UTILITY FUNCTIONS — `lib/utils.dart`

```dart
import 'package:intl/intl.dart';

/// Format a monetary amount using the given currency code.
/// Outputs no decimal places (e.g. "$1,200" not "$1,200.00").
String fmtCurrency(double amount, String currency) {
  final symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'NGN': '₦', 'CAD': 'CA\$'};
  final symbol = symbols[currency] ?? currency;
  return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(amount);
}

/// Format total minutes as "Xh Ym". If minutes is 0, returns "0h".
String fmtDuration(int totalMins) {
  final h = totalMins ~/ 60;
  final m = totalMins % 60;
  if (totalMins == 0) return '0h';
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}

/// Days until deadline. Negative means overdue.
/// Uses date-only comparison (no time component).
int daysLeft(String deadline) {
  final d = DateFormat('yyyy-MM-dd').parse(deadline);
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  return d.difference(today).inDays;
}

/// Progress as integer percentage, clamped to [0, 100].
int progressPct(double logged, double estimated) {
  if (estimated <= 0) return 0;
  return (logged / estimated * 100).round().clamp(0, 100);
}

/// Today's date as 'yyyy-MM-dd'
String todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// Time-based greeting
String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Compute initials from a full name (max 2 characters, uppercase).
/// "Sarah Mitchell" → "SM", "Kat" → "K"
String initialsFrom(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
```

---

# SEED DATA

Called once on first launch only. Use dates relative to `DateTime.now()` so projects are not permanently overdue:

```dart
// In seed_data.dart — call seedIfNeeded(box) from main.dart
void seedIfNeeded(Box settingsBox, Box clientsBox) {
  if (settingsBox.get('seeded_v1') == true) return;

  final now = DateTime.now();
  final fmt = DateFormat('yyyy-MM-dd');

  // Compute dynamic dates so the demo always looks live
  final activeDeadline = fmt.format(now.add(const Duration(days: 18)));
  final activeStart    = fmt.format(now.subtract(const Duration(days: 45)));
  final completedDeadline = fmt.format(now.subtract(const Duration(days: 60)));
  final completedStart    = fmt.format(now.subtract(const Duration(days: 130)));
  final session1Date = fmt.format(now.subtract(const Duration(days: 30)));
  final session2Date = fmt.format(now.subtract(const Duration(days: 15)));
  final session3Date = fmt.format(now.subtract(const Duration(days: 100)));
  final session4Date = fmt.format(now.subtract(const Duration(days: 80)));

  final clients = [
    // Client 1: Sarah Mitchell — active project
    Client()
      ..id = const Uuid().v4()
      ..name = 'Sarah Mitchell'
      ..company = 'Bloom Studio'
      ..type = 'website'
      ..email = 'sarah@bloom.co'
      ..phone = '+1 555-0101'
      ..avatar = 'SM'
      ..createdAt = fmt.format(now.subtract(const Duration(days: 90)))
      ..notes = 'Prefers communication via email. Very detail-oriented.'
      ..projects = [
        Project()
          ..id = const Uuid().v4()
          ..name = 'Portfolio Redesign'
          ..status = 'active'
          ..type = 'website'
          ..startDate = activeStart
          ..deadline = activeDeadline
          ..pricingType = 'fixed'
          ..fixedPrice = 2400
          ..hourlyRate = 0
          ..estimatedHours = 40
          ..loggedHours = 7.0
          ..upfront = 1200
          ..remaining = 1200
          ..maintenanceFee = 120
          ..maintenanceActive = true
          ..services = ['UI Design', 'Development', 'SEO Setup']
          ..notes = 'Client wants minimalist look. Figma file shared.'
          ..sessions = [
            WorkSession()
              ..id = const Uuid().v4()
              ..date = session1Date
              ..durationMins = 180
              ..note = 'Wireframes',
            WorkSession()
              ..id = const Uuid().v4()
              ..date = session2Date
              ..durationMins = 240
              ..note = 'Homepage build',
          ],
      ],

    // Client 2: James Okafor — completed project
    Client()
      ..id = const Uuid().v4()
      ..name = 'James Okafor'
      ..company = 'Kafor Brands'
      ..type = 'graphic'
      ..email = 'james@kafor.ng'
      ..phone = '+234 812 000 1234'
      ..avatar = 'JO'
      ..createdAt = fmt.format(now.subtract(const Duration(days: 200)))
      ..notes = 'Quick to respond. Lagos based.'
      ..projects = [
        Project()
          ..id = const Uuid().v4()
          ..name = 'Brand Identity Pack'
          ..status = 'completed'
          ..type = 'graphic'
          ..startDate = completedStart
          ..deadline = completedDeadline
          ..pricingType = 'fixed'
          ..fixedPrice = 1800
          ..hourlyRate = 0
          ..estimatedHours = 30
          ..loggedHours = 12.0 + 8.0
          ..upfront = 1800
          ..remaining = 0
          ..maintenanceFee = 0
          ..maintenanceActive = false
          ..services = ['Logo Design', 'Brand Guidelines', 'Social Kit']
          ..notes = 'Delivered all files in AI, PDF, PNG formats.'
          ..sessions = [
            WorkSession()
              ..id = const Uuid().v4()
              ..date = session3Date
              ..durationMins = 300
              ..note = 'Logo concepts',
            WorkSession()
              ..id = const Uuid().v4()
              ..date = session4Date
              ..durationMins = 480
              ..note = 'Full brand guide',
          ],
      ],
  ];

  clientsBox.put('all', clients);
  settingsBox.put('seeded_v1', true);
}
```

---

# NAVIGATION ARCHITECTURE

Use a `StatefulWidget` root shell (`MainShell`) with a `BottomNavigationBar` and `IndexedStack` to preserve tab state. The Clients tab uses its own nested `Navigator` (via `Navigator` widget with a `GlobalKey<NavigatorState>`) so that back navigation within Clients (List → Detail → Project) does not pop back to Dashboard.

```
MaterialApp
└── MainShell (StatefulWidget, manages selectedIndex)
    ├── IndexedStack index 0: DashboardScreen
    ├── IndexedStack index 1: Navigator (Clients)
    │   ├── route '/': ClientListScreen
    │   ├── route '/client': ClientDetailScreen (passes clientId via RouteSettings.arguments)
    │   └── route '/project': ProjectDetailScreen (passes clientId + projectId via RouteSettings.arguments)
    ├── IndexedStack index 2: FinanceScreen
    └── IndexedStack index 3: SettingsScreen
```

Navigating to a client: `clientsNavigatorKey.currentState?.pushNamed('/client', arguments: clientId)`
Navigating to a project: `clientsNavigatorKey.currentState?.pushNamed('/project', arguments: {'clientId': ..., 'projectId': ...})`

The Android back button on the Clients tab should pop within the Clients navigator first; only when it's at the root does the back button minimize the app.

## Bottom Navigation Bar

Custom `BottomNavigationBar` widget with:
- `ClipRect` + `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))` for the frosted glass effect
- Background: `kBg.withOpacity(0.85)` over the blur
- Top border via `BoxDecoration` with `Border(top: BorderSide(color: kBorder))`
- All labels in `.toUpperCase()`
- Bottom safe area padding: `MediaQuery.of(context).padding.bottom`

---

# REUSABLE WIDGETS — `lib/widgets/`

## `status_badge.dart`

```dart
// StatusBadge — colored pill widget for project status
// status: 'active'|'completed'|'paused'|'cancelled'
// Returns a Container with rounded corners (20), colored background at 13% opacity,
// colored border at 27% opacity, and status label in ALL CAPS.
// Color map: active→kGreen, completed→kBlue, paused→kYellow, cancelled→kRed
```

## `progress_bar.dart`

```dart
// CustomProgressBar
// height: double (default 6)
// value: double (0.0 to 1.0)
// Color: kRed if value > 0.9, kYellow if > 0.7, kGreen otherwise
// Background: kBorder (white 10%)
// Animated: use TweenAnimationBuilder to animate from 0.0 to value on first build
// Duration: 500ms, curve: Curves.easeOut
```

## `avatar_widget.dart`

```dart
// ClientAvatar
// name: String — used for color lookup and initials
// size: double (default 48)
// radius: double (default 14)
// Shows a rounded rectangle with:
//   background: avatarColorFor(name).withOpacity(0.20)
//   border: avatarColorFor(name).withOpacity(0.33)
//   text: initialsFrom(name) in avatarColorFor(name), FontWeight.w700
```

## `section_label.dart`

```dart
// SectionLabel — small ALL-CAPS spaced label for section headers
// text: String
// trailing: Widget? (optional right-side widget, e.g. count or button)
// Renders text in kStyleLabel with .toUpperCase()
```

## `stat_card.dart`

```dart
// StatCard — small single-metric card
// label: String
// value: String
// valueColor: Color
// borderColor: Color? (optional — if provided, card uses that border color)
// backgroundTint: Color? (optional — card background tinted at 6% opacity)
```

## `timer_display.dart`

```dart
// TimerDisplay — shows HH:MM:SS with AnimatedSwitcher fade on each digit group
// elapsedSeconds: int
// style: TextStyle (use kStyleTimer)
// Each of the three groups (HH, MM, SS) wrapped in AnimatedSwitcher
// duration 150ms, FadeTransition
```

---

# SCREEN 1 — DASHBOARD (`lib/screens/dashboard_screen.dart`)

Wrap content in `Scaffold(backgroundColor: kBg, body: AmbientBackground(child: SafeArea(...)))`.

Content is a `SingleChildScrollView` with `physics: BouncingScrollPhysics()`. Build sections in this exact order:

### Section 1A: Header
Padding: `EdgeInsets.fromLTRB(20, 24, 20, 0)`

Row with:
- Left column: greeting text in `kStyleLabel` + `.toUpperCase()`, then "FreelanceHub" in `kStyleHeading` with `fontSize: 30`
- Right: `_PurpleButton(label: '+ Client', onTap: () => showAddClientSheet(context))` — appears at the top right, `margin: EdgeInsets.only(top: 8)`

### Section 1B: Active Projects & Deadlines
Padding: `EdgeInsets.fromLTRB(20, 20, 20, 0)`

Row header: `SectionLabel(text: 'Active Projects', trailing: Text('${activeProjects.length} running', style: kStyleCaption))`

Active projects come from `DataProvider.activeProjectsSorted`.

**Empty state** (when list is empty):
```
Container with dashed border (color: kBorder, width: 1), BorderRadius.circular(16),
padding: EdgeInsets.symmetric(vertical: 28), centered Text in kTextMuted:
"No active projects · Add a client to get started"
```

**Project card** (for each active project):
```
GestureDetector → navigate to project detail screen
Container: kCardDecoration with conditional border color (see urgency system below)
padding: EdgeInsets.all(16), margin: EdgeInsets.only(bottom: 10)
```

Card body:
1. `Stack` with optional urgency top strip at `Alignment.topCenter` — a `Container` of height 2px, full width, colored per urgency tier, `BorderRadius.vertical(top: Radius.circular(18))`
2. Row: left side (project name in `kStyleBodyBold`, below it a Row with mini `ClientAvatar(size: 20, radius: 5)`, client name in `kStyleCaption`, separator dot, type emoji) | right side (deadline badge)
3. Deadline badge: `Container` with `BorderRadius.circular(10)`, padding, colored per urgency. Contains a large bold day number + small caps "days"/"overdue" label
4. `SizedBox(height: 10)` then `CustomProgressBar(value: progressPct(...) / 100)`
5. Row of 3 caption texts: logged time | progress % | owed amount or "✓ Paid"

### Section 1C: Client Overview Horizontal Strip
Padding: `EdgeInsets.only(top: 16)`

`SectionLabel` with text 'Clients', padding `EdgeInsets.symmetric(horizontal: 20)`.

`SizedBox(height: 100, child: ListView.builder(scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: 20)))`

Each client card (minimum width 110px):
- `GestureDetector` → navigate to client detail
- Container with `kCardDecoration(radius: 16)`, padding 12
- `ClientAvatar(size: 40, radius: 12)` centered
- First name only (truncated with overflow ellipsis)
- Type label "🌐 Web" or "🎨 Design"
- Active count badge if `client.activeCount > 0`

Last item: add-new card with dashed border, purple `+` icon, "New" label in `kPurple`.

### Section 1D: Owed + Today 2-column
Padding: `EdgeInsets.fromLTRB(20, 16, 20, 0)`

`Row` with two equal `Expanded` children, gap 10.

**Owed card:** `StatCard` with conditional yellow tint if owed > 0, green if 0.
Sub-label: "across N projects" or "all settled ✓"

**Today/Timer card:** Reads from `TimerProvider`. If running: green tint, live `TimerDisplay`, small red "Stop & Save" button. If idle: plain card, total today minutes from `DataProvider.todayMinutes`, sub-label "logged today".

Stop & Save handler:
```dart
final session = timerProvider.stopTimer();
await dataProvider.addSession(timerProvider.activeClientId!, timerProvider.activeProjectId!, session);
```

### Section 1E: MRR + Collected Footer
Padding: `EdgeInsets.fromLTRB(20, 10, 20, 100)` (100 bottom = space above nav bar)

`Row` with two `Expanded` children, gap 10.
- Left: blue-tinted pill — "Monthly Recurring" + "{amount}/mo"
- Right: green-tinted pill — "Collected" + total collected amount

---

# SCREEN 2 — CLIENT LIST (`lib/screens/client_list_screen.dart`)

`Scaffold(backgroundColor: kBg, body: AmbientBackground(child: SafeArea(...)))`

Header: `SectionLabel('DIRECTORY')` + `Text('Clients', style: kStyleHeading)` + purple `+ New` button (top-right).

`ListView.builder` wrapping each client in `Slidable`:
```dart
Slidable(
  endActionPane: ActionPane(
    motion: const DrawerMotion(),
    children: [
      SlidableAction(
        onPressed: (_) => _confirmDeleteClient(context, client),
        backgroundColor: kRed,
        icon: Icons.delete_outline,
        label: 'Delete',
      ),
    ],
  ),
  child: ClientListCard(client: client, onTap: () => navigate to detail),
)
```

`ClientListCard` shows: avatar (48px) | name + company + type badge + active badge | owed amount + project count.

**Empty state:** Centered icon + "No clients yet · Tap + to add your first client"

---

# SCREEN 3 — CLIENT DETAIL (`lib/screens/client_detail_screen.dart`)

`Scaffold` with `AppBar(title: Text('Client Profile'), leading: BackButton())`.

Body: `SingleChildScrollView` with `BouncingScrollPhysics`.

Sections:
1. **Profile card:** Avatar (64px) + name (Playfair 20) + company + type badge + email row (tappable via `url_launcher`, `launchUrl(Uri.parse('mailto:${client.email})`)`) + phone row (tappable via `tel:`) + notes block (italic, quote-styled container)
2. **Stats row:** 3 `StatCard`s — Paid (green), Owed (yellow), Hours (blue)
3. **Projects section:** `SectionLabel` + `TextButton('+ Add')`. List of project mini-cards. Each tappable → project detail. Shows name + `StatusBadge` + `CustomProgressBar` + "{logged}h / {estimated}h" + total value.
4. **Empty projects:** "No projects yet" with a dashed-border prompt.

---

# SCREEN 4 — PROJECT DETAIL (`lib/screens/project_detail_screen.dart`)

`Scaffold` with `AppBar` showing project name + `StatusBadge` as `actions`.

Body: `SingleChildScrollView` with `BouncingScrollPhysics`, padding bottom 100.

Sections (in order):

**1. Time Tracker Card**
Reads from `TimerProvider`. Check `timerProvider.isTimerForProject(project.id)`.

If timer running on this project:
- Green-tinted `kCardDecoration`, label "⏱ RUNNING" in `kGreen`
- `TimerDisplay` widget showing live elapsed time
- Red `ElevatedButton` "Stop & Save" — calls `stopTimer()` + `dataProvider.addSession(...)`

If timer running on a DIFFERENT project:
- Show a "▶ Start" button — but on tap, catch `TimerConflictException` and show:
  ```
  AlertDialog with title: 'Timer already running'
  content: 'A timer is already running on "${exception.projectName}". Stop it first?'
  actions: [TextButton('Cancel'), ElevatedButton('Stop & Switch', color: kOrange)]
  ```
  On "Stop & Switch": call `stopTimer()` on the old session, save it to the old project, then start new timer.

If no timer running:
- Default card, label "TIME TRACKER", total logged time, green "▶ Start" button

**2. Financials Card**
2×2 `GridView` (shrinkWrap, non-scrollable) of `StatCard`s:
- Project Value / Upfront Paid / Remaining / Maintenance (or "—" if not active)
If hourly pricing: purple info bar below: "@ {rate}/hr · Est. max: {fmtCurrency(estimatedHours * hourlyRate)}"

**3. Progress Card**
`SectionLabel('PROGRESS', trailing: deadline text in urgency color)`
`CustomProgressBar(value: pct / 100, height: 8)`
Row: logged | percentage | estimated

**4. Services Card** — `Wrap` of filter chips (non-interactive, purple tint)

**5. Work Sessions Card**
Header row + `TextButton('+ Manual', onTap: () => showLogSessionSheet(...))`
`ListView` (shrinkWrap, non-scrollable) of last 5 sessions reversed.
Each session row: note text + date | duration in `kBlue`. `Divider` between rows.

**6. Notes Card** — only shown if `project.notes.isNotEmpty`

**7. Action Row**
`Row` with:
- `Expanded` "✓ Mark Complete" button (green outline) if status != 'completed' → calls `dataProvider.updateProjectStatus(...)` then pops
- `OutlinedButton` trash icon (red) → confirm dialog → `dataProvider.deleteProject(...)` then pops

---

# SCREEN 5 — FINANCE (`lib/screens/finance_screen.dart`)

Header: "OVERVIEW" label + "Revenue" heading.

**1. Lifetime Value Hero Card:**
`Container` with `LinearGradient([kPurple.withOpacity(0.13), kBlue.withOpacity(0.13)])` background.
Shows `fmtCurrency(dataProvider.lifetimeValue, currency)` in Playfair Display 40px.
Sub-label: "incl. MRR annualized"

**2. Breakdown List (3 rows):**
`ListTile`-style rows: icon + label + bold amount. Colors: green/yellow/blue.

**3. Bar Chart (fl_chart `BarChart`):**
One bar per client, height = `client.totalPaid + client.totalOwed`.
Bar color: `avatarColorFor(client.name)`.
X-axis labels: first name only.
Y-axis: `fmtCurrency(value, currency)` at 3 evenly-spaced ticks.
`BarTouchData(enabled: true)` with tooltip showing client name + total.
Chart padding: `FlBorderData(show: false)`, `gridData: FlGridData(show: true, horizontalInterval: ..., getDrawingHorizontalLine: (v) => FlLine(color: kBorder, strokeWidth: 0.5))`.
Wrap in `SizedBox(height: 200)`.

**4. Per-Client Breakdown:**
`SectionLabel('PER CLIENT')`
Each client: mini card (avatar + name + total | sub-row with paid/owed/mrr in color-coded small text)

---

# SCREEN 6 — SETTINGS (`lib/screens/settings_screen.dart`)

Header: "PREFERENCES" label + "Settings" heading.

Settings card with:
- `TextFormField` for hourly rate (number input, `TextInputType.numberWithOptions(decimal: true)`) — on changed, debounce 500ms then call `settingsProvider.updateHourlyRate()`
- `DropdownButtonFormField<String>` for currency — `DropdownMenuItem` for each in `AppSettings.supportedCurrencies` — on changed, call `settingsProvider.updateCurrency()`

Footer: centered caption "FreelanceHub · All data stored locally on your device" + app version below.

---

# BOTTOM SHEETS — `lib/sheets/`

All bottom sheets use `showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: ...)`.

Outer container: `Container` with `decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.vertical(top: Radius.circular(24)))`.

Header: drag handle (centered 32×4px rounded bar, `kBorder` color) + `Row` with Playfair Display title + close `IconButton`.

Body: `SingleChildScrollView` with `padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24)` to handle keyboard.

## `add_client_sheet.dart`

Fields in order:
1. Full Name (`TextFormField`, required, validator: `(v) => v == null || v.trim().isEmpty ? 'Name is required' : null`)
2. Company
3. Email (`TextInputType.emailAddress`)
4. Phone (`TextInputType.phone`)
5. Client Type — `SegmentedButton<String>` with segments "🌐 Website" and "🎨 Graphic Design" (values 'website' and 'graphic')
6. Notes (`maxLines: 3`)

Submit button: purple full-width `ElevatedButton('Add Client')`. Calls `Form.validate()` first. On success: builds `Client` object using `Uuid().v4()` for id, `initialsFrom(name)` for avatar, `todayStr()` for createdAt, `[]` for projects. Then calls `dataProvider.addClient(client)` and `Navigator.pop(context)`.

## `add_project_sheet.dart`

Receives `clientId` as a parameter.

Fields in order:
1. Project Name (required)
2. Type toggle — same `SegmentedButton` as above
3. Start Date — `TextFormField` with a `CalendarDatePicker` dialog on tap (hint: "Select start date")
4. Deadline (required) — same date picker approach
5. Pricing Type — `SegmentedButton<String>` with 'Fixed Price' and 'Hourly Rate'
6. Conditional: if Fixed → "Fixed Price" number field; if Hourly → "Hourly Rate" number field prefilled from `settingsProvider.settings.hourlyRate`
7. Estimated Hours (number field)
8. Upfront Paid (number field)
9. Remaining (number field). Optional: auto-fill from `fixedPrice - upfront` when fixedPrice and upfront are both filled
10. Maintenance /mo (number field) + `Switch` for "Active" in the same row (use `Row` with `Expanded` field + `Switch`)
11. Services (free text, hint: "Logo Design, Brand Guide" — split on comma on submit)
12. Notes (multiline)

Submit: `Form.validate()` then build `Project` and call `dataProvider.addProject(clientId, project)`.

## `log_session_sheet.dart`

Receives `clientId` and `projectId`.

Fields:
1. Date — tap to open date picker, default today
2. Hours (number, `TextInputType.number`)
3. Minutes (number, `TextInputType.number`)
4. Note (text)

Validation: hours + minutes must sum to > 0. Show inline error if both are 0 on submit.

Submit: compute `durationMins = hours * 60 + minutes`, build `WorkSession`, call `dataProvider.addSession(clientId, projectId, session)`, pop.

---

# DEADLINE URGENCY VISUAL SYSTEM

Implement a `DeadlineUrgency` enum and helper in `utils.dart`:

```dart
enum DeadlineUrgency { normal, warning, urgent, overdue }

DeadlineUrgency urgencyFor(String deadline) {
  final d = daysLeft(deadline);
  if (d < 0)  return DeadlineUrgency.overdue;
  if (d < 5)  return DeadlineUrgency.urgent;
  if (d < 10) return DeadlineUrgency.warning;
  return DeadlineUrgency.normal;
}

Color urgencyColor(DeadlineUrgency u) => switch (u) {
  DeadlineUrgency.overdue => kRed,
  DeadlineUrgency.urgent  => kOrange,
  DeadlineUrgency.warning => kYellow,
  DeadlineUrgency.normal  => kTextMuted,
};

// Returns null if no strip should be shown (normal/warning)
Color? urgencyStripColor(DeadlineUrgency u) => switch (u) {
  DeadlineUrgency.overdue => kRed,
  DeadlineUrgency.urgent  => kOrange,
  _ => null,
};

// Border color for project card
Color urgencyBorderColor(DeadlineUrgency u) => switch (u) {
  DeadlineUrgency.overdue => kRed.withOpacity(0.19),
  DeadlineUrgency.urgent  => kOrange.withOpacity(0.15),
  _ => kBorder,
};
```

---

# ERROR STATES & EMPTY STATES

Define a reusable `EmptyState` widget:
```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  // Renders: icon (40px, kTextMuted), message text, optional TextButton
}
```

Use `EmptyState` in:
- Client list: `icon: Icons.people_outline, message: 'No clients yet · Tap + to add your first'`
- Client projects: `icon: Icons.folder_outlined, message: 'No projects yet'`, actionLabel: `'+ Add project'`
- Dashboard active projects: dashed-border container instead of `EmptyState`

For Hive read errors: in `DataProvider`, catch exceptions and set `bool hasError = false; String errorMessage = ''`. In the UI, if `dataProvider.hasError`, show a `SnackBar` with the error message and a "Retry" action that calls `dataProvider.reload()`.

---

# CONFIRMATION DIALOGS

Implement a reusable `showConfirmDialog(BuildContext context, {required String title, required String message, required String confirmLabel, Color confirmColor = kRed, VoidCallback? onConfirm})` function in `lib/utils.dart`.

Uses `AlertDialog` with `kBgCard` background, Playfair title, DM Sans content, muted cancel button, and styled confirm button.

Required dialog calls:
1. Delete client: title "Delete client?", message "This will remove ${client.name} and all their projects and sessions.", confirmLabel "Delete", confirmColor `kRed`
2. Delete project: title "Delete project?", message "All sessions and financial data for '${project.name}' will be permanently deleted.", confirmLabel "Delete", confirmColor `kRed`
3. Mark complete: title "Mark as complete?", message "This will set '${project.name}' to completed. You can still view it in the client profile.", confirmLabel "Mark complete", confirmColor `kGreen`
4. Timer conflict: custom `AlertDialog` (not the generic confirm dialog) with additional "Stop & Switch" button in `kOrange`

---

# ANIMATIONS & TRANSITIONS

- **Screen push:** Use `CupertinoPageRoute` for all `clientsNavigatorKey` pushes for native iOS slide
- **Progress bars:** `TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: value), duration: 500ms, curve: Curves.easeOut)`
- **Timer digits:** `AnimatedSwitcher` wrapping each HH/MM/SS text block, `duration: Duration(milliseconds: 150)`, `transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child)`
- **Card tap:** `InkWell` with `splashColor: kPurple.withOpacity(0.10)`, `highlightColor: kPurple.withOpacity(0.05)`
- **Tab switch:** Instant (no animation)
- **Bottom sheet open:** Default Flutter slide-up
- **Bottom sheet content:** `AnimatedPadding` that responds to `MediaQuery.of(context).viewInsets.bottom` for smooth keyboard avoidance

---

# FINAL REQUIREMENTS CHECKLIST

Before finalizing any generated file, verify every item:

- [ ] Fully offline — zero network calls anywhere in the codebase
- [ ] `WidgetsFlutterBinding.ensureInitialized()` called before any async work in `main()`
- [ ] All 4 Hive adapters registered before any box is opened
- [ ] All model classes have `@HiveType`, `@HiveField`, and `part '*.g.dart'` — DO NOT skip annotations
- [ ] Seed data uses `DateTime.now()`-relative dates — never hardcoded past dates
- [ ] `recomputeLoggedHours()` called on `Project` after every `addSession` or `removeSession`
- [ ] `TextTransform` is NOT used anywhere — use `.toUpperCase()` on String values
- [ ] `TimerProvider` throws `TimerConflictException` when `startTimer()` is called while already running
- [ ] Timer "Stop & Save" always calls `dataProvider.addSession()` with the returned `WorkSession`
- [ ] Only one `Timer.periodic` instance active at any time in `TimerProvider`
- [ ] `SafeArea` wraps body on all screens
- [ ] `BouncingScrollPhysics()` on all `ListView` and `SingleChildScrollView`
- [ ] All bottom sheets use `isScrollControlled: true` + `viewInsets.bottom` padding
- [ ] `url_launcher` used for email and phone with `launchUrl` (not deprecated `launch`)
- [ ] Android `AndroidManifest.xml` has `<queries>` block for mailto and tel
- [ ] iOS `Info.plist` has `LSApplicationQueriesSchemes` for mailto and tel
- [ ] `fl_chart` `BarChart` has `BarTouchData(enabled: true)` with tooltip
- [ ] Currency formatting uses `intl` — never hardcoded symbols except in the `fmtCurrency` symbols map
- [ ] `daysLeft()` uses date-only comparison — strips time component before diffing
- [ ] `EmptyState` widget used for all empty list states
- [ ] `showConfirmDialog()` used for all destructive actions
- [ ] Ambient glow `AmbientBackground` wraps content on every screen
- [ ] All `Text` using `kStyleLabel` also calls `.toUpperCase()` on the string value
- [ ] `DataProvider` exposes `hasError` and `reload()` for Hive failure recovery
- [ ] Dark theme only — no `MediaQuery.platformBrightness` checks
