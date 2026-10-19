import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'controllers/settings_controller.dart';
import 'data/high_score_repository.dart';
import 'data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Se cargan las preferencias antes de dibujar el primer frame para que la
  // app arranque ya con el tema y la configuración del usuario.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    PuzzleApp(
      settings: SettingsController(SettingsRepository(prefs)),
      highScores: HighScoreRepository(prefs),
    ),
  );
}
