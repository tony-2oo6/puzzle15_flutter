import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../core/app_routes.dart';
import '../widgets/animated_menu_button.dart';
import '../widgets/appear.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/game_logo.dart';
import '../widgets/themed_background.dart';
import 'game_screen.dart';
import 'high_scores_screen.dart';
import 'instructions_screen.dart';
import 'settings_screen.dart';

/// Menú principal. No guarda estado propio: lee las preferencias del
/// `AppScope` y se reconstruye solo cuando cambian (por ejemplo, al volver
/// de Configuración con otra dificultad).
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _play(BuildContext context, {bool choose = false}) async {
    final controller = AppScope.controllerOf(context);
    if (choose || !controller.value.difficultyConfirmed) {
      final picked = await showDifficultyPicker(
        context,
        initial: controller.value.difficulty,
      );
      if (picked == null) return;
      await controller.setDifficulty(picked);
    }
    if (!context.mounted) return;
    final settings = controller.value;
    await Navigator.of(context).push(
      buildAppRoute<void>(
        context,
        GameScreen(
          difficulty: settings.difficulty,
          timeAttack: settings.timeAttackEnabled,
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(buildAppRoute<void>(context, page));
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.settingsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final difficulty = settings.difficulty;
    final playSubtitle = settings.difficultyConfirmed
        ? '${difficulty.label} · ${difficulty.gridLabel}'
              '${settings.timeAttackEnabled ? ' · Contrarreloj' : ''}'
        : 'Elige tu dificultad y empieza';

    const step = Duration(milliseconds: 90);

    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Appear(
                        effect: AppearEffect.bounceInDown,
                        child: GameLogo(size: 92),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Appear(
                      effect: AppearEffect.fadeInDown,
                      delay: step,
                      child: Text(
                        '15-Puzzle',
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    Appear(
                      effect: AppearEffect.fadeInDown,
                      delay: step * 2,
                      child: Text(
                        'Ordena las piezas en el menor tiempo posible',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Appear(
                      delay: step * 3,
                      child: AnimatedMenuButton(
                        primary: true,
                        icon: Icons.play_arrow_rounded,
                        label: 'Jugar',
                        subtitle: playSubtitle,
                        onPressed: () => _play(context),
                      ),
                    ),
                    if (settings.difficultyConfirmed)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _play(context, choose: true),
                          child: const Text('Cambiar dificultad'),
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                    Appear(
                      delay: step * 4,
                      child: AnimatedMenuButton(
                        icon: Icons.emoji_events_rounded,
                        label: 'Marcadores',
                        subtitle: 'Tus mejores tiempos y movimientos',
                        onPressed: () =>
                            _open(context, const HighScoresScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Appear(
                      delay: step * 5,
                      child: AnimatedMenuButton(
                        icon: Icons.tune_rounded,
                        label: 'Configuración',
                        subtitle: 'Dificultad, tema y estilo de piezas',
                        onPressed: () => _open(context, const SettingsScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Appear(
                      delay: step * 6,
                      child: AnimatedMenuButton(
                        icon: Icons.menu_book_rounded,
                        label: 'Cómo jugar',
                        subtitle: 'Reglas, controles y consejos',
                        onPressed: () =>
                            _open(context, const InstructionsScreen()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'v1.0.0 · Hecho con Flutter',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
