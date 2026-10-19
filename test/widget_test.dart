import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15_flutter/app.dart';
import 'package:puzzle15_flutter/controllers/settings_controller.dart';
import 'package:puzzle15_flutter/data/high_score_repository.dart';
import 'package:puzzle15_flutter/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _launchApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  // Animaciones apagadas para que las pruebas sean deterministas.
  SharedPreferences.setMockInitialValues({
    'settings.animations': false,
    ...prefs,
  });
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    PuzzleApp(
      settings: SettingsController(SettingsRepository(instance)),
      highScores: HighScoreRepository(instance),
    ),
  );
}

Future<void> _skipSplash(WidgetTester tester) async {
  await tester.tap(find.text('Saltar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el splash muestra el título y pasa solo al menú', (tester) async {
    await _launchApp(tester);
    expect(find.text('15-Puzzle Flutter'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.text('Jugar'), findsOneWidget);
    expect(find.text('Marcadores'), findsOneWidget);
    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Cómo jugar'), findsOneWidget);
  });

  testWidgets('Jugar pide la dificultad la primera vez y abre el tablero', (
    tester,
  ) async {
    await _launchApp(tester);
    await _skipSplash(tester);

    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige la dificultad'), findsOneWidget);

    await tester.tap(find.text('Fácil'));
    await tester.pumpAndSettle();
    expect(find.text('Fácil · 3×3'), findsOneWidget);
    expect(find.text('Movimientos'), findsOneWidget);
    // 8 piezas en el tablero de 3×3.
    expect(find.bySemanticsLabel(RegExp(r'^Pieza 8')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Pieza 9')), findsNothing);
  });

  testWidgets('con dificultad guardada, Jugar va directo al tablero', (
    tester,
  ) async {
    await _launchApp(
      tester,
      prefs: {'settings.difficulty': 'hard', 'settings.difficultyConfirmed': true},
    );
    await _skipSplash(tester);
    await tester.tap(find.text('Jugar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige la dificultad'), findsNothing);
    expect(find.text('Difícil · 5×5'), findsOneWidget);
  });

  testWidgets('marcadores vacíos muestran un mensaje amigable', (tester) async {
    await _launchApp(tester);
    await _skipSplash(tester);
    await tester.tap(find.text('Marcadores'));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay récords'), findsOneWidget);
    await tester.tap(find.text('Volver al menú principal'));
    await tester.pumpAndSettle();
    expect(find.text('Jugar'), findsOneWidget);
  });

  testWidgets('cambiar el tema en Configuración se aplica al instante', (
    tester,
  ) async {
    await _launchApp(tester);
    await _skipSplash(tester);
    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.theme'), 'dark');
    expect(find.text('Guardado'), findsOneWidget);

    // Deja expirar el aviso "Guardado" para no dejar temporizadores vivos.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
