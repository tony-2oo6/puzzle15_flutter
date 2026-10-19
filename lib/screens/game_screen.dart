import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_scope.dart';
import '../core/formatters.dart';
import '../core/game_feedback.dart';
import '../logic/puzzle_board.dart';
import '../logic/puzzle_game.dart';
import '../models/difficulty.dart';
import '../models/high_score.dart';
import '../models/tile_style.dart';
import '../widgets/common.dart';
import '../widgets/game_over_dialog.dart';
import '../widgets/puzzle_art.dart';
import '../widgets/puzzle_board_view.dart';
import '../widgets/themed_background.dart';

/// Pantalla de juego.
///
/// Es un [StatefulWidget] porque su estado cambia constantemente: cada
/// movimiento, cada tick del cronómetro, la pausa y el fin de partida. Las
/// reglas viven en [PuzzleGame] (lógica pura); aquí solo se traducen las
/// interacciones del usuario en llamadas a esa lógica y se usa `setState`
/// para redibujar con el nuevo estado.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.difficulty,
    required this.timeAttack,
  });

  final Difficulty difficulty;
  final bool timeAttack;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final PuzzleGame _game = PuzzleGame(
    difficulty: widget.difficulty,
    timeLimit: widget.timeAttack ? widget.difficulty.timeLimit : null,
  );

  final FocusNode _focusNode = FocusNode(debugLabel: 'tablero');
  Timer? _ticker;
  bool _resultVisible = false;
  bool _showReference = false;

  /// Aviso de poco tiempo en contrarreloj (últimos 30 s).
  static const Duration _lowTimeThreshold = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  /// Si la app pasa a segundo plano (cambio de pestaña, llamada, etc.) se
  /// pausa la partida para no penalizar al jugador.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed &&
        _game.status == GameStatus.playing) {
      _pause();
    }
  }

  GameFeedback get _feedback => GameFeedback(
    enabled: AppScope.settingsOf(context, listen: false).soundEnabled,
  );

  bool get _animationsEnabled =>
      AppScope.settingsOf(context, listen: false).animationsEnabled;

  // ---------------------------------------------------------------------
  // Cronómetro
  // ---------------------------------------------------------------------

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      final timeUp = _game.checkTimeUp();
      // setState justificado: el tiempo mostrado cambia en cada tick.
      setState(() {});
      if (timeUp) {
        _stopTicker();
        unawaited(_finishGame());
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ---------------------------------------------------------------------
  // Acciones del jugador
  // ---------------------------------------------------------------------

  void _handleTileTap(int index) => _applyMove(() => _game.tryMove(index));

  void _handleDirection(MoveDirection direction) =>
      _applyMove(() => _game.tryMoveInDirection(direction));

  void _applyMove(int Function() move) {
    if (_game.isFinished || _game.status == GameStatus.paused) return;
    var moved = 0;
    setState(() {
      moved = move();
    });
    if (moved == 0) {
      _feedback.invalidMove();
      return;
    }
    _feedback.move();
    if (_game.status == GameStatus.playing) {
      _startTicker();
    } else if (_game.status == GameStatus.won) {
      _stopTicker();
      unawaited(_finishGame());
    }
  }

  void _pause() {
    if (_game.status != GameStatus.playing) return;
    setState(_game.pause);
    _stopTicker();
  }

  void _resume() {
    if (_game.status != GameStatus.paused) return;
    setState(_game.resume);
    _startTicker();
    _focusNode.requestFocus();
  }

  void _togglePause() {
    if (_game.status == GameStatus.playing) {
      _pause();
    } else if (_game.status == GameStatus.paused) {
      _resume();
    }
  }

  Future<void> _restart({bool askFirst = true}) async {
    if (askFirst && _game.isInProgress) {
      final wasPlaying = _game.status == GameStatus.playing;
      _pause();
      final confirmed = await showConfirmDialog(
        context,
        title: '¿Reiniciar partida?',
        message: 'Se generará un tablero nuevo y perderás el progreso actual.',
        confirmLabel: 'Reiniciar',
        icon: Icons.replay_rounded,
      );
      if (!mounted) return;
      if (!confirmed) {
        if (wasPlaying) _resume();
        return;
      }
    }
    _stopTicker();
    setState(() {
      _game.restart();
      _showReference = false;
    });
    _focusNode.requestFocus();
  }

  Future<void> _surrender() async {
    final wasPlaying = _game.status == GameStatus.playing;
    _pause();
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Rendirse?',
      message: 'La partida contará como perdida y no se guardará ningún récord.',
      confirmLabel: 'Rendirme',
      icon: Icons.flag_rounded,
      destructive: true,
    );
    if (!mounted) return;
    if (!confirmed) {
      if (wasPlaying) _resume();
      return;
    }
    _stopTicker();
    setState(_game.surrender);
    await _finishGame();
  }

  /// Confirmación al intentar salir con una partida en curso.
  Future<void> _confirmExit() async {
    final wasPlaying = _game.status == GameStatus.playing;
    _pause();
    final leave = await showConfirmDialog(
      context,
      title: '¿Salir de la partida?',
      message: 'Perderás el progreso de esta partida.',
      confirmLabel: 'Salir',
      icon: Icons.logout_rounded,
    );
    if (!mounted) return;
    if (leave) {
      Navigator.of(context).pop();
    } else if (wasPlaying) {
      _resume();
    }
  }

  /// Guarda el récord (si se ganó) y muestra la pantalla de fin de partida.
  Future<void> _finishGame() async {
    if (_resultVisible) return;
    _resultVisible = true;

    final won = _game.status == GameStatus.won;
    final highScores = AppScope.highScoresOf(context);
    final animations = _animationsEnabled;
    var record = RecordUpdate.none;

    if (won) {
      _feedback.victory();
      record = await highScores.submitWin(
        widget.difficulty,
        ScoreEntry(
          elapsedMs: _game.elapsed.inMilliseconds,
          moves: _game.moves,
          date: DateTime.now(),
        ),
      );
    } else {
      _feedback.defeat();
    }

    // Pequeña pausa para que se vea el último deslizamiento.
    if (animations) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
    }
    if (!mounted) return;

    final action = await showGameOverDialog(
      context,
      animationsEnabled: animations,
      result: GameResult(
        won: won,
        lossReason: _game.lossReason,
        elapsed: _game.elapsed,
        moves: _game.moves,
        difficulty: widget.difficulty,
        timeAttack: _game.isTimed,
        record: record,
      ),
    );
    _resultVisible = false;
    if (!mounted) return;

    switch (action) {
      case GameOverAction.playAgain:
        await _restart(askFirst: false);
      case GameOverAction.mainMenu:
        Navigator.of(context).pop();
      case GameOverAction.viewBoard || null:
        _focusNode.requestFocus();
    }
  }

  // ---------------------------------------------------------------------
  // Teclado y gestos
  // ---------------------------------------------------------------------

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final direction = switch (key) {
      LogicalKeyboardKey.arrowUp || LogicalKeyboardKey.keyW => MoveDirection.up,
      LogicalKeyboardKey.arrowDown ||
      LogicalKeyboardKey.keyS => MoveDirection.down,
      LogicalKeyboardKey.arrowLeft ||
      LogicalKeyboardKey.keyA => MoveDirection.left,
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.keyD => MoveDirection.right,
      _ => null,
    };
    if (direction != null) {
      _handleDirection(direction);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.keyP || key == LogicalKeyboardKey.space)) {
      _togglePause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.distance < 250) return;
    final direction = velocity.dx.abs() > velocity.dy.abs()
        ? (velocity.dx > 0 ? MoveDirection.right : MoveDirection.left)
        : (velocity.dy > 0 ? MoveDirection.down : MoveDirection.up);
    _handleDirection(direction);
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.settingsOf(context);
    return PopScope(
      canPop: !_game.isInProgress,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        body: ThemedBackground(
          child: SafeArea(
            child: Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: _onKeyEvent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide =
                      constraints.maxWidth >= 760 &&
                      constraints.maxWidth > constraints.maxHeight * 1.1;
                  return Column(
                    children: [
                      _buildTopBar(context, settings.tileStyle),
                      Expanded(
                        child: wide
                            ? _buildWideLayout(context, settings.tileStyle,
                                settings.animationsEnabled)
                            : _buildNarrowLayout(context, settings.tileStyle,
                                settings.animationsEnabled),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, TileStyle style) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final status = _game.status;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver al menú',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.difficulty.label} · ${widget.difficulty.gridLabel}',
                  style: textTheme.titleLarge,
                ),
                Text(
                  _game.isTimed ? 'Modo contrarreloj' : 'Modo clásico',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (style == TileStyle.image)
            IconButton(
              tooltip: _showReference ? 'Ocultar imagen' : 'Ver imagen de referencia',
              isSelected: _showReference,
              icon: const Icon(Icons.image_outlined),
              selectedIcon: const Icon(Icons.image_rounded),
              onPressed: () => setState(() => _showReference = !_showReference),
            ),
          IconButton(
            tooltip: status == GameStatus.paused ? 'Reanudar (P)' : 'Pausar (P)',
            onPressed:
                status == GameStatus.playing || status == GameStatus.paused
                ? _togglePause
                : null,
            icon: Icon(
              status == GameStatus.paused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Reiniciar',
            icon: const Icon(Icons.replay_rounded),
            onPressed: () => _restart(),
          ),
          if (_game.isInProgress)
            IconButton(
              tooltip: 'Rendirse',
              icon: const Icon(Icons.flag_outlined),
              onPressed: _surrender,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildStats() {
    final remaining = _game.remaining;
    final lowTime = remaining != null && remaining <= _lowTimeThreshold;
    return [
      StatTile(
        icon: Icons.swap_horiz_rounded,
        label: 'Movimientos',
        value: '${_game.moves}',
      ),
      StatTile(
        icon: remaining == null
            ? Icons.timer_outlined
            : Icons.hourglass_bottom_rounded,
        label: remaining == null ? 'Tiempo' : 'Restante',
        value: formatDuration(remaining ?? _game.elapsed),
        warning: lowTime && !_game.isFinished,
      ),
      StatTile(
        icon: Icons.check_circle_outline_rounded,
        label: 'En su lugar',
        value: '${_game.board.correctTileCount}/${_game.board.tileCount}',
      ),
    ];
  }

  String get _hint {
    switch (_game.status) {
      case GameStatus.ready:
        return 'Toca una pieza en la fila o columna del hueco para empezar. '
            'El cronómetro arranca con tu primer movimiento.';
      case GameStatus.playing:
        return 'Toca, desliza o usa las flechas del teclado.';
      case GameStatus.paused:
        return 'Partida en pausa.';
      case GameStatus.won:
        return '¡Rompecabezas resuelto!';
      case GameStatus.lost:
        return _game.lossReason == LossReason.timeUp
            ? 'Se acabó el tiempo.'
            : 'Te rendiste en esta partida.';
    }
  }

  Widget _buildHintAndActions(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _hint,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (_game.isFinished) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _restart(askFirst: false),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Jugar de nuevo'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Menú principal'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    TileStyle style,
    bool animations,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _buildStats(),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBoardArea(style, animations)),
          const SizedBox(height: 12),
          _buildHintAndActions(context),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    TileStyle style,
    bool animations,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          SizedBox(
            width: 260,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final stat in _buildStats()) ...[
                  stat,
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                _buildHintAndActions(context),
                const SizedBox(height: 16),
                Text(
                  'Atajos: flechas o WASD para mover · P o espacio para pausar',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(child: _buildBoardArea(style, animations)),
        ],
      ),
    );
  }

  Widget _buildBoardArea(TileStyle style, bool animations) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = math.min(
          math.min(constraints.maxWidth, constraints.maxHeight),
          640.0,
        );
        final paused = _game.status == GameStatus.paused;
        final interactive = !paused && !_game.isFinished;
        return Center(
          child: SizedBox(
            width: extent,
            height: extent,
            child: GestureDetector(
              onPanEnd: interactive ? _onSwipe : null,
              child: Stack(
                children: [
                  PuzzleBoardView(
                    board: _game.board,
                    extent: extent,
                    style: style,
                    animationsEnabled: animations,
                    onTileTap: interactive ? _handleTileTap : null,
                  ),
                  if (_showReference && style == TileStyle.image)
                    Positioned.fill(child: _ReferenceImage(extent: extent)),
                  if (paused)
                    Positioned.fill(
                      child: _PauseOverlay(extent: extent, onResume: _resume),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Cubre el tablero durante la pausa (así no se puede estudiar sin que
/// corra el reloj).
class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.extent, required this.onResume});

  final double extent;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(extent * 0.05),
      child: ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pause_circle_rounded, size: 64, color: scheme.primary),
              const SizedBox(height: 12),
              Text('En pausa', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              FilledButton.icon(
                autofocus: true,
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Imagen completa superpuesta para el modo imagen.
class _ReferenceImage extends StatelessWidget {
  const _ReferenceImage({required this.extent});

  final double extent;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(extent * 0.05),
        child: Opacity(
          opacity: 0.92,
          child: CustomPaint(
            painter: const PuzzleArtPainter(),
            size: Size.square(extent),
          ),
        ),
      ),
    );
  }
}
