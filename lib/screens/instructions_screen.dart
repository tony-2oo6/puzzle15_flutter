import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../logic/puzzle_board.dart';
import '../models/difficulty.dart';
import '../widgets/common.dart';
import '../widgets/puzzle_board_view.dart';

/// Reglas del juego. Contenido estático: [StatelessWidget].
class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.settingsOf(context);
    final limits = Difficulty.values
        .map((d) => '${d.label}: ${d.timeLimit.inMinutes} min')
        .join(' · ');

    return Scaffold(
      appBar: AppBar(title: const Text('Cómo jugar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ResponsiveContent(
              maxWidth: 680,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionCard(
                    icon: Icons.flag_circle_outlined,
                    title: 'Objetivo',
                    child: Text(
                      'Ordena las piezas en orden numérico (o forma la imagen '
                      'correcta) utilizando el espacio vacío para deslizar las '
                      'piezas adyacentes.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    icon: Icons.emoji_events_outlined,
                    title: 'Cómo se gana',
                    child: Column(
                      children: [
                        const Text(
                          'Ganas cuando todas las piezas quedan ordenadas de '
                          'izquierda a derecha y de arriba hacia abajo '
                          '(1, 2, 3…), con el espacio vacío en la esquina '
                          'inferior derecha. Así se ve un tablero resuelto:',
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: PuzzleBoardView(
                            board: PuzzleBoard.solved(3),
                            extent: 180,
                            style: settings.tileStyle,
                            animationsEnabled: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionCard(
                    icon: Icons.touch_app_outlined,
                    title: 'Cómo mover las piezas',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bullet(
                          'Toca una pieza junto al espacio vacío para '
                          'deslizarla hacia él.',
                        ),
                        _Bullet(
                          'Atajo: si tocas una pieza más lejana en la misma '
                          'fila o columna del hueco, se desliza toda la línea. '
                          'Cada pieza movida cuenta como un movimiento.',
                        ),
                        _Bullet(
                          'También puedes deslizar el dedo sobre el tablero o '
                          'usar las flechas del teclado (o W, A, S, D).',
                        ),
                        _Bullet(
                          'El cronómetro empieza con tu primer movimiento. '
                          'Pausa con el botón de pausa, la tecla P o la barra '
                          'espaciadora; el tablero se oculta mientras tanto.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    icon: Icons.hourglass_bottom_rounded,
                    title: '¿Se puede perder?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Bullet(
                          'En el modo clásico no: todo tablero generado tiene '
                          'solución garantizada y puedes tomarte el tiempo que '
                          'necesites.',
                        ),
                        _Bullet(
                          'En el modo contrarreloj (actívalo en Configuración) '
                          'pierdes si el tiempo llega a cero antes de ordenar '
                          'el tablero. Límites: $limits.',
                        ),
                        const _Bullet(
                          'En cualquier modo puedes rendirte con el botón de '
                          'bandera; la partida cuenta como perdida.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionCard(
                    icon: Icons.leaderboard_outlined,
                    title: 'Marcadores',
                    child: Text(
                      'Por cada dificultad se guardan tu mejor tiempo y tu '
                      'menor número de movimientos, con la fecha de la '
                      'partida. Solo cuentan las partidas ganadas.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Consejos',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bullet(
                          'Resuelve primero la fila superior y luego la '
                          'columna izquierda: el problema se reduce a un '
                          'tablero más pequeño.',
                        ),
                        _Bullet(
                          'Coloca las dos últimas piezas de una fila juntas, '
                          'girándolas alrededor del hueco.',
                        ),
                        _Bullet(
                          'El punto en la esquina de una pieza indica que ya '
                          'está en su lugar.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Volver al menú principal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
