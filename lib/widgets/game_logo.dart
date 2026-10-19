import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Logo del juego: un mini tablero 2×2 con tres fichas y el hueco.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gap = size * 0.08;
    final tile = (size - gap) / 2;

    Widget piece(String label, Color color) => Container(
      width: tile,
      height: tile,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(tile * 0.24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: tile * 0.25,
            offset: Offset(0, tile * 0.08),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.displayFont,
          fontWeight: FontWeight.w700,
          fontSize: tile * 0.5,
          color: Colors.white,
          height: 1,
        ),
      ),
    );

    final hole = Container(
      width: tile,
      height: tile,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tile * 0.24),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.6),
          width: size * 0.02,
        ),
      ),
    );

    return Semantics(
      label: 'Logo de 15-Puzzle Flutter',
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [piece('1', scheme.primary), piece('2', AppTheme.accent)],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [piece('3', scheme.tertiary), hole],
            ),
          ],
        ),
      ),
    );
  }
}
