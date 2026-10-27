import 'package:flutter/material.dart';

abstract final class AppColors {
  static const maroon = Color(0xFF7A1F2B);
  static const maroonDark = Color(0xFF5A1420);
  static const gold = Color(0xFFC9A24A);
  static const goldLight = Color(0xFFE9D59C);
  static const ivory = Color(0xFFFBF6EE);
  static const ivoryDeep = Color(0xFFF3EADB);
  static const charcoal = Color(0xFF2B2B2B);
  static const muted = Color(0xFF6E6862);
  static const success = Color(0xFF2E7D4F);
  static const error = Color(0xFFB3261E);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  static const pagePadding = EdgeInsets.symmetric(horizontal: md);
}

abstract final class AppRadius {
  static const card = 16.0;
  static const chip = 24.0;
  static final cardBorder = BorderRadius.circular(card);
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(
      color: Color(0x1A7A1F2B),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];
}

abstract final class AppFonts {
  static const display = 'PlayfairDisplay';
  static const ui = 'Poppins';
  static const script = 'GreatVibes';
  static const devanagari = 'NotoSansDevanagari';

  /// Applied to every text style so Hindi input always renders.
  static const fallback = [devanagari];
}
