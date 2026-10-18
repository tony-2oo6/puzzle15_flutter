import 'dart:math';

/// Dirección en la que se desplaza una pieza hacia el espacio vacío.
enum MoveDirection { up, down, left, right }

/// Tablero del rompecabezas deslizante (lógica pura, sin dependencias de UI).
///
/// Las piezas se guardan en una lista plana de `size * size` posiciones,
/// recorrida de izquierda a derecha y de arriba hacia abajo. El valor `0`
/// representa el espacio vacío. El tablero está resuelto cuando contiene
/// `1, 2, …, n` seguido del `0` al final.
class PuzzleBoard {
  PuzzleBoard._(this.size, this._tiles);

  /// Tablero ordenado (estado objetivo).
  factory PuzzleBoard.solved(int size) {
    _checkSize(size);
    final count = size * size;
    return PuzzleBoard._(
      size,
      List<int>.generate(count, (i) => i == count - 1 ? 0 : i + 1),
    );
  }

  /// Crea un tablero a partir de una disposición concreta. Útil para pruebas
  /// y para restaurar partidas.
  factory PuzzleBoard.fromTiles(int size, List<int> tiles) {
    _checkSize(size);
    final count = size * size;
    if (tiles.length != count) {
      throw ArgumentError.value(tiles, 'tiles', 'Debe contener $count valores');
    }
    final sorted = [...tiles]..sort();
    for (var i = 0; i < count; i++) {
      if (sorted[i] != i) {
        throw ArgumentError.value(
          tiles,
          'tiles',
          'Debe ser una permutación de 0..${count - 1}',
        );
      }
    }
    return PuzzleBoard._(size, List<int>.of(tiles));
  }

  /// Genera un tablero desordenado al azar que **siempre** tiene solución.
  ///
  /// 1. Se baraja con Fisher–Yates (todas las permutaciones son equiprobables).
  /// 2. Se valida la paridad de inversiones con [isSolvable].
  /// 3. Si la permutación no tiene solución, se intercambian dos piezas que no
  ///    sean el hueco: una transposición cambia la paridad de las inversiones
  ///    sin mover el hueco, así que el tablero pasa a ser resoluble.
  /// 4. Se descartan tableros ya resueltos o casi ordenados.
  factory PuzzleBoard.shuffled(int size, {Random? random}) {
    _checkSize(size);
    final rng = random ?? Random();
    final count = size * size;
    final tiles = List<int>.generate(count, (i) => i);
    while (true) {
      _fisherYatesShuffle(tiles, rng);
      if (!isSolvable(tiles, size)) {
        _swapFirstTwoTiles(tiles);
      }
      final board = PuzzleBoard._(size, List<int>.of(tiles));
      final tooEasy = board.correctTileCount > (count - 1) ~/ 2;
      if (!board.isSolved && !tooEasy) return board;
    }
  }

  /// Número de filas y columnas.
  final int size;
  final List<int> _tiles;

  /// Número de piezas (sin el hueco).
  int get tileCount => size * size - 1;

  /// Copia inmutable de la disposición actual.
  List<int> get tiles => List<int>.unmodifiable(_tiles);

  int get blankIndex => _tiles.indexOf(0);

  int valueAt(int index) => _tiles[index];

  int indexOfValue(int value) => _tiles.indexOf(value);

  int rowOf(int index) => index ~/ size;

  int colOf(int index) => index % size;

  /// `true` si la pieza en [index] está en su posición final.
  bool isInCorrectPlace(int index) {
    final value = _tiles[index];
    return value != 0 && value == index + 1;
  }

  /// Cantidad de piezas que ya están en su sitio.
  int get correctTileCount {
    var count = 0;
    for (var i = 0; i < _tiles.length; i++) {
      if (isInCorrectPlace(i)) count++;
    }
    return count;
  }

  /// Condición de victoria: piezas en orden y hueco al final.
  bool get isSolved {
    for (var i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles.last == 0;
  }

  bool isAdjacentToBlank(int index) {
    final blank = blankIndex;
    final distance =
        (rowOf(index) - rowOf(blank)).abs() + (colOf(index) - colOf(blank)).abs();
    return distance == 1;
  }

  /// Una pieza puede moverse si está en la misma fila o columna que el hueco.
  /// Las adyacentes se mueven solas; las más lejanas empujan a toda la fila o
  /// columna (comportamiento habitual en los 15-puzzle comerciales).
  bool canMove(int index) {
    if (index < 0 || index >= _tiles.length) return false;
    final blank = blankIndex;
    if (index == blank) return false;
    return rowOf(index) == rowOf(blank) || colOf(index) == colOf(blank);
  }

  /// Mueve la pieza en [index] hacia el hueco y devuelve cuántas piezas se
  /// desplazaron (0 si el movimiento no es válido). Cada pieza desplazada
  /// cuenta como un movimiento.
  int move(int index) {
    if (!canMove(index)) return 0;
    final blank = blankIndex;
    final int step;
    if (rowOf(index) == rowOf(blank)) {
      step = index > blank ? 1 : -1;
    } else {
      step = index > blank ? size : -size;
    }
    var cursor = blank;
    var moved = 0;
    while (cursor != index) {
      _tiles[cursor] = _tiles[cursor + step];
      cursor += step;
      moved++;
    }
    _tiles[index] = 0;
    return moved;
  }

  /// Índice de la pieza que se movería en [direction] (teclado o gesto), o
  /// `null` si no hay ninguna. Por ejemplo, [MoveDirection.up] mueve hacia
  /// arriba la pieza que está debajo del hueco.
  int? indexForDirection(MoveDirection direction) {
    final blank = blankIndex;
    final row = rowOf(blank);
    final col = colOf(blank);
    return switch (direction) {
      MoveDirection.up => row + 1 < size ? blank + size : null,
      MoveDirection.down => row - 1 >= 0 ? blank - size : null,
      MoveDirection.left => col + 1 < size ? blank + 1 : null,
      MoveDirection.right => col - 1 >= 0 ? blank - 1 : null,
    };
  }

  /// Mueve una pieza en [direction]. Devuelve 1 si se movió, 0 si no.
  int moveInDirection(MoveDirection direction) {
    final index = indexForDirection(direction);
    return index == null ? 0 : move(index);
  }

  PuzzleBoard copy() => PuzzleBoard._(size, List<int>.of(_tiles));

  /// Número de inversiones: pares de piezas (sin contar el hueco) que
  /// aparecen en orden inverso al recorrer el tablero.
  static int countInversions(List<int> tiles) {
    final values = tiles.where((tile) => tile != 0).toList();
    var inversions = 0;
    for (var i = 0; i < values.length; i++) {
      for (var j = i + 1; j < values.length; j++) {
        if (values[i] > values[j]) inversions++;
      }
    }
    return inversions;
  }

  /// Criterio clásico de resolubilidad (paridad de inversiones):
  ///
  /// * Ancho impar (3×3, 5×5): resoluble si las inversiones son pares.
  /// * Ancho par (4×4): contando la fila del hueco desde abajo (empezando en
  ///   1), resoluble si `inversiones + filaDelHuecoDesdeAbajo` es impar.
  static bool isSolvable(List<int> tiles, int size) {
    final inversions = countInversions(tiles);
    if (size.isOdd) return inversions.isEven;
    final blankRowFromBottom = size - tiles.indexOf(0) ~/ size;
    return (inversions + blankRowFromBottom).isOdd;
  }

  static void _fisherYatesShuffle(List<int> list, Random rng) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  static void _swapFirstTwoTiles(List<int> tiles) {
    final first = tiles.indexWhere((tile) => tile != 0);
    final second = tiles.indexWhere((tile) => tile != 0, first + 1);
    final temp = tiles[first];
    tiles[first] = tiles[second];
    tiles[second] = temp;
  }

  static void _checkSize(int size) {
    if (size < 2) {
      throw ArgumentError.value(size, 'size', 'El tablero debe ser de 2×2 o más');
    }
  }
}
