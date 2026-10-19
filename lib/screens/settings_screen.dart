import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/app_theme_preference.dart';
import '../models/difficulty.dart';
import '../models/tile_style.dart';
import '../widgets/common.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/tile_face.dart';

/// Pantalla de Configuración.
///
/// Las preferencias viven en `SettingsController` (compartido por toda la
/// app), así que cada cambio se aplica al instante en el tema y el menú.
/// El estado local de esta pantalla es el aviso "Guardado", que confirma al
/// usuario que el cambio quedó persistido en el dispositivo.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showSaved = false;
  Timer? _savedTimer;

  @override
  void dispose() {
    _savedTimer?.cancel();
    super.dispose();
  }

  Future<void> _apply(Future<void> Function() change) async {
    await change();
    if (!mounted) return;
    setState(() => _showSaved = true);
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showSaved = false);
    });
  }

  Future<void> _resetDefaults() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Restablecer preferencias?',
      message:
          'Se recuperan la dificultad, el tema y los estilos por defecto. '
          'Tus marcadores no se borran.',
      confirmLabel: 'Restablecer',
      icon: Icons.restart_alt_rounded,
    );
    if (!confirmed || !mounted) return;
    await _apply(AppScope.controllerOf(context).resetToDefaults);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.settingsOf(context);
    final controller = AppScope.controllerOf(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showSaved
                ? Padding(
                    key: const ValueKey('saved'),
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done_rounded, color: scheme.primary, size: 20),
                        const SizedBox(width: 6),
                        Text('Guardado', style: textTheme.labelLarge),
                      ],
                    ),
                  )
                : const SizedBox(key: ValueKey('idle'), width: 16),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ResponsiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    icon: Icons.grid_view_rounded,
                    title: 'Dificultad por defecto',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<Difficulty>(
                          showSelectedIcon: false,
                          segments: [
                            for (final d in Difficulty.values)
                              ButtonSegment(
                                value: d,
                                label: Text('${d.label}\n${d.gridLabel}', textAlign: TextAlign.center),
                              ),
                          ],
                          selected: {settings.difficulty},
                          onSelectionChanged: (selection) => _apply(
                            () => controller.setDifficulty(selection.first),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            MiniGridIcon(
                              size: settings.difficulty.size,
                              color: scheme.primary,
                              extent: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${settings.difficulty.summary} · ${settings.difficulty.tagline}',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    icon: Icons.palette_outlined,
                    title: 'Tema',
                    child: SegmentedButton<AppThemePreference>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: AppThemePreference.light,
                          icon: Icon(Icons.light_mode_rounded),
                          label: Text('Claro'),
                        ),
                        ButtonSegment(
                          value: AppThemePreference.dark,
                          icon: Icon(Icons.dark_mode_rounded),
                          label: Text('Oscuro'),
                        ),
                        ButtonSegment(
                          value: AppThemePreference.system,
                          icon: Icon(Icons.brightness_auto_rounded),
                          label: Text('Auto'),
                          tooltip: 'Sigue la configuración del sistema',
                        ),
                      ],
                      selected: {settings.themePreference},
                      onSelectionChanged: (selection) => _apply(
                        () => controller.setThemePreference(selection.first),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    icon: Icons.style_outlined,
                    title: 'Estilo de las piezas',
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 520 ? 3 : 2;
                        const spacing = 12.0;
                        final width =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final style in TileStyle.values)
                              SizedBox(
                                width: width,
                                child: _StyleOption(
                                  style: style,
                                  selected: style == settings.tileStyle,
                                  onTap: () => _apply(
                                    () => controller.setTileStyle(style),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    icon: Icons.sports_esports_outlined,
                    title: 'Juego',
                    padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.hourglass_bottom_rounded),
                          title: const Text('Modo contrarreloj'),
                          subtitle: Text(
                            'Pierdes si se agota el tiempo: '
                            '${Difficulty.values.map((d) => '${d.label} ${d.timeLimit.inMinutes} min').join(' · ')}',
                          ),
                          value: settings.timeAttackEnabled,
                          onChanged: (value) => _apply(
                            () => controller.setTimeAttackEnabled(value),
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.volume_up_outlined),
                          title: const Text('Efectos de sonido y vibración'),
                          subtitle: const Text('Clic al mover piezas (sin música)'),
                          value: settings.soundEnabled,
                          onChanged: (value) =>
                              _apply(() => controller.setSoundEnabled(value)),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.animation_rounded),
                          title: const Text('Animaciones'),
                          subtitle: const Text(
                            'Desactívalas para una experiencia más rápida',
                          ),
                          value: settings.animationsEnabled,
                          onChanged: (value) => _apply(
                            () => controller.setAnimationsEnabled(value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _resetDefaults,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Restablecer preferencias'),
                  ),
                  const SizedBox(height: 12),
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

/// Tarjeta seleccionable con una vista previa del estilo de pieza.
class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final TileStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      // Para el modo imagen se muestran piezas de la fila
                      // inferior, donde el paisaje es más reconocible.
                      for (final value in style == TileStyle.image
                          ? const [13, 14, 15]
                          : const [1, 2, 3]) ...[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: TileFace(
                                value: value,
                                gridSize: 4,
                                style: style,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(style.label, style: textTheme.titleMedium),
                    ),
                    if (selected)
                      Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
                  ],
                ),
                Text(
                  style.description,
                  style: textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
