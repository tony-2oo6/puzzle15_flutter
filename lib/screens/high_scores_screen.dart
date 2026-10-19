import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../core/formatters.dart';
import '../data/high_score_repository.dart';
import '../models/difficulty.dart';
import '../models/high_score.dart';
import '../widgets/appear.dart';
import '../widgets/common.dart';
import '../widgets/difficulty_picker.dart';

/// Pantalla de marcadores por dificultad.
///
/// Es un [StatefulWidget] porque mantiene en memoria los récords leídos del
/// almacenamiento y los actualiza (con `setState`) cuando el usuario los
/// borra.
class HighScoresScreen extends StatefulWidget {
  const HighScoresScreen({super.key});

  @override
  State<HighScoresScreen> createState() => _HighScoresScreenState();
}

class _HighScoresScreenState extends State<HighScoresScreen> {
  late HighScoreRepository _repository;
  Map<Difficulty, DifficultyRecords> _records = const {};
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _repository = AppScope.highScoresOf(context);
      _records = _repository.loadAll();
      _loaded = true;
    }
  }

  bool get _isEmpty => _records.values.every((records) => records.isEmpty);

  Future<void> _clearAll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Borrar todos los marcadores?',
      message:
          'Se eliminarán los récords de las tres dificultades. '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Borrar',
      icon: Icons.delete_forever_rounded,
      destructive: true,
    );
    if (!confirmed) return;
    await _repository.clearAll();
    if (!mounted) return;
    setState(() => _records = _repository.loadAll());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marcadores borrados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcadores'),
        actions: [
          IconButton(
            tooltip: 'Borrar marcadores',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _isEmpty ? null : _clearAll,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isEmpty ? const _EmptyState() : _buildRecords(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ResponsiveContent(
                maxWidth: 480,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Volver al menú principal'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecords() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        const spacing = 16.0;
        final available = math.max(0.0, math.min(constraints.maxWidth - 32, 1100.0));
        final cardWidth = (available - spacing * (columns - 1)) / columns;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final (index, difficulty) in Difficulty.values.indexed)
                  SizedBox(
                    width: cardWidth,
                    child: Appear(
                      delay: Duration(milliseconds: 90 * index),
                      child: _DifficultyRecordCard(
                        difficulty: difficulty,
                        records: _records[difficulty] ?? DifficultyRecords.empty,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DifficultyRecordCard extends StatelessWidget {
  const _DifficultyRecordCard({
    required this.difficulty,
    required this.records,
  });

  final Difficulty difficulty;
  final DifficultyRecords records;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bestTime = records.bestTime;
    final fewestMoves = records.fewestMoves;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MiniGridIcon(size: difficulty.size, color: scheme.primary, extent: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(difficulty.label, style: textTheme.titleLarge),
                      Text(
                        difficulty.summary,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (records.gamesWon > 0)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.emoji_events_rounded, size: 18),
                    label: Text(
                      records.gamesWon == 1
                          ? '1 victoria'
                          : '${records.gamesWon} victorias',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (bestTime == null || fewestMoves == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Aún no has ganado en este nivel. ¡Tu primer récord te espera!',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              )
            else ...[
              _RecordRow(
                icon: Icons.timer_rounded,
                title: 'Mejor tiempo',
                value: formatDuration(bestTime.elapsed, showTenths: true),
                detail:
                    '${pluralizeMoves(bestTime.moves)} · ${formatDate(bestTime.date)}',
              ),
              const SizedBox(height: 10),
              _RecordRow(
                icon: Icons.swap_horiz_rounded,
                title: 'Menos movimientos',
                value: '${fewestMoves.moves}',
                detail:
                    '${formatDuration(fewestMoves.elapsed)} · ${formatDate(fewestMoves.date)}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.labelLarge),
                Text(
                  detail,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(
              color: scheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Appear(
          effect: AppearEffect.zoomIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 56,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Todavía no hay récords',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  'Gana tu primera partida y aquí aparecerán tu mejor tiempo '
                  'y tu menor número de movimientos en cada dificultad.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
