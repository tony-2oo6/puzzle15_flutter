import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15_flutter/controllers/settings_controller.dart';
import 'package:puzzle15_flutter/data/high_score_repository.dart';
import 'package:puzzle15_flutter/data/settings_repository.dart';
import 'package:puzzle15_flutter/models/app_theme_preference.dart';
import 'package:puzzle15_flutter/models/difficulty.dart';
import 'package:puzzle15_flutter/models/high_score.dart';
import 'package:puzzle15_flutter/models/tile_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

ScoreEntry _entry(int seconds, int moves) => ScoreEntry(
  elapsedMs: seconds * 1000,
  moves: moves,
  date: DateTime(2026, 10, 17, 12, 30),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('HighScoreRepository', () {
    test('sin datos no hay récords', () async {
      final repo = HighScoreRepository(await SharedPreferences.getInstance());
      expect(repo.hasAnyRecord, isFalse);
      expect(repo.load(Difficulty.easy).isEmpty, isTrue);
    });

    test('la primera victoria establece ambos récords', () async {
      final repo = HighScoreRepository(await SharedPreferences.getInstance());
      final update = await repo.submitWin(Difficulty.easy, _entry(60, 40));
      expect(update.isNewRecord, isTrue);
      expect(update.isFirstWin, isTrue);
      final records = repo.load(Difficulty.easy);
      expect(records.bestTime?.elapsedMs, 60000);
      expect(records.fewestMoves?.moves, 40);
      expect(records.gamesWon, 1);
    });

    test('mejor tiempo y menos movimientos se guardan por separado', () async {
      final repo = HighScoreRepository(await SharedPreferences.getInstance());
      await repo.submitWin(Difficulty.medium, _entry(100, 80));

      final faster = await repo.submitWin(Difficulty.medium, _entry(90, 120));
      expect(faster.newBestTime, isTrue);
      expect(faster.newFewestMoves, isFalse);

      final fewer = await repo.submitWin(Difficulty.medium, _entry(200, 60));
      expect(fewer.newBestTime, isFalse);
      expect(fewer.newFewestMoves, isTrue);

      final worse = await repo.submitWin(Difficulty.medium, _entry(300, 300));
      expect(worse.isNewRecord, isFalse);

      final records = repo.load(Difficulty.medium);
      expect(records.bestTime?.elapsedMs, 90000);
      expect(records.bestTime?.moves, 120);
      expect(records.fewestMoves?.moves, 60);
      expect(records.gamesWon, 4);
      // Las otras dificultades no se ven afectadas.
      expect(repo.load(Difficulty.hard).isEmpty, isTrue);
    });

    test('los récords sobreviven a una nueva instancia y se pueden borrar', () async {
      final prefs = await SharedPreferences.getInstance();
      await HighScoreRepository(prefs).submitWin(Difficulty.hard, _entry(500, 400));

      final reopened = HighScoreRepository(prefs);
      expect(reopened.load(Difficulty.hard).bestTime?.moves, 400);
      expect(reopened.load(Difficulty.hard).bestTime?.date, DateTime(2026, 10, 17, 12, 30));

      await reopened.clearAll();
      expect(reopened.hasAnyRecord, isFalse);
    });

    test('un dato corrupto no rompe la app', () async {
      SharedPreferences.setMockInitialValues({'highscores.easy': '{no es json'});
      final repo = HighScoreRepository(await SharedPreferences.getInstance());
      expect(repo.load(Difficulty.easy).isEmpty, isTrue);
    });
  });

  group('SettingsController', () {
    test('usa valores por defecto la primera vez', () async {
      final controller = SettingsController(
        SettingsRepository(await SharedPreferences.getInstance()),
      );
      expect(controller.value.difficulty, Difficulty.medium);
      expect(controller.value.difficultyConfirmed, isFalse);
      expect(controller.value.themePreference, AppThemePreference.system);
    });

    test('persiste los cambios y notifica a los oyentes', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = SettingsController(SettingsRepository(prefs));
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setDifficulty(Difficulty.hard);
      await controller.setThemePreference(AppThemePreference.dark);
      await controller.setTileStyle(TileStyle.retro);
      await controller.setAnimationsEnabled(false);
      await controller.setSoundEnabled(false);
      await controller.setTimeAttackEnabled(true);
      expect(notifications, 6);

      final reloaded = SettingsRepository(prefs).load();
      expect(reloaded.difficulty, Difficulty.hard);
      expect(reloaded.difficultyConfirmed, isTrue);
      expect(reloaded.themePreference, AppThemePreference.dark);
      expect(reloaded.tileStyle, TileStyle.retro);
      expect(reloaded.animationsEnabled, isFalse);
      expect(reloaded.soundEnabled, isFalse);
      expect(reloaded.timeAttackEnabled, isTrue);

      await controller.resetToDefaults();
      expect(SettingsRepository(prefs).load().tileStyle, TileStyle.classic);
    });
  });
}
