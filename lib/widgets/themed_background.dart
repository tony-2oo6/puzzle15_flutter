import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';

/// Fondo temático: degradado suave con fichas translúcidas que flotan
/// lentamente. La animación se detiene si el usuario desactiva animaciones.
class ThemedBackground extends StatefulWidget {
  const ThemedBackground({super.key, required this.child});

  final Widget child;

  @override
  State<ThemedBackground> createState() => _ThemedBackgroundState();
}

class _ThemedBackgroundState extends State<ThemedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = AppScope.settingsOf(context).animationsEnabled;
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [scheme.surface, scheme.surfaceContainer, scheme.surfaceContainerLow]
              : [
                  scheme.surface,
                  scheme.primaryContainer.withValues(alpha: 0.45),
                  scheme.surfaceContainerLow,
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FloatingTilesPainter(
                  animation: _controller,
                  color: scheme.primary.withValues(alpha: isDark ? 0.07 : 0.06),
                  accent: scheme.tertiary.withValues(alpha: isDark ? 0.07 : 0.06),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _FloatingTilesPainter extends CustomPainter {
  _FloatingTilesPainter({
    required this.animation,
    required this.color,
    required this.accent,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;
  final Color accent;

  // Posiciones fijas (relativas) para que el fondo sea estable entre frames.
  static const List<(double, double, double, double)> _tiles = [
    (0.08, 0.12, 0.16, 0.0),
    (0.82, 0.08, 0.12, 1.3),
    (0.70, 0.42, 0.20, 2.1),
    (0.14, 0.58, 0.11, 3.4),
    (0.90, 0.74, 0.15, 4.2),
    (0.36, 0.86, 0.13, 5.0),
    (0.48, 0.22, 0.09, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    final t = animation.value * 2 * math.pi;
    for (var i = 0; i < _tiles.length; i++) {
      final (x, y, scale, phase) = _tiles[i];
      final extent = shortest * scale;
      final dx = math.sin(t + phase) * shortest * 0.02;
      final dy = math.cos(t * 0.8 + phase) * shortest * 0.025;
      final rect = Rect.fromCenter(
        center: Offset(size.width * x + dx, size.height * y + dy),
        width: extent,
        height: extent,
      );
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(math.sin(t + phase) * 0.12);
      canvas.translate(-rect.center.dx, -rect.center.dy);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(extent * 0.22)),
        Paint()..color = i.isEven ? color : accent,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatingTilesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}
