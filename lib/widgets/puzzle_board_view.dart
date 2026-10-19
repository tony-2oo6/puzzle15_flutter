import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/puzzle_board.dart';
import '../models/tile_style.dart';
import 'tile_face.dart';

/// Dibuja el tablero. Cada pieza se posiciona con [AnimatedPositioned]
/// identificada por su número, así que al mover una pieza Flutter anima el
/// deslizamiento desde su posición anterior hasta la nueva.
class PuzzleBoardView extends StatelessWidget {
  const PuzzleBoardView({
    super.key,
    required this.board,
    required this.extent,
    required this.style,
    required this.animationsEnabled,
    this.onTileTap,
  });

  final PuzzleBoard board;

  /// Lado del tablero en píxeles lógicos (calculado de forma responsive).
  final double extent;
  final TileStyle style;
  final bool animationsEnabled;

  /// `null` deshabilita la interacción (pausa, fin de partida, vistas previas).
  final ValueChanged<int>? onTileTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = board.size;
    final padding = extent * 0.025;
    final gap = extent * (size <= 3 ? 0.022 : 0.016);
    final inner = extent - padding * 2;
    final tileExtent = (inner - gap * (size - 1)) / size;
    final duration = animationsEnabled
        ? const Duration(milliseconds: 150)
        : Duration.zero;

    double offsetOf(int position) => position * (tileExtent + gap);

    final (boardColor, slotColor, borderColor) = switch (style) {
      TileStyle.retro => (
        const Color(0xFF6B3F1F),
        const Color(0xFF55301A),
        const Color(0xFF3E2210),
      ),
      TileStyle.image => (
        const Color(0xFF1B1446),
        const Color(0xFF120D33),
        const Color(0xFF0C0824),
      ),
      TileStyle.minimalist => (
        Colors.transparent,
        scheme.outlineVariant.withValues(alpha: 0.25),
        scheme.outlineVariant,
      ),
      _ => (
        scheme.surfaceContainerHigh,
        scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        scheme.outlineVariant.withValues(alpha: 0.5),
      ),
    };

    final onTap = onTileTap;

    return Semantics(
      container: true,
      label: 'Tablero de ${size}x$size',
      child: Container(
        width: extent,
        height: extent,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: boardColor,
          borderRadius: BorderRadius.circular(extent * 0.05),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: style == TileStyle.minimalist
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Huecos de fondo: muestran la cuadrícula y el espacio vacío.
            for (var index = 0; index < size * size; index++)
              Positioned(
                left: offsetOf(board.colOf(index)),
                top: offsetOf(board.rowOf(index)),
                width: tileExtent,
                height: tileExtent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: slotColor,
                    borderRadius: BorderRadius.circular(tileExtent * 0.16),
                  ),
                ),
              ),
            for (var value = 1; value <= board.tileCount; value++)
              _buildTile(
                value: value,
                index: board.indexOfValue(value),
                tileExtent: tileExtent,
                offsetOf: offsetOf,
                duration: duration,
                onTap: onTap,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required int value,
    required int index,
    required double tileExtent,
    required double Function(int) offsetOf,
    required Duration duration,
    required ValueChanged<int>? onTap,
  }) {
    return AnimatedPositioned(
      key: ValueKey<int>(value),
      duration: duration,
      curve: Curves.easeOutCubic,
      left: offsetOf(board.colOf(index)),
      top: offsetOf(board.rowOf(index)),
      width: tileExtent,
      height: tileExtent,
      child: PuzzleTile(
        value: value,
        gridSize: board.size,
        style: style,
        inPlace: board.isInCorrectPlace(index),
        animationsEnabled: animationsEnabled,
        onTap: onTap == null ? null : () => onTap(index),
      ),
    );
  }
}

/// Pieza interactiva: animación de presión, cursor de mano y semántica
/// accesible. La apariencia la aporta [TileFace].
class PuzzleTile extends StatefulWidget {
  const PuzzleTile({
    super.key,
    required this.value,
    required this.gridSize,
    required this.style,
    required this.inPlace,
    required this.animationsEnabled,
    required this.onTap,
  });

  final int value;
  final int gridSize;
  final TileStyle style;
  final bool inPlace;
  final bool animationsEnabled;
  final VoidCallback? onTap;

  @override
  State<PuzzleTile> createState() => _PuzzleTileState();
}

class _PuzzleTileState extends State<PuzzleTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      container: true,
      button: enabled,
      label: 'Pieza ${widget.value}${widget.inPlace ? ', en su lugar' : ''}',
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: widget.animationsEnabled
                ? const Duration(milliseconds: 90)
                : Duration.zero,
            child: TileFace(
              value: widget.value,
              gridSize: widget.gridSize,
              style: widget.style,
              inPlace: widget.inPlace,
            ),
          ),
        ),
      ),
    );
  }
}
