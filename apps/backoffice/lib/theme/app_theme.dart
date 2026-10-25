import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFFD7263D);
  static const fontFamily = 'Barlow';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

    // The backoffice is used with the keyboard, so whatever has the focus gets
    // a ring that can be seen from across the desk.
    final focusRing = WidgetStateProperty.resolveWith<BorderSide?>(
      (states) => states.contains(WidgetState.focused) ? BorderSide(color: scheme.tertiary, width: 3) : null,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      focusColor: scheme.primary.withValues(alpha: 0.25),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: ButtonStyle(side: focusRing)),
      outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(side: focusRing)),
      textButtonTheme: TextButtonThemeData(style: ButtonStyle(side: focusRing)),
      iconButtonTheme: IconButtonThemeData(style: ButtonStyle(side: focusRing)),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
