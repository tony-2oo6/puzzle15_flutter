import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/tile_style.dart';
import 'puzzle_art.dart';

/// Apariencia visual de una pieza según el estilo elegido. No gestiona
/// interacción (eso lo hace `PuzzleTile`), así que también se reutiliza en
/// las vistas previas de Configuración.
class TileFace extends StatelessWidget {
  const TileFace({
    super.key,
    required this.value,
    required this.gridSize,
    required this.style,
    this.inPlace = false,
  });

  final int value;
  final int gridSize;
  final TileStyle style;

  /// Muestra un pequeño indicador si la pieza ya está en su posición.
  final bool inPlace;

  int get _tileCount => gridSize * gridSize - 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.biggest.shortestSide;
        final radius = BorderRadius.circular(extent * 0.16);
        if (style == TileStyle.image) {
          return _buildImage(extent, radius);
        }
        final visual = _TileVisual.resolve(
          context: context,
          style: style,
          value: value,
          tileCount: _tileCount,
          inPlace: inPlace,
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: visual.gradient == null ? visual.background : null,
            gradient: visual.gradient,
            borderRadius: radius,
            border: visual.borderColor == null
                ? null
                : Border.all(
                    color: visual.borderColor!,
                    width: extent * visual.borderWidthFactor,
                  ),
            boxShadow: visual.hasShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: extent * 0.08,
                      offset: Offset(0, extent * 0.05),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.all(extent * 0.12),
                  child: FittedBox(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontFamily: visual.fontFamily,
                        fontWeight: visual.fontWeight,
                        fontSize: extent * 0.42,
                        color: visual.foreground,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              if (inPlace)
                Positioned(
                  top: extent * 0.1,
                  right: extent * 0.1,
                  child: Container(
                    width: extent * 0.08,
                    height: extent * 0.08,
                    decoration: BoxDecoration(
                      color: visual.foreground.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(double extent, BorderRadius radius) {
    final correctIndex = value - 1;
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: PuzzleArtSlicePainter(
              row: correctIndex ~/ gridSize,
              col: correctIndex % gridSize,
              gridSize: gridSize,
            ),
          ),
          Positioned(
            left: extent * 0.07,
            top: extent * 0.07,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: extent * 0.06,
                vertical: extent * 0.02,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(extent * 0.08),
              ),
              child: Text(
                '$value',
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w600,
                  fontSize: extent * 0.15,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: inPlace
                    ? const Color(0xCCFFE08A)
                    : Colors.white.withValues(alpha: 0.18),
                width: extent * 0.025,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colores y tipografía de una pieza para cada estilo.
class _TileVisual {
  const _TileVisual({
    required this.background,
    required this.foreground,
    this.gradient,
    this.borderColor,
    this.borderWidthFactor = 0.02,
    this.hasShadow = true,
    this.fontFamily = AppTheme.displayFont,
    this.fontWeight = FontWeight.w600,
  });

  factory _TileVisual.resolve({
    required BuildContext context,
    required TileStyle style,
    required int value,
    required int tileCount,
    required bool inPlace,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (style) {
      case TileStyle.classic:
        return _TileVisual(
          background: isDark
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerLowest,
          foreground: inPlace ? scheme.primary : scheme.onSurface,
        );
      case TileStyle.colorful:
        final hue = 330.0 * (value - 1) / (tileCount > 1 ? tileCount - 1 : 1);
        final start = HSLColor.fromAHSL(1, hue, 0.72, isDark ? 0.5 : 0.58);
        final end = HSLColor.fromAHSL(1, (hue + 28) % 360, 0.78, isDark ? 0.4 : 0.48);
        return _TileVisual(
          background: start.toColor(),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [start.toColor(), end.toColor()],
          ),
          foreground: Colors.white,
          fontWeight: FontWeight.w700,
        );
      case TileStyle.retro:
        return const _TileVisual(
          background: Color(0xFFF1DDB0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6E6C1), Color(0xFFDDBD82)],
          ),
          foreground: Color(0xFF5A3418),
          borderColor: Color(0xFF8B5A2B),
          borderWidthFactor: 0.035,
          fontWeight: FontWeight.w700,
        );
      case TileStyle.minimalist:
        return _TileVisual(
          background: Colors.transparent,
          foreground: inPlace ? scheme.primary : scheme.onSurface,
          borderColor: scheme.outline.withValues(alpha: 0.7),
          hasShadow: false,
          fontFamily: AppTheme.bodyFont,
          fontWeight: FontWeight.w400,
        );
      case TileStyle.image:
        // El modo imagen se dibuja aparte; este valor no se usa.
        return _TileVisual(
          background: scheme.surface,
          foreground: scheme.onSurface,
        );
    }
  }

  final Color background;
  final Color foreground;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidthFactor;
  final bool hasShadow;
  final String fontFamily;
  final FontWeight fontWeight;
}
