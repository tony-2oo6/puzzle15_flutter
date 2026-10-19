import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/app_scope.dart';
import 'controllers/settings_controller.dart';
import 'core/app_theme.dart';
import 'data/high_score_repository.dart';
import 'data/settings_repository.dart';
import 'models/app_theme_preference.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    PuzzleApp(
      settings: SettingsController(SettingsRepository(prefs)),
      highScores: HighScoreRepository(prefs),
    ),
  );
}

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({
    super.key,
    required this.settings,
    required this.highScores,
  });

  final SettingsController settings;
  final HighScoreRepository highScores;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: settings,
      highScores: highScores,
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          title: '15 Puzzle',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: switch (settings.value.themePreference) {
            AppThemePreference.light => ThemeMode.light,
            AppThemePreference.dark => ThemeMode.dark,
            AppThemePreference.system => ThemeMode.system,
          },
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
