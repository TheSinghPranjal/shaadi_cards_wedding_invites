import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.maroon,
      primary: AppColors.maroon,
      onPrimary: AppColors.ivory,
      secondary: AppColors.gold,
      onSecondary: AppColors.charcoal,
      surface: AppColors.ivory,
      onSurface: AppColors.charcoal,
      error: AppColors.error,
    );

    final textTheme = _textTheme(AppColors.charcoal);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ivory,
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.fallback,
      textTheme: textTheme,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.maroon,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.maroon),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          foregroundColor: AppColors.maroon,
          side: const BorderSide(color: AppColors.maroon),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.maroon,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.maroon,
        labelStyle: textTheme.labelMedium,
        side: const BorderSide(color: AppColors.ivoryDeep),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: const BorderSide(color: AppColors.ivoryDeep),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: const BorderSide(color: AppColors.ivoryDeep),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.ivory,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    TextStyle display(double size, FontWeight weight) => TextStyle(
          fontFamily: AppFonts.display,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: size,
          fontWeight: weight,
          color: AppColors.maroon,
          height: 1.2,
        );
    TextStyle ui(double size, FontWeight weight) => TextStyle(
          fontFamily: AppFonts.ui,
          fontFamilyFallback: AppFonts.fallback,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.4,
        );

    return TextTheme(
      displayLarge: display(44, FontWeight.w700),
      displayMedium: display(36, FontWeight.w700),
      displaySmall: display(30, FontWeight.w600),
      headlineLarge: display(28, FontWeight.w700),
      headlineMedium: display(24, FontWeight.w600),
      headlineSmall: display(21, FontWeight.w600),
      titleLarge: display(20, FontWeight.w600),
      titleMedium: ui(16, FontWeight.w600),
      titleSmall: ui(14, FontWeight.w600),
      bodyLarge: ui(16, FontWeight.w400),
      bodyMedium: ui(14, FontWeight.w400),
      bodySmall: ui(12, FontWeight.w400).copyWith(color: AppColors.muted),
      labelLarge: ui(15, FontWeight.w600),
      labelMedium: ui(13, FontWeight.w500),
      labelSmall: ui(11, FontWeight.w500),
    );
  }
}
