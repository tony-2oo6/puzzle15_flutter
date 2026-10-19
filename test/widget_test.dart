import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:puzzle15_flutter/controllers/settings_controller.dart';
import 'package:puzzle15_flutter/data/high_score_repository.dart';
import 'package:puzzle15_flutter/data/settings_repository.dart';
import 'package:puzzle15_flutter/main.dart';

void main() {
  testWidgets('El menú principal se muestra al iniciar', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.animations': false});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      PuzzleApp(
        settings: SettingsController(SettingsRepository(prefs)),
        highScores: HighScoreRepository(prefs),
      ),
    );
    await tester.pump();

    expect(find.text('15 Puzzle'), findsOneWidget);
    expect(find.text('Jugar'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
