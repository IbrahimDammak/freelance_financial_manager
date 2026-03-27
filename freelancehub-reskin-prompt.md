# DESIGN RESKIN + CURRENCY UPDATE — FreelanceHub

## SCOPE OF CHANGES
This is a targeted update to `lib/theme.dart`, `lib/utils.dart`, and `lib/models/app_settings.dart` only.
All logic, data models, providers, screens, and navigation remain exactly as specified in the original prompt.
Do not regenerate any file not listed in this update.

---

## 1. REPLACE THE ENTIRE DESIGN SYSTEM — `lib/theme.dart`

### 1A. Design Reference

The new design follows a **clean, high-contrast light theme** inspired by a modern neobank UI with these characteristics:
- **Light background** — near-white surfaces, not dark
- **Bold lime green accent** — used for primary buttons, active states, brand elements
- **Near-black** for text, card backgrounds, and dark UI elements
- **Rounded, card-heavy layout** — large border radii, soft shadows
- **Space Grotesk font** — geometric, modern, slightly technical
- No gradients. No glow effects. Flat, sharp, confident.

---

### 1B. New Color Palette

Replace ALL previous color constants with the following. Delete every old `k*` color constant.

```dart
// ── BRAND ────────────────────────────────────────────────────────────────────
const Color kLime        = Color(0xFFc9f158);   // PRIMARY accent — buttons, active nav, highlights
const Color kBlack       = Color(0xFF202020);   // near-black — dark cards, primary text, filled buttons
const Color kWhite       = Color(0xFFffffff);   // pure white — card surfaces, modal backgrounds
const Color kSurface     = Color(0xFFf2f3f5);   // page background — very light grey

// ── BACKGROUNDS ──────────────────────────────────────────────────────────────
const Color kBg          = kSurface;            // scaffold background
const Color kBgCard      = kWhite;              // card surface
const Color kBgCardAlt   = Color(0xFFf7f8fa);   // input field background, alternate card

// ── SEMANTIC COLORS ───────────────────────────────────────────────────────────
const Color kGreen       = Color(0xFF22c55e);   // success — paid, completed, all-clear
const Color kYellow      = Color(0xFFf59e0b);   // warning — owed money, paused
const Color kOrange      = Color(0xFFf97316);   // urgent — deadline < 5 days
const Color kRed         = Color(0xFFef4444);   // danger — overdue, delete, cancelled
const Color kBlue        = Color(0xFF3b82f6);   // info — MRR, website type, completed badge

// ── TEXT ──────────────────────────────────────────────────────────────────────
const Color kTextPrimary   = Color(0xFF202020);  // near-black — main readable text
const Color kTextSecondary = Color(0xFF6b7280);  // medium grey — subtitles, descriptions
const Color kTextMuted     = Color(0xFFa1a9b4);  // light grey — labels, placeholders, captions

// ── BORDERS ───────────────────────────────────────────────────────────────────
const Color kBorder        = Color(0xFFe8eaed);  // subtle divider
const Color kBorderStrong  = Color(0xFFd1d5db);  // stronger border, focused field

// ── PINK (graphic design type label) ─────────────────────────────────────────
const Color kPink        = Color(0xFFec4899);

// ── ALIAS: kPurple is replaced by kLime as the primary interactive color ──────
// Do NOT define kPurple. Any place the old prompt used kPurple, use kLime instead.
```

---

### 1C. New Typography — Space Grotesk

Replace ALL previous `kStyle*` text styles. Use **only** `GoogleFonts.spaceGrotesk()`. Remove all references to Playfair Display and DM Sans.

```dart
// Headings
TextStyle kStyleHeading = GoogleFonts.spaceGrotesk(
  fontSize: 28, fontWeight: FontWeight.w700, color: kTextPrimary,
);
TextStyle kStyleHeadingSm = GoogleFonts.spaceGrotesk(
  fontSize: 20, fontWeight: FontWeight.w700, color: kTextPrimary,
);

// Section labels (ALL CAPS — caller must call .toUpperCase() on the string)
TextStyle kStyleLabel = GoogleFonts.spaceGrotesk(
  fontSize: 11, fontWeight: FontWeight.w600,
  letterSpacing: 1.5, color: kTextMuted,
);

// Body text
TextStyle kStyleBody = GoogleFonts.spaceGrotesk(
  fontSize: 14, fontWeight: FontWeight.w400, color: kTextSecondary,
);
TextStyle kStyleBodyBold = GoogleFonts.spaceGrotesk(
  fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrimary,
);

// Timer — monospace-like tabular figures
TextStyle kStyleTimer = GoogleFonts.spaceGrotesk(
  fontSize: 24, fontWeight: FontWeight.w800, color: kTextPrimary,
  fontFeatures: [FontFeature.tabularFigures()],
);

// Small captions
TextStyle kStyleCaption = GoogleFonts.spaceGrotesk(
  fontSize: 11, fontWeight: FontWeight.w400, color: kTextMuted,
);

// Large number display (balance, revenue total)
TextStyle kStyleDisplay = GoogleFonts.spaceGrotesk(
  fontSize: 36, fontWeight: FontWeight.w700, color: kTextPrimary,
);

// Button label
TextStyle kStyleButton = GoogleFonts.spaceGrotesk(
  fontSize: 15, fontWeight: FontWeight.w700, color: kBlack,
);
```

---

### 1D. Updated Card Decoration Helpers

Replace the previous `kCardDecoration` and `kInputDecoration` helpers:

```dart
BoxDecoration kCardDecoration({
  Color? borderColor,
  Color background = kBgCard,
  double radius = 20,
  bool hasShadow = true,
}) =>
  BoxDecoration(
    color: background,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor ?? kBorder, width: 1),
    boxShadow: hasShadow
      ? [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]
      : null,
  );

BoxDecoration kInputDecorationBox = BoxDecoration(
  color: kBgCardAlt,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: kBorder),
);
```

> Note: Default card radius is now **20** (was 18). The light theme uses a very subtle drop shadow instead of a colored border glow.

---

### 1E. Updated ThemeData

Replace the entire `appTheme` definition:

```dart
ThemeData appTheme = ThemeData(
  brightness: Brightness.light,                    // LIGHT THEME
  scaffoldBackgroundColor: kSurface,
  colorScheme: ColorScheme.light(
    primary: kBlack,                               // filled buttons, active elements
    secondary: kLime,                              // accent
    surface: kWhite,
    error: kRed,
    onPrimary: kWhite,
    onSecondary: kBlack,
    onSurface: kTextPrimary,
  ),
  textTheme: GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme).apply(
    bodyColor: kTextPrimary,
    displayColor: kTextPrimary,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.spaceGrotesk(
      fontSize: 17, fontWeight: FontWeight.w700, color: kTextPrimary,
    ),
    iconTheme: const IconThemeData(color: kTextPrimary),
    systemOverlayStyle: SystemUiOverlayStyle.dark,  // dark status bar icons on light bg
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kBgCardAlt,
    labelStyle: GoogleFonts.spaceGrotesk(
      fontSize: 11, letterSpacing: 1.5, color: kTextMuted,
    ),
    hintStyle: GoogleFonts.spaceGrotesk(fontSize: 14, color: kTextMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kBlack, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kRed),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: kWhite,
    selectedItemColor: kBlack,
    unselectedItemColor: kTextMuted,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w700),
    unselectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 0.5),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kBlack,
      foregroundColor: kWhite,
      textStyle: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(double.infinity, 52),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kTextPrimary,
      side: const BorderSide(color: kBorder, width: 1),
      textStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(double.infinity, 48),
    ),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: kWhite,
    titleTextStyle: GoogleFonts.spaceGrotesk(
      fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary,
    ),
    contentTextStyle: GoogleFonts.spaceGrotesk(fontSize: 14, color: kTextSecondary),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 4,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: kBlack,
    contentTextStyle: GoogleFonts.spaceGrotesk(color: kWhite),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);
```

---

### 1F. Remove AmbientBackground Widget

Delete the `AmbientBackground` widget entirely. The light theme does not use glow effects.

Replace all usages of `AmbientBackground(child: ...)` with just the child directly. Every screen's scaffold body becomes:

```dart
// BEFORE
body: AmbientBackground(child: SafeArea(child: content))

// AFTER
body: SafeArea(child: content)
```

---

### 1G. Color Replacement Map

Every place in the codebase that previously used an old color, apply this exact substitution:

| Old color        | New color        | Notes                                    |
|------------------|------------------|------------------------------------------|
| `kPurple`        | `kLime`          | Primary interactive color                |
| `kBg` (dark)     | `kSurface`       | Already aliased above                    |
| `kBgCard` (dark) | `kWhite`         | Already aliased above                    |
| `kTextPrimary` (warm white) | `kTextPrimary` (near-black) | Already redefined   |
| `kTextSecondary` (white 60%) | `kTextSecondary` (grey) | Already redefined |
| `kTextMuted` (white 27%) | `kTextMuted` (light grey) | Already redefined  |
| `kBorder` (white 10%) | `kBorder` (light grey) | Already redefined              |

Semantic colors `kGreen`, `kYellow`, `kOrange`, `kRed`, `kBlue`, `kPink` retain their meaning but have updated hex values as defined in Section 1B.

---

### 1H. Updated Avatar Colors

Replace `kAvatarColors` list with light-theme-appropriate pastel variants that look good on white cards:

```dart
const List<Color> kAvatarColors = [
  Color(0xFFfbbf24), // amber
  Color(0xFF34d399), // emerald
  Color(0xFF60a5fa), // sky blue
  Color(0xFFf472b6), // pink
  Color(0xFFa78bfa), // violet
  Color(0xFFfb923c), // orange
  Color(0xFF4ade80), // green
];
```

Avatar widget: white card background, avatar color at **15% opacity** background, avatar color at **30% opacity** border, initials in avatar color at **full opacity**.

---

### 1I. Updated Status Badge Colors

No change to semantic status meanings. But badge rendering on the light theme must use:
- Background: status color at **10% opacity** (was 13%)
- Border: status color at **25% opacity** (was 27%)
- Text: status color at **full opacity**, `FontWeight.w700`

---

### 1J. Primary Button Style

The primary CTA button (previously purple `kPurple`) is now a **solid black pill**:

```dart
// Primary button — black fill, white text, full width, 52px height, radius 14
// Used for: "Add Client", "Create Project", "Save Session", "Add Money", etc.
style: ElevatedButton.styleFrom(
  backgroundColor: kBlack,
  foregroundColor: kWhite,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  minimumSize: const Size(double.infinity, 52),
  elevation: 0,
  textStyle: kStyleButton,
)
```

The lime green `kLime` is used for:
- Active bottom nav item icon + label color
- Active/selected state highlights
- Progress bar fill color (overrides the old green/yellow/red logic — see Section 1K)
- "New" quick-action buttons (small accent pills)
- Dashboard small action chips

---

### 1K. Updated Progress Bar Color Logic

Replace the old 3-tier color logic with:

```dart
// In CustomProgressBar widget:
// value <= 0.7  → kLime (lime green, on track)
// value <= 0.9  → kYellow (amber, nearing limit)
// value > 0.9   → kRed (over limit warning)
// Track background: kBgCardAlt (light grey)
```

---

### 1L. Bottom Navigation Bar Style

The bottom nav is now **white** with a top border and subtle shadow:

```dart
// Bottom nav container decoration:
BoxDecoration(
  color: kWhite,
  border: Border(top: BorderSide(color: kBorder, width: 1)),
  boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, -4))],
)
```

Active nav item: icon and label in `kBlack`, with a small `kLime`-colored dot or underline indicator below.
Inactive nav item: icon and label in `kTextMuted`.
Remove the `BackdropFilter` blur — not needed on a light theme.

---

### 1M. Dashboard "Owed to You" Card — Light Theme Update

- If owed > 0: background `kYellow.withOpacity(0.08)`, border `kYellow.withOpacity(0.25)`, value text in `kYellow`
- If owed = 0: background `kGreen.withOpacity(0.08)`, border `kGreen.withOpacity(0.20)`, value text in `kGreen`, label "all settled ✓"

---

### 1N. Dashboard Timer Card — Light Theme Update

- If timer running: background `kLime.withOpacity(0.15)`, border `kLime.withOpacity(0.40)`, timer text in `kBlack`
- Stop button: `kRed` background, white text
- If idle: default white card

---

### 1O. Finance Hero Card — Light Theme Update

Replace the dark gradient hero card with:

```dart
Container(
  decoration: BoxDecoration(
    color: kBlack,                         // solid near-black background
    borderRadius: BorderRadius.circular(24),
  ),
  padding: EdgeInsets.all(24),
  child: Column(children: [
    Text('TOTAL LIFETIME VALUE', style: kStyleLabel.copyWith(color: Colors.white54)),
    SizedBox(height: 8),
    Text(fmtCurrency(value, currency), style: kStyleDisplay.copyWith(color: kWhite)),
    SizedBox(height: 4),
    Text('incl. MRR annualized', style: kStyleCaption.copyWith(color: Colors.white38)),
  ]),
)
```

---

## 2. ADD TND CURRENCY SUPPORT

### 2A. Update `lib/models/app_settings.dart`

Add `'TND'` to the supported currencies list:

```dart
static const List<String> supportedCurrencies = ['USD', 'EUR', 'GBP', 'NGN', 'TND', 'CAD'];
```

Change the default currency to `'TND'` for new installs:

```dart
@HiveField(1) String currency = 'TND';
```

### 2B. Update `lib/utils.dart` — `fmtCurrency` function

Add TND to the symbols map and handle its specific formatting rules:

```dart
String fmtCurrency(double amount, String currency) {
  // Currency symbol map
  final symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'NGN': '₦',
    'TND': 'DT',   // Tunisian Dinar — symbol "DT" placed AFTER the amount
    'CAD': 'CA\$',
  };

  // TND uses 3 decimal places (millimes) — e.g. "1,200.500 DT"
  // All other currencies use 0 decimal places
  if (currency == 'TND') {
    final formatted = NumberFormat('#,##0.###', 'en_US').format(amount);
    return '$formatted ${symbols['TND']}';   // symbol after amount, space-separated
  }

  final symbol = symbols[currency] ?? currency;
  return NumberFormat.currency(symbol: symbol, decimalDigits: 0).format(amount);
}
```

> **TND formatting rules:**
> - Symbol: **DT** (Dinar Tunisien), placed **after** the number with a space
> - Sub-unit: millimes (1 DT = 1000 millimes), so use up to 3 decimal places
> - Example: `1200.500 DT` or `85.000 DT`
> - For display in financial cards where space is tight, show 3 decimal places but trailing zeros after the first significant millime may be dropped (use `#,##0.###` pattern)

### 2C. Update Settings Screen — Currency Dropdown

The currency dropdown now includes TND as a first-class option. Display it as:

```dart
DropdownMenuItem(value: 'TND', child: Text('TND — Tunisian Dinar (DT)'))
```

### 2D. Update Seed Data Default

In `lib/seed_data.dart`, update `AppSettings` defaults so new installs show TND pricing:

```dart
// Seed data financial values remain the same numerically.
// The displayed currency will use TND formatting automatically
// once the default currency is set to 'TND' in AppSettings.
// No changes needed to seed monetary amounts.
```

---

## 3. SYSTEM UI UPDATE — `main.dart`

Update `SystemChrome.setSystemUIOverlayStyle` for the light theme:

```dart
// BEFORE (dark theme — light icons)
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.light,
));

// AFTER (light theme — dark icons)
SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.light,          // iOS
  statusBarIconBrightness: Brightness.dark,        // Android
));
```

---

## 4. COMPLETE FILE LIST TO REGENERATE

Only regenerate these files. All other files are unchanged:

1. `lib/theme.dart` — full replacement per sections 1A–1O above
2. `lib/utils.dart` — update `fmtCurrency` function only (section 2B)
3. `lib/models/app_settings.dart` — add TND, change default (section 2A)
4. `lib/seed_data.dart` — no code changes, but default currency now TND (section 2D)
5. `main.dart` — update `SystemUiOverlayStyle` only (section 3)

---

## 5. CHECKLIST — VERIFY BEFORE SUBMITTING

- [ ] Font is `Space Grotesk` everywhere — no Playfair Display, no DM Sans
- [ ] Background is light (`kSurface = #f2f3f5`), NOT dark
- [ ] Primary button is solid black (`kBlack`), not purple or lime
- [ ] `kLime` (#c9f158) is used for: active nav, progress bars (on-track), quick-action pills, selected states
- [ ] `kPurple` constant does NOT exist — all old usages replaced with `kLime`
- [ ] `AmbientBackground` widget is deleted — no glow effects anywhere
- [ ] `SystemUiOverlayStyle` uses `Brightness.dark` for icons (light bg requires dark icons)
- [ ] TND is in `supportedCurrencies` list in `AppSettings`
- [ ] TND default currency is set for new installs
- [ ] `fmtCurrency('TND')` places symbol AFTER the number: `"1,200.500 DT"` not `"DT1,200"`
- [ ] `fmtCurrency('TND')` uses up to 3 decimal places
- [ ] Card shadows use `0x08000000` (very subtle black, not colored)
- [ ] All card border radii updated to 20 (was 18)
- [ ] Input field border radii updated to 14 (was 12)
- [ ] Bottom nav background is `kWhite`, not transparent/blurred
- [ ] Avatar background opacity reduced to 15% (was 20%) for light theme legibility
- [ ] Progress bar track background is `kBgCardAlt` (light grey), not `kBorder`
- [ ] Finance hero card uses solid `kBlack` background, not a gradient
