import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/difficulty.dart';
import '../models/high_score.dart';

/// Marcadores por dificultad, guardados como JSON en almacenamiento local.
class HighScoreRepository {
  HighScoreRepository(this._prefs);

  final SharedPreferences _prefs;

  static String _key(Difficulty difficulty) => 'highscores.${difficulty.name}';

  DifficultyRecords load(Difficulty difficulty) {
    final raw = _prefs.getString(_key(difficulty));
    if (raw == null) return DifficultyRecords.empty;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return DifficultyRecords.fromJson(decoded);
      }
    } on FormatException {
      // Dato corrupto: se ignora y se trata como si no hubiera récords.
    } on TypeError {
      // Estructura inesperada (por ejemplo, de una versión anterior).
    }
    return DifficultyRecords.empty;
  }

  Map<Difficulty, DifficultyRecords> loadAll() => {
    for (final difficulty in Difficulty.values) difficulty: load(difficulty),
  };

  bool get hasAnyRecord =>
      Difficulty.values.any((difficulty) => !load(difficulty).isEmpty);

  /// Registra una victoria y devuelve qué récords se superaron.
  Future<RecordUpdate> submitWin(Difficulty difficulty, ScoreEntry entry) async {
    final current = load(difficulty);
    final bestTime = current.bestTime;
    final fewestMoves = current.fewestMoves;
    final newBestTime = bestTime == null || entry.isFasterThan(bestTime);
    final newFewestMoves =
        fewestMoves == null || entry.hasFewerMovesThan(fewestMoves);

    final updated = DifficultyRecords(
      bestTime: newBestTime ? entry : bestTime,
      fewestMoves: newFewestMoves ? entry : fewestMoves,
      gamesWon: current.gamesWon + 1,
    );
    await _prefs.setString(_key(difficulty), jsonEncode(updated.toJson()));

    return RecordUpdate(
      newBestTime: newBestTime,
      newFewestMoves: newFewestMoves,
      isFirstWin: current.gamesWon == 0,
    );
  }

  Future<void> clearAll() async {
    for (final difficulty in Difficulty.values) {
      await _prefs.remove(_key(difficulty));
    }
  }
}
