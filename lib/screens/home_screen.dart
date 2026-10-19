import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../core/app_routes.dart';
import '../models/app_theme_preference.dart';
import '../widgets/animated_menu_button.dart';
import '../widgets/appear.dart';
import '../widgets/common.dart';
import '../widgets/difficulty_picker.dart';
import '../widgets/game_logo.dart';
import '../widgets/themed_background.dart';
import 'game_screen.dart';

/// Menú principal: jugar, cambiar la dificultad y el tema.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _play(BuildContext context) async {
    final controller = AppScope.controllerOf(context);
    var settings = controller.value;

    // La primera vez se pide elegir la dificultad antes de jugar.
    if (!settings.difficultyConfirmed) {
      final picked = await showDifficultyPicker(
        context,
        initial: settings.difficulty,
      );
      if (picked == null || !context.mounted) return;
      await controller.setDifficulty(picked);
      if (!context.mounted) return;
      settings = controller.value;
    }

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

  Future<void> _chooseDifficulty(BuildContext context) async {
    final controller = AppScope.controllerOf(context);
    final picked = await showDifficultyPicker(
      context,
      initial: controller.value.difficulty,
    );
    if (picked != null) await controller.setDifficulty(picked);
  }

  void _cycleTheme(BuildContext context) {
    final controller = AppScope.controllerOf(context);
    const values = AppThemePreference.values;
    final current = controller.value.themePreference;
    controller.setThemePreference(
      values[(current.index + 1) % values.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.settingsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: ResponsiveContent(
            maxWidth: 480,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 32),
                const Appear(
                  effect: AppearEffect.bounceInDown,
                  child: Center(child: GameLogo(size: 120)),
                ),
                const SizedBox(height: 16),
                Text(
                  '15 Puzzle',
                  style: textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Appear(
                  delay: const Duration(milliseconds: 150),
                  child: AnimatedMenuButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'Jugar',
                    subtitle: settings.difficultyConfirmed
                        ? '${settings.difficulty.label} · '
                              '${settings.difficulty.summary}'
                        : null,
                    primary: true,
                    onPressed: () => _play(context),
                  ),
                ),
                const SizedBox(height: 12),
                Appear(
                  delay: const Duration(milliseconds: 250),
                  child: AnimatedMenuButton(
                    icon: Icons.grid_view_rounded,
                    label: 'Dificultad',
                    subtitle: settings.difficulty.label,
                    onPressed: () => _chooseDifficulty(context),
                  ),
                ),
                const SizedBox(height: 12),
                Appear(
                  delay: const Duration(milliseconds: 350),
                  child: AnimatedMenuButton(
                    icon: Icons.brightness_6_rounded,
                    label: 'Tema',
                    subtitle: settings.themePreference.label,
                    onPressed: () => _cycleTheme(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
