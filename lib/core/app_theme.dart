import 'package:flutter/material.dart';

/// Tema visual de la app (claro y oscuro) con tipografías empaquetadas.
abstract final class AppTheme {
  static const Color seed = Color(0xFF5B4BDB);

  /// Color de acento cálido usado en el logo, récords y piezas destacadas.
  static const Color accent = Color(0xFFFF7A59);

  static const String bodyFont = 'Nunito';
  static const String displayFont = 'Fredoka';

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: bodyFont,
    );

    TextStyle? display(TextStyle? style, FontWeight weight) =>
        style?.copyWith(fontFamily: displayFont, fontWeight: weight);

    final textTheme = base.textTheme.copyWith(
      displayLarge: display(base.textTheme.displayLarge, FontWeight.w700),
      displayMedium: display(base.textTheme.displayMedium, FontWeight.w700),
      displaySmall: display(base.textTheme.displaySmall, FontWeight.w700),
      headlineLarge: display(base.textTheme.headlineLarge, FontWeight.w600),
      headlineMedium: display(base.textTheme.headlineMedium, FontWeight.w600),
      headlineSmall: display(base.textTheme.headlineSmall, FontWeight.w600),
      titleLarge: display(base.textTheme.titleLarge, FontWeight.w600),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    const buttonText = TextStyle(
      fontFamily: bodyFont,
      fontWeight: FontWeight.w700,
      fontSize: 16,
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape, textStyle: buttonText),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: bodyFont,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: const TooltipThemeData(
        textStyle: TextStyle(fontFamily: bodyFont, color: Colors.white),
      ),
    );
  }
}
