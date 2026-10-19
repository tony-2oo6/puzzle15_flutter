/// Estilos de visualización de las piezas del tablero.
enum TileStyle {
  classic(label: 'Clásico', description: 'Números sobre fichas sobrias'),
  colorful(label: 'Colorido', description: 'Cada número con su color'),
  retro(label: 'Retro', description: 'Fichas de madera de toda la vida'),
  minimalist(label: 'Minimalista', description: 'Solo contornos y números'),
  image(label: 'Imagen', description: 'Arma el paisaje pieza a pieza');

  const TileStyle({required this.label, required this.description});

  final String label;
  final String description;

  static TileStyle fromName(String? name) {
    return TileStyle.values.firstWhere(
      (style) => style.name == name,
      orElse: () => TileStyle.classic,
    );
  }
}
