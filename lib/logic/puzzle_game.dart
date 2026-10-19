import 'dart:math';

import '../models/difficulty.dart';
import 'puzzle_board.dart';

/// Estados posibles de una partida.
enum GameStatus {
  /// Tablero listo; el cronómetro aún no arranca.
  ready,

  /// Partida en curso, cronómetro corriendo.
  playing,

  /// Partida en pausa (botón de pausa o app en segundo plano).
  paused,

  /// Todas las piezas en su lugar.
  won,

  /// Se agotó el tiempo (contrarreloj) o el jugador se rindió.
  lost,
}

/// Motivo por el que se perdió una partida.
enum LossReason { timeUp, surrendered }

/// Reglas de una partida: tablero, contador de movimientos, cronómetro y
/// transiciones de estado. No depende de Flutter, así que se prueba con
/// tests unitarios y la UI solo refleja su estado con `setState`.
class PuzzleGame {
  PuzzleGame({
    required this.difficulty,
    this.timeLimit,
    Random? random,
    PuzzleBoard? initialBoard,
    Stopwatch? stopwatch,
  }) : assert(
         initialBoard == null || initialBoard.size == difficulty.size,
         'El tablero inicial no coincide con la dificultad',
       ),
       _random = random ?? Random(),
       _stopwatch = stopwatch ?? Stopwatch(),
       _board =
           initialBoard ??
           PuzzleBoard.shuffled(difficulty.size, random: random);

  final Difficulty difficulty;

  /// Tiempo máximo (modo contrarreloj). `null` = modo clásico sin límite.
  final Duration? timeLimit;

  final Random _random;
  final Stopwatch _stopwatch;
  PuzzleBoard _board;
  int _moves = 0;
  GameStatus _status = GameStatus.ready;
  LossReason? _lossReason;

  PuzzleBoard get board => _board;
  int get moves => _moves;
  GameStatus get status => _status;
  LossReason? get lossReason => _lossReason;
  bool get isTimed => timeLimit != null;

  /// Tiempo jugado. En contrarreloj nunca supera el límite.
  Duration get elapsed {
    final limit = timeLimit;
    final value = _stopwatch.elapsed;
    if (limit != null && value > limit) return limit;
    return value;
  }

  /// Tiempo restante en contrarreloj (`null` en modo clásico).
  Duration? get remaining {
    final limit = timeLimit;
    if (limit == null) return null;
    final left = limit - _stopwatch.elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isFinished =>
      _status == GameStatus.won || _status == GameStatus.lost;

  /// `true` si hay progreso que se perdería al salir o reiniciar.
  bool get isInProgress =>
      _moves > 0 &&
      (_status == GameStatus.playing || _status == GameStatus.paused);

  /// Intenta mover la pieza en [index]. Devuelve cuántas piezas se movieron.
  /// El primer movimiento válido arranca el cronómetro.
  int tryMove(int index) {
    if (isFinished || _status == GameStatus.paused) return 0;
    final moved = _board.move(index);
    if (moved == 0) return 0;
    _registerMove(moved);
    return moved;
  }

  /// Igual que [tryMove] pero indicando una dirección (teclado o gesto).
  int tryMoveInDirection(MoveDirection direction) {
    final index = _board.indexForDirection(direction);
    return index == null ? 0 : tryMove(index);
  }

  void _registerMove(int moved) {
    if (_status == GameStatus.ready) {
      _status = GameStatus.playing;
      _stopwatch.start();
    }
    _moves += moved;
    if (_board.isSolved) {
      _stopwatch.stop();
      _status = GameStatus.won;
    }
  }

  void pause() {
    if (_status != GameStatus.playing) return;
    _stopwatch.stop();
    _status = GameStatus.paused;
  }

  void resume() {
    if (_status != GameStatus.paused) return;
    _stopwatch.start();
    _status = GameStatus.playing;
  }

  /// Comprueba el límite de tiempo. Devuelve `true` si la partida acaba de
  /// perderse por tiempo.
  bool checkTimeUp() {
    final limit = timeLimit;
    if (limit == null || _status != GameStatus.playing) return false;
    if (_stopwatch.elapsed < limit) return false;
    _stopwatch.stop();
    _status = GameStatus.lost;
    _lossReason = LossReason.timeUp;
    return true;
  }

  /// El jugador abandona la partida actual.
  void surrender() {
    if (isFinished) return;
    _stopwatch.stop();
    _status = GameStatus.lost;
    _lossReason = LossReason.surrendered;
  }

  /// Nueva partida con un tablero distinto en la misma dificultad.
  void restart() {
    _board = PuzzleBoard.shuffled(difficulty.size, random: _random);
    _moves = 0;
    _status = GameStatus.ready;
    _lossReason = null;
    _stopwatch
      ..stop()
      ..reset();
  }
}
