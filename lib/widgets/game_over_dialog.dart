import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../logic/puzzle_game.dart';
import '../models/difficulty.dart';
import '../models/high_score.dart';

/// Acción elegida en la pantalla de fin de partida.
enum GameOverAction {
  /// Reiniciar: nueva partida en la misma dificultad.
  playAgain,

  /// Continuar: volver a ver el tablero final.
  viewBoard,

  /// Salir al menú principal.
  mainMenu,
}

/// Datos que se muestran al terminar una partida.
class GameResult {
  const GameResult({
    required this.won,
    required this.elapsed,
    required this.moves,
    required this.difficulty,
    required this.timeAttack,
    this.lossReason,
    this.record = RecordUpdate.none,
  });

  final bool won;
  final LossReason? lossReason;
  final Duration elapsed;
  final int moves;
  final Difficulty difficulty;
  final bool timeAttack;
  final RecordUpdate record;
}

/// Muestra la pantalla superpuesta de victoria o derrota.
Future<GameOverAction?> showGameOverDialog(
  BuildContext context, {
  required GameResult result,
  required bool animationsEnabled,
}) {
  return showGeneralDialog<GameOverAction>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Fin de partida',
    barrierColor: Colors.black54,
    transitionDuration: animationsEnabled
        ? const Duration(milliseconds: 380)
        : Duration.zero,
    pageBuilder: (context, _, _) => GameOverDialog(
      result: result,
      animationsEnabled: animationsEnabled,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.result,
    required this.animationsEnabled,
  });

  final GameResult result;
  final bool animationsEnabled;

  String get _subtitle {
    if (result.won) {
      return result.record.isFirstWin
          ? '¡Tu primera victoria en ${result.difficulty.label}!'
          : 'Resolviste el tablero ${result.difficulty.gridLabel}.';
    }
    return switch (result.lossReason) {
      LossReason.timeUp => 'Se agotó el tiempo del modo contrarreloj.',
      LossReason.surrendered => 'Te rendiste. ¡La próxima será!',
      null => 'La partida terminó.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final won = result.won;
    final record = result.record;
    final accent = won ? const Color(0xFFFFB020) : scheme.error;

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB020), AppTheme.accent],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            '¡Nuevo récord!',
            style: textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
    if (animationsEnabled) {
      badge = Pulse(infinite: true, child: badge);
    }

    final recordDetails = [
      if (record.newBestTime) 'mejor tiempo',
      if (record.newFewestMoves) 'menos movimientos',
    ].join(' y ');

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    won
                        ? Icons.emoji_events_rounded
                        : (result.lossReason == LossReason.timeUp
                              ? Icons.hourglass_bottom_rounded
                              : Icons.flag_rounded),
                    size: 48,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                won ? '¡Ganaste!' : 'Perdiste',
                textAlign: TextAlign.center,
                style: textTheme.displaySmall,
              ),
              const SizedBox(height: 6),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (won && record.isNewRecord) ...[
                const SizedBox(height: 16),
                Center(child: badge),
                const SizedBox(height: 6),
                Text(
                  'Superaste tu marca de $recordDetails.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      icon: Icons.timer_outlined,
                      label: 'Tiempo total',
                      value: formatDuration(result.elapsed, showTenths: true),
                    ),
                    _SummaryRow(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Movimientos',
                      value: '${result.moves}',
                    ),
                    _SummaryRow(
                      icon: Icons.grid_view_rounded,
                      label: 'Dificultad',
                      value:
                          '${result.difficulty.label} (${result.difficulty.gridLabel})',
                    ),
                    _SummaryRow(
                      icon: Icons.sports_score_rounded,
                      label: 'Modo',
                      value: result.timeAttack ? 'Contrarreloj' : 'Clásico',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                autofocus: true,
                onPressed: () =>
                    Navigator.of(context).pop(GameOverAction.playAgain),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Reiniciar'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(GameOverAction.viewBoard),
                icon: const Icon(Icons.grid_on_rounded),
                label: const Text('Continuar (ver tablero)'),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(GameOverAction.mainMenu),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Salir al menú principal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
