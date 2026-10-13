import 'package:flutter/material.dart';

/// Lunara design tokens — taken from the Figma "01 · Foundations" page.
class LColors {
  static const ivory = Color(0xFFFBF7F2); // Background
  static const plum = Color(0xFF49334F); // Text, buttons
  static const lavender = Color(0xFFDCD5F4); // Secondary surfaces, AI
  static const rose = Color(0xFFD99AA7); // Subtle accents
  static const sage = Color(0xFFC7D6C1); // Completed states
  static const white = Color(0xFFFFFFFF); // Cards, inputs
  static const textSecondary = Color(0xFF77717A);
  static const border = Color(0xFFECE5EA);
  static const lavender50 = Color(0xFFF4F1FC); // Icon tiles
  static const rose50 = Color(0xFFF9ECEF); // Accent tiles
  static const checkboxBorder = Color(0x5949334F); // plum @ 35%
  static const sageNote = Color(0x73C7D6C1); // sage @ 45%
  static const previewWhite = Color(0x99FFFFFF); // white @ 60%
  static const scrim = Color(0x6649334F);
}

/// Radius scale: 12 tiles · 16 cards · 20 AI cards · 28 sheets · pill buttons.
class LRadius {
  static const tile = 12.0;
  static const card = 16.0;
  static const aiCard = 20.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

class LShadows {
  /// Shadow/Card
  static const card = [
    BoxShadow(color: Color(0x0D49334F), offset: Offset(0, 1), blurRadius: 3),
    BoxShadow(color: Color(0x0D49334F), offset: Offset(0, 8), blurRadius: 24, spreadRadius: -6),
  ];

  /// Lighter drop shadow used on habit + metric cards.
  static const habit = [
    BoxShadow(color: Color(0x0D49334F), offset: Offset(0, 1), blurRadius: 1.5),
    BoxShadow(color: Color(0x0D49334F), offset: Offset(0, 8), blurRadius: 12),
  ];
}

/// Text styles — names match the Figma text styles.
class LText {
  static const _sans = 'DMSans';
  static const _serif = 'CormorantGaramond';

  static TextStyle _s(double size, FontWeight w, double lh, {Color color = LColors.plum, double ls = 0}) =>
      TextStyle(fontFamily: _sans, fontSize: size, fontWeight: w, height: lh / size, color: color, letterSpacing: ls);

  static const displaySerif32 = TextStyle(
      fontFamily: _serif, fontSize: 32, fontWeight: FontWeight.w600, height: 38 / 32, letterSpacing: -0.32, color: LColors.plum);
  static const headingSerif24 =
      TextStyle(fontFamily: _serif, fontSize: 24, fontWeight: FontWeight.w600, height: 30 / 24, color: LColors.plum);

  static final title18 = _s(18, FontWeight.w600, 24);
  static final title16 = _s(16, FontWeight.w600, 22);
  static final button14 = _s(14, FontWeight.w600, 20, color: LColors.white);
  static final body16Medium = _s(16, FontWeight.w500, 22);
  static final body16 = _s(16, FontWeight.w400, 24);
  static final body14 = _s(14, FontWeight.w400, 20);
  static final body14Medium = _s(14, FontWeight.w500, 20);
  static final caption13 = _s(13, FontWeight.w400, 18, color: LColors.textSecondary);
  static final label12 = _s(12, FontWeight.w500, 16);
  static final overline12 = _s(12, FontWeight.w600, 16, color: LColors.textSecondary, ls: 0.96);
  static final nav11 = _s(11, FontWeight.w500, 14);
  static final number28 = _s(28, FontWeight.w700, 32, ls: -0.28);
}

ThemeData buildLunaraTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'DMSans',
    scaffoldBackgroundColor: LColors.ivory,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LColors.plum,
      primary: LColors.plum,
      surface: LColors.white,
    ),
    splashFactory: InkRipple.splashFactory,
  );
  return base.copyWith(
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: LColors.plum,
      selectionColor: LColors.lavender,
      selectionHandleColor: LColors.plum,
    ),
  );
}
