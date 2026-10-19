/// Niveles de dificultad disponibles. Cada nivel define el tamaño de la
/// cuadrícula y el tiempo límite usado en el modo contrarreloj.
enum Difficulty {
  easy(
    size: 3,
    label: 'Fácil',
    tagline: 'Ideal para empezar',
    timeLimit: Duration(minutes: 3),
  ),
  medium(
    size: 4,
    label: 'Medio',
    tagline: 'El 15-puzzle clásico',
    timeLimit: Duration(minutes: 8),
  ),
  hard(
    size: 5,
    label: 'Difícil',
    tagline: 'Para mentes pacientes',
    timeLimit: Duration(minutes: 15),
  );

  const Difficulty({
    required this.size,
    required this.label,
    required this.tagline,
    required this.timeLimit,
  });

  /// Número de filas (y de columnas) del tablero.
  final int size;

  /// Nombre visible para el usuario.
  final String label;

  /// Frase corta que describe el nivel.
  final String tagline;

  /// Tiempo máximo para resolver el tablero en modo contrarreloj.
  final Duration timeLimit;

  /// Número de piezas (sin contar el espacio vacío).
  int get tileCount => size * size - 1;

  /// Texto del tamaño de la cuadrícula, por ejemplo `4×4`.
  String get gridLabel => '$size×$size';

  /// Descripción compacta: `4×4 · 15 piezas`.
  String get summary => '$gridLabel · $tileCount piezas';

  /// Convierte el nombre guardado en disco al valor del enum.
  static Difficulty fromName(
    String? name, {
    Difficulty fallback = Difficulty.medium,
  }) {
    return Difficulty.values.firstWhere(
      (difficulty) => difficulty.name == name,
      orElse: () => fallback,
    );
  }
}
