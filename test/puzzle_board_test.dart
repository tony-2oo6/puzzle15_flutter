import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle15_flutter/logic/puzzle_board.dart';

void main() {
  group('PuzzleBoard.solved', () {
    test('ordena las piezas y deja el hueco al final', () {
      final board = PuzzleBoard.solved(4);
      expect(board.tiles, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0]);
      expect(board.isSolved, isTrue);
      expect(board.correctTileCount, 15);
    });
  });

  group('isSolvable (paridad de inversiones)', () {
    test('el tablero resuelto es resoluble en 3×3, 4×4 y 5×5', () {
      for (final size in [3, 4, 5]) {
        expect(PuzzleBoard.isSolvable(PuzzleBoard.solved(size).tiles, size), isTrue);
      }
    });

    test('intercambiar dos piezas vuelve el tablero imposible', () {
      // Configuración clásica "14-15" de Sam Loyd: no tiene solución.
      const loyd = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 14, 0];
      expect(PuzzleBoard.isSolvable(loyd, 4), isFalse);

      const easySwap = [2, 1, 3, 4, 5, 6, 7, 8, 0];
      expect(PuzzleBoard.isSolvable(easySwap, 3), isFalse);
    });

    test('en ancho par importa la fila del hueco', () {
      // Mover el hueco una fila arriba (un movimiento legal) mantiene la
      // resolubilidad aunque cambie la paridad de inversiones.
      final board = PuzzleBoard.solved(4)..move(11);
      expect(PuzzleBoard.countInversions(board.tiles), isNot(0));
      expect(PuzzleBoard.isSolvable(board.tiles, 4), isTrue);
    });

    test('cuenta inversiones ignorando el hueco', () {
      expect(PuzzleBoard.countInversions([1, 2, 3, 4, 5, 6, 7, 8, 0]), 0);
      expect(PuzzleBoard.countInversions([8, 7, 6, 5, 4, 3, 2, 1, 0]), 28);
      expect(PuzzleBoard.countInversions([0, 2, 1]), 1);
    });
  });

  group('PuzzleBoard.shuffled', () {
    test('siempre genera tableros resolubles y desordenados', () {
      final random = Random(42);
      for (final size in [3, 4, 5]) {
        for (var i = 0; i < 300; i++) {
          final board = PuzzleBoard.shuffled(size, random: random);
          expect(PuzzleBoard.isSolvable(board.tiles, size), isTrue);
          expect(board.isSolved, isFalse);
          expect(board.tiles.toSet().length, size * size);
        }
      }
    });

    test('un tablero de 3×3 barajado se puede resolver (búsqueda BFS)', () {
      final random = Random(7);
      for (var i = 0; i < 5; i++) {
        final board = PuzzleBoard.shuffled(3, random: random);
        expect(_isReachableFromSolved(board.tiles), isTrue);
      }
    });
  });

  group('movimientos', () {
    test('mueve una pieza adyacente al hueco', () {
      final board = PuzzleBoard.solved(3);
      expect(board.canMove(7), isTrue); // la pieza 8, a la izquierda del hueco
      expect(board.move(7), 1);
      expect(board.tiles, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      expect(board.isSolved, isFalse);
    });

    test('rechaza piezas fuera de la fila o columna del hueco', () {
      final board = PuzzleBoard.solved(3);
      expect(board.canMove(0), isFalse);
      expect(board.move(0), 0);
      expect(board.move(8), 0); // el propio hueco
      expect(board.move(-1), 0);
      expect(board.isSolved, isTrue);
    });

    test('desliza toda la fila al tocar una pieza lejana', () {
      final board = PuzzleBoard.solved(4);
      expect(board.move(12), 3); // pieza 13 en la misma fila que el hueco
      expect(board.tiles.sublist(12), [0, 13, 14, 15]);
    });

    test('desliza toda la columna', () {
      final board = PuzzleBoard.solved(3);
      expect(board.move(2), 2);
      expect(board.tiles, [1, 2, 0, 4, 5, 3, 7, 8, 6]);
    });

    test('mover y deshacer devuelve el tablero resuelto', () {
      final board = PuzzleBoard.solved(3)..move(7);
      expect(board.isSolved, isFalse);
      board.move(8);
      expect(board.isSolved, isTrue);
    });

    test('direcciones de teclado y gestos', () {
      final board = PuzzleBoard.solved(3);
      // Hueco abajo a la derecha: no hay pieza debajo ni a la derecha.
      expect(board.indexForDirection(MoveDirection.up), isNull);
      expect(board.indexForDirection(MoveDirection.left), isNull);
      expect(board.indexForDirection(MoveDirection.down), 5);
      expect(board.indexForDirection(MoveDirection.right), 7);
      expect(board.moveInDirection(MoveDirection.down), 1);
      expect(board.tiles, [1, 2, 3, 4, 5, 0, 7, 8, 6]);
    });
  });

  test('fromTiles valida la permutación', () {
    expect(() => PuzzleBoard.fromTiles(3, [1, 2, 3]), throwsArgumentError);
    expect(
      () => PuzzleBoard.fromTiles(3, [1, 1, 2, 3, 4, 5, 6, 7, 0]),
      throwsArgumentError,
    );
    expect(PuzzleBoard.fromTiles(3, [1, 2, 3, 4, 5, 6, 7, 8, 0]).isSolved, isTrue);
  });
}

/// Comprueba con BFS que [tiles] es alcanzable desde el tablero resuelto
/// de 3×3 (181 440 estados como máximo).
bool _isReachableFromSolved(List<int> tiles) {
  final target = tiles.join(',');
  final start = PuzzleBoard.solved(3);
  final seen = <String>{start.tiles.join(',')};
  final queue = <PuzzleBoard>[start];
  var head = 0;
  while (head < queue.length) {
    final current = queue[head++];
    final key = current.tiles.join(',');
    if (key == target) return true;
    for (final direction in MoveDirection.values) {
      final next = current.copy();
      if (next.moveInDirection(direction) == 0) continue;
      if (seen.add(next.tiles.join(','))) queue.add(next);
    }
  }
  return false;
}
