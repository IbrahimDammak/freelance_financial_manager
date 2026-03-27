import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kLime = Color(0xFFc9f158);
const Color kBlack = Color(0xFF202020);
const Color kWhite = Color(0xFFffffff);
const Color kSurface = Color(0xFFf2f3f5);

const Color kBg = kSurface;
const Color kBgCard = kWhite;
const Color kBgCardAlt = Color(0xFFf7f8fa);

const Color kGreen = Color(0xFF22c55e);
const Color kYellow = Color(0xFFf59e0b);
const Color kOrange = Color(0xFFf97316);
const Color kRed = Color(0xFFef4444);
const Color kBlue = Color(0xFF3b82f6);

const Color kTextPrimary = Color(0xFF202020);
const Color kTextSecondary = Color(0xFF6b7280);
const Color kTextMuted = Color(0xFFa1a9b4);

const Color kBorder = Color(0xFFe8eaed);
const Color kBorderStrong = Color(0xFFd1d5db);

const Color kPink = Color(0xFFec4899);

final TextStyle kStyleHeading = GoogleFonts.spaceGrotesk(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  color: kTextPrimary,
);
final TextStyle kStyleHeadingSm = GoogleFonts.spaceGrotesk(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  color: kTextPrimary,
);
final TextStyle kStyleLabel = GoogleFonts.spaceGrotesk(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 1.5,
  color: kTextMuted,
);
final TextStyle kStyleBody = GoogleFonts.spaceGrotesk(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: kTextSecondary,
);
final TextStyle kStyleBodyBold = GoogleFonts.spaceGrotesk(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: kTextPrimary,
);
final TextStyle kStyleTimer = GoogleFonts.spaceGrotesk(
  fontSize: 24,
  fontWeight: FontWeight.w800,
  color: kTextPrimary,
  fontFeatures: const [FontFeature.tabularFigures()],
);
final TextStyle kStyleCaption = GoogleFonts.spaceGrotesk(
  fontSize: 11,
  fontWeight: FontWeight.w400,
  color: kTextMuted,
);

final TextStyle kStyleDisplay = GoogleFonts.spaceGrotesk(
  fontSize: 36,
  fontWeight: FontWeight.w700,
  color: kTextPrimary,
);

final TextStyle kStyleButton = GoogleFonts.spaceGrotesk(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: kBlack,
);

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
          ? const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ]
          : null,
    );

BoxDecoration kInputDecorationBox = BoxDecoration(
  color: kBgCardAlt,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: kBorder),
);

ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: kSurface,
  colorScheme: const ColorScheme.light(
    primary: kBlack,
    secondary: kLime,
    surface: kWhite,
    error: kRed,
    onPrimary: kWhite,
    onSecondary: kBlack,
    onSurface: kTextPrimary,
  ),
  textTheme:
      GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme).apply(
    bodyColor: kTextPrimary,
    displayColor: kTextPrimary,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: GoogleFonts.spaceGrotesk(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: kTextPrimary,
    ),
    iconTheme: const IconThemeData(color: kTextPrimary),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kBgCardAlt,
    labelStyle: GoogleFonts.spaceGrotesk(
      fontSize: 11,
      letterSpacing: 1.5,
      color: kTextMuted,
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
    selectedLabelStyle: TextStyle(
      fontSize: 10,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w700,
    ),
    unselectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 0.5),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kBlack,
      foregroundColor: kWhite,
      textStyle: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(0, 52),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kTextPrimary,
      side: const BorderSide(color: kBorder, width: 1),
      textStyle: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minimumSize: const Size(0, 48),
    ),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: kWhite,
    titleTextStyle: GoogleFonts.spaceGrotesk(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: kTextPrimary,
    ),
    contentTextStyle:
        GoogleFonts.spaceGrotesk(fontSize: 14, color: kTextSecondary),
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

const List<Color> kAvatarColors = [
  Color(0xFFfbbf24),
  Color(0xFF34d399),
  Color(0xFF60a5fa),
  Color(0xFFf472b6),
  Color(0xFFa78bfa),
  Color(0xFFfb923c),
  Color(0xFF4ade80),
];

Color avatarColorFor(String name) {
  var hash = 0;
  for (final rune in name.runes) {
    hash = (hash * 31 + rune) % kAvatarColors.length;
  }
  return kAvatarColors[hash];
}
