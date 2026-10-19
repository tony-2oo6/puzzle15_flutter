import 'package:flutter/material.dart';

import 'controllers/app_scope.dart';
import 'controllers/settings_controller.dart';
import 'core/app_theme.dart';
import 'data/high_score_repository.dart';
import 'models/app_theme_preference.dart';
import 'screens/splash_screen.dart';

/// Raíz de la aplicación. Escucha al [SettingsController] para aplicar el
/// tema elegido (claro, oscuro o automático) en cuanto cambia.
class PuzzleApp extends StatelessWidget {
  const PuzzleApp({
    super.key,
    required this.settings,
    required this.highScores,
  });

  final SettingsController settings;
  final HighScoreRepository highScores;

  static ThemeMode _themeModeFor(AppThemePreference preference) =>
      switch (preference) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: settings,
      highScores: highScores,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final value = settings.value;
          return MaterialApp(
            title: '15-Puzzle Flutter',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeModeFor(value.themePreference),
            themeAnimationDuration: value.animationsEnabled
                ? kThemeAnimationDuration
                : Duration.zero,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
