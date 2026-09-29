import 'package:flutter/material.dart';

class CormexTheme {
  static const deep = Color(0xFF0B2025);
  static const petroleum = Color(0xFF123D43);
  static const forest = Color(0xFF326A5F);
  static const sage = Color(0xFFB6D6C8);
  static const ink = Color(0xFF172B2D);
  static const muted = Color(0xFF617476);
  static const canvas = Color(0xFFF4F7F5);
  static const border = Color(0xFFDDE7E3);
  static const pale = Color(0xFFEAF2EE);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: petroleum,
      primary: petroleum,
      secondary: forest,
      surface: Colors.white,
      onSurface: ink,
    ).copyWith(outline: border);

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      dividerColor: border,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: muted),
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: forest, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: petroleum,
          foregroundColor: Colors.white,
          disabledBackgroundColor: pale,
          disabledForegroundColor: muted,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: rounded,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: petroleum,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
          shape: rounded,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: petroleum,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: pale,
        selectedColor: sage,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        labelStyle: const TextStyle(
          color: petroleum,
          fontWeight: FontWeight.w600,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? forest
              : border,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deep,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.6,
          height: 1.1,
          color: deep,
        ),
        headlineMedium: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.18,
          color: deep,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
          color: deep,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: ink, height: 1.55),
        bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
