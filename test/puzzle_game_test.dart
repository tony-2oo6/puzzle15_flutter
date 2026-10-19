import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15_flutter/logic/puzzle_board.dart';
import 'package:puzzle15_flutter/logic/puzzle_game.dart';
import 'package:puzzle15_flutter/models/difficulty.dart';

/// Tablero a un movimiento de resolverse (pieza 8 a la derecha del hueco).
PuzzleBoard _oneMoveFromSolved() =>
    PuzzleBoard.fromTiles(3, [1, 2, 3, 4, 5, 6, 7, 0, 8]);

/// Cronómetro controlable para probar el tiempo sin esperas reales.
class _FakeStopwatch implements Stopwatch {
  Duration _elapsed = Duration.zero;
  bool _running = false;

  void advance(Duration duration) {
    if (_running) _elapsed += duration;
  }

  @override
  Duration get elapsed => _elapsed;
  @override
  bool get isRunning => _running;
  @override
  void start() => _running = true;
  @override
  void stop() => _running = false;
  @override
  void reset() => _elapsed = Duration.zero;
  @override
  int get elapsedMicroseconds => _elapsed.inMicroseconds;
  @override
  int get elapsedMilliseconds => _elapsed.inMilliseconds;
  @override
  int get elapsedTicks => _elapsed.inMicroseconds;
  @override
  int get frequency => 1000000;
}

void main() {
  test('empieza listo, sin movimientos y con el cronómetro detenido', () {
    final watch = _FakeStopwatch();
    final game = PuzzleGame(
      difficulty: Difficulty.easy,
      initialBoard: _oneMoveFromSolved(),
      stopwatch: watch,
    );
    expect(game.status, GameStatus.ready);
    expect(game.moves, 0);
    expect(watch.isRunning, isFalse);
  });

  test('el primer movimiento arranca el cronómetro', () {
    final watch = _FakeStopwatch();
    final game = PuzzleGame(
      difficulty: Difficulty.easy,
      initialBoard: PuzzleBoard.fromTiles(3, [1, 2, 3, 4, 5, 6, 0, 7, 8]),
      stopwatch: watch,
    );
    expect(game.tryMove(7), 1);
    expect(game.status, GameStatus.playing);
    expect(watch.isRunning, isTrue);
    expect(game.moves, 1);
  });

  test('un movimiento inválido no cuenta ni arranca el reloj', () {
    final watch = _FakeStopwatch();
    final game = PuzzleGame(
      difficulty: Difficulty.easy,
      initialBoard: _oneMoveFromSolved(),
      stopwatch: watch,
    );
    expect(game.tryMove(0), 0);
    expect(game.moves, 0);
    expect(game.status, GameStatus.ready);
    expect(watch.isRunning, isFalse);
  });

  test('detecta la victoria y detiene el cronómetro', () {
    final watch = _FakeStopwatch();
    final game = PuzzleGame(
      difficulty: Difficulty.easy,
      initialBoard: _oneMoveFromSolved(),
      stopwatch: watch,
    );
    game.tryMove(8);
    expect(game.status, GameStatus.won);
    expect(game.isFinished, isTrue);
    expect(watch.isRunning, isFalse);
    // Tras ganar no se aceptan más movimientos.
    expect(game.tryMove(7), 0);
  });

  test('la pausa bloquea movimientos y detiene el tiempo', () {
    final watch = _FakeStopwatch();
    final game = PuzzleGame(
      difficulty: Difficulty.easy,
      initialBoard: PuzzleBoard.fromTiles(3, [1, 2, 3, 4, 5, 6, 0, 7, 8]),
      stopwatch: watch,
    );
    game.tryMove(7);
    watch.advance(const Duration(seconds: 5));
    game.pause();
    expect(game.status, GameStatus.paused);
    watch.advance(const Duration(seconds: 30));
    expect(game.elapsed, const Duration(seconds: 5));
    expect(game.tryMove(8), 0);
    game.resume();
    expect(game.status, GameStatus.playing);
  });

  test('en contrarreloj se pierde al agotarse el tiempo', () {
    final watch = _FakeStopwatch();
    final game = PuzzleGame(
      difficulty: Difficulty.easy,
      timeLimit: const Duration(minutes: 1),
      initialBoard: PuzzleBoard.fromTiles(3, [1, 2, 3, 4, 5, 6, 0, 7, 8]),
      stopwatch: watch,
    );
    game.tryMove(7);
    watch.advance(const Duration(seconds: 59));
    expect(game.checkTimeUp(), isFalse);
    expect(game.remaining, const Duration(seconds: 1));
    watch.advance(const Duration(seconds: 2));
    expect(game.checkTimeUp(), isTrue);
    expect(game.status, GameStatus.lost);
    expect(game.lossReason, LossReason.timeUp);
    expect(game.remaining, Duration.zero);
    expect(game.elapsed, const Duration(minutes: 1));
  });

  test('rendirse termina la partida como derrota', () {
    final game = PuzzleGame(
      difficulty: Difficulty.easy,
      initialBoard: _oneMoveFromSolved(),
      stopwatch: _FakeStopwatch(),
    );
    game.surrender();
    expect(game.status, GameStatus.lost);
    expect(game.lossReason, LossReason.surrendered);
  });

  test('reiniciar genera un tablero nuevo y limpia el estado', () {
    final watch = _FakeStopwatch();
    final game = PuzzleGame(
      difficulty: Difficulty.medium,
      stopwatch: watch,
    );
    final blank = game.board.blankIndex;
    final neighbour = game.board.indexForDirection(MoveDirection.up) ??
        game.board.indexForDirection(MoveDirection.down)!;
    expect(neighbour, isNot(blank));
    game.tryMove(neighbour);
    watch.advance(const Duration(seconds: 3));
    game.restart();
    expect(game.moves, 0);
    expect(game.status, GameStatus.ready);
    expect(game.elapsed, Duration.zero);
    expect(game.board.size, 4);
    expect(PuzzleBoard.isSolvable(game.board.tiles, 4), isTrue);
  });
}
