import 'package:flutter/material.dart';

import '../models/difficulty.dart';

/// Hoja inferior para elegir dificultad antes de la primera partida.
/// Devuelve la dificultad elegida o `null` si el usuario la cierra.
Future<Difficulty?> showDifficultyPicker(
  BuildContext context, {
  required Difficulty initial,
}) {
  return showModalBottomSheet<Difficulty>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => _DifficultyPickerSheet(initial: initial),
  );
}

class _DifficultyPickerSheet extends StatelessWidget {
  const _DifficultyPickerSheet({required this.initial});

  final Difficulty initial;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige la dificultad',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'La recordaremos para tus próximas partidas. '
              'Puedes cambiarla cuando quieras en Configuración.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            for (final difficulty in Difficulty.values) ...[
              _DifficultyOption(
                difficulty: difficulty,
                selected: difficulty == initial,
                onTap: () => Navigator.of(context).pop(difficulty),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              MiniGridIcon(size: difficulty.size, color: scheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(difficulty.label, style: textTheme.titleLarge),
                    Text(
                      '${difficulty.summary} · ${difficulty.tagline}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icono de una cuadrícula n×n con el último hueco vacío.
class MiniGridIcon extends StatelessWidget {
  const MiniGridIcon({
    super.key,
    required this.size,
    required this.color,
    this.extent = 44,
  });

  final int size;
  final Color color;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final gap = extent * 0.06;
    final cell = (extent - gap * (size - 1)) / size;
    return SizedBox(
      width: extent,
      height: extent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var row = 0; row < size; row++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var col = 0; col < size; col++)
                  _cell(row * size + col, cell),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(int index, double cell) {
    final last = size * size - 1;
    return Container(
      width: cell,
      height: cell,
      decoration: BoxDecoration(
        color: index == last
            ? Colors.transparent
            : color.withValues(alpha: 0.35 + 0.65 * (index / last)),
        borderRadius: BorderRadius.circular(cell * 0.25),
      ),
    );
  }
}
