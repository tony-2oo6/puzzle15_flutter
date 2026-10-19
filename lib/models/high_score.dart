/// Resultado de una partida ganada.
class ScoreEntry {
  const ScoreEntry({
    required this.elapsedMs,
    required this.moves,
    required this.date,
  });

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    return ScoreEntry(
      elapsedMs: (json['elapsedMs'] as num).toInt(),
      moves: (json['moves'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  final int elapsedMs;
  final int moves;
  final DateTime date;

  Duration get elapsed => Duration(milliseconds: elapsedMs);

  /// `true` si este resultado es más rápido que [other]. A igual tiempo,
  /// desempata el menor número de movimientos.
  bool isFasterThan(ScoreEntry other) {
    if (elapsedMs != other.elapsedMs) return elapsedMs < other.elapsedMs;
    return moves < other.moves;
  }

  /// `true` si este resultado usa menos movimientos que [other]. A igual
  /// número de movimientos, desempata el menor tiempo.
  bool hasFewerMovesThan(ScoreEntry other) {
    if (moves != other.moves) return moves < other.moves;
    return elapsedMs < other.elapsedMs;
  }

  Map<String, Object> toJson() => {
    'elapsedMs': elapsedMs,
    'moves': moves,
    'date': date.toIso8601String(),
  };
}

/// Récords guardados para una dificultad.
class DifficultyRecords {
  const DifficultyRecords({
    this.bestTime,
    this.fewestMoves,
    this.gamesWon = 0,
  });

  factory DifficultyRecords.fromJson(Map<String, dynamic> json) {
    ScoreEntry? read(String key) {
      final value = json[key];
      return value is Map<String, dynamic> ? ScoreEntry.fromJson(value) : null;
    }

    return DifficultyRecords(
      bestTime: read('bestTime'),
      fewestMoves: read('fewestMoves'),
      gamesWon: (json['gamesWon'] as num?)?.toInt() ?? 0,
    );
  }

  static const DifficultyRecords empty = DifficultyRecords();

  /// Partida con el mejor tiempo.
  final ScoreEntry? bestTime;

  /// Partida con menos movimientos.
  final ScoreEntry? fewestMoves;

  /// Total de partidas ganadas en esta dificultad.
  final int gamesWon;

  bool get isEmpty => bestTime == null && fewestMoves == null;

  Map<String, Object> toJson() {
    final best = bestTime;
    final fewest = fewestMoves;
    return {
      'bestTime': ?best?.toJson(),
      'fewestMoves': ?fewest?.toJson(),
      'gamesWon': gamesWon,
    };
  }
}

/// Indica qué récords mejoró una partida recién ganada.
class RecordUpdate {
  const RecordUpdate({
    required this.newBestTime,
    required this.newFewestMoves,
    required this.isFirstWin,
  });

  static const RecordUpdate none = RecordUpdate(
    newBestTime: false,
    newFewestMoves: false,
    isFirstWin: false,
  );

  final bool newBestTime;
  final bool newFewestMoves;
  final bool isFirstWin;

  bool get isNewRecord => newBestTime || newFewestMoves;
}
