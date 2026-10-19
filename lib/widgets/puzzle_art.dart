import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ilustración del "Modo Imagen": un paisaje al atardecer dibujado por
/// código (sin archivos de imagen), lo que la hace nítida a cualquier tamaño
/// y disponible sin conexión.
abstract final class PuzzleArt {
  static void paintScene(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Cielo.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E1452),
            Color(0xFF5B2A86),
            Color(0xFFE0607E),
            Color(0xFFFFB36B),
          ],
          stops: [0, 0.35, 0.62, 0.8],
        ).createShader(rect),
    );

    // Estrellas.
    final starPaint = Paint()..color = const Color(0xCCFFFFFF);
    final random = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final dx = random.nextDouble() * w;
      final dy = random.nextDouble() * h * 0.35;
      canvas.drawCircle(Offset(dx, dy), w * (0.002 + random.nextDouble() * 0.004), starPaint);
    }

    // Luna creciente.
    final moonCenter = Offset(w * 0.18, h * 0.14);
    canvas.drawCircle(moonCenter, w * 0.05, Paint()..color = const Color(0xFFFFF3C4));
    canvas.drawCircle(
      moonCenter.translate(w * 0.02, -h * 0.012),
      w * 0.045,
      Paint()..color = const Color(0xFF2A1A60),
    );

    // Sol con halo.
    final sunCenter = Offset(w * 0.66, h * 0.56);
    canvas.drawCircle(
      sunCenter,
      w * 0.26,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x66FFD27A), const Color(0x00FFD27A)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.26)),
    );
    canvas.drawCircle(sunCenter, w * 0.12, Paint()..color = const Color(0xFFFFE08A));

    // Nubes.
    final cloudPaint = Paint()..color = const Color(0x55FFFFFF);
    void cloud(double x, double y, double s) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * x, h * y, w * s, h * s * 0.22),
          Radius.circular(h * s * 0.11),
        ),
        cloudPaint,
      );
    }

    cloud(0.48, 0.18, 0.3);
    cloud(0.58, 0.24, 0.22);
    cloud(0.06, 0.34, 0.26);

    // Montañas lejanas.
    final far = Path()
      ..moveTo(0, h * 0.66)
      ..lineTo(w * 0.14, h * 0.5)
      ..lineTo(w * 0.28, h * 0.6)
      ..lineTo(w * 0.44, h * 0.42)
      ..lineTo(w * 0.62, h * 0.62)
      ..lineTo(w * 0.8, h * 0.48)
      ..lineTo(w, h * 0.6)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF7B3F8F));

    // Nieve en el pico principal.
    final snow = Path()
      ..moveTo(w * 0.44, h * 0.42)
      ..lineTo(w * 0.40, h * 0.47)
      ..lineTo(w * 0.43, h * 0.46)
      ..lineTo(w * 0.45, h * 0.48)
      ..lineTo(w * 0.48, h * 0.465)
      ..close();
    canvas.drawPath(snow, Paint()..color = const Color(0xFFF6E7FF));

    // Colinas medias.
    final mid = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.2, h * 0.62, w * 0.42, h * 0.72)
      ..quadraticBezierTo(w * 0.66, h * 0.82, w, h * 0.68)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mid, Paint()..color = const Color(0xFF4B2470));

    // Lago con reflejo del sol.
    final lake = Rect.fromLTWH(0, h * 0.82, w, h * 0.18);
    canvas.drawRect(
      lake,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B2A7A), Color(0xFF1B1446)],
        ).createShader(lake),
    );
    final reflection = Paint()..color = const Color(0x88FFE08A);
    for (var i = 0; i < 4; i++) {
      final width = w * (0.2 - i * 0.04);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(sunCenter.dx, h * (0.85 + i * 0.035)),
            width: width,
            height: h * 0.012,
          ),
          Radius.circular(h * 0.006),
        ),
        reflection,
      );
    }

    // Pinos en primer plano.
    final treePaint = Paint()..color = const Color(0xFF1A0F33);
    void tree(double x, double base, double height) {
      final path = Path()
        ..moveTo(w * x, h * (base - height))
        ..lineTo(w * (x - height * 0.32), h * base)
        ..lineTo(w * (x + height * 0.32), h * base)
        ..close();
      canvas.drawPath(path, treePaint);
    }

    tree(0.08, 0.86, 0.24);
    tree(0.16, 0.86, 0.17);
    tree(0.9, 0.86, 0.2);
    tree(0.97, 0.86, 0.14);

    // Pájaros.
    final birdPaint = Paint()
      ..color = const Color(0xFF2A1A60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.006
      ..strokeCap = StrokeCap.round;
    void bird(double x, double y, double s) {
      final path = Path()
        ..moveTo(w * (x - s), h * y)
        ..quadraticBezierTo(w * (x - s / 2), h * (y - s * 0.6), w * x, h * y)
        ..quadraticBezierTo(w * (x + s / 2), h * (y - s * 0.6), w * (x + s), h * y);
      canvas.drawPath(path, birdPaint);
    }

    bird(0.3, 0.3, 0.03);
    bird(0.36, 0.26, 0.022);
    bird(0.82, 0.34, 0.026);
  }
}

/// Pinta la imagen completa (vista de referencia).
class PuzzleArtPainter extends CustomPainter {
  const PuzzleArtPainter();

  @override
  void paint(Canvas canvas, Size size) => PuzzleArt.paintScene(canvas, size);

  @override
  bool shouldRepaint(PuzzleArtPainter oldDelegate) => false;
}

/// Pinta solo el fragmento de la imagen que corresponde a una pieza.
class PuzzleArtSlicePainter extends CustomPainter {
  const PuzzleArtSlicePainter({
    required this.row,
    required this.col,
    required this.gridSize,
  });

  /// Fila y columna de la posición **correcta** de la pieza.
  final int row;
  final int col;
  final int gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(-col * size.width, -row * size.height);
    PuzzleArt.paintScene(
      canvas,
      Size(size.width * gridSize, size.height * gridSize),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(PuzzleArtSlicePainter oldDelegate) =>
      oldDelegate.row != row ||
      oldDelegate.col != col ||
      oldDelegate.gridSize != gridSize;
}
