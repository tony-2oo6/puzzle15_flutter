import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../core/app_routes.dart';
import '../widgets/appear.dart';
import '../widgets/game_logo.dart';
import '../widgets/themed_background.dart';
import 'menu_screen.dart';

/// Pantalla de carga con el logo animado. Pasa al menú tras unos segundos
/// o al pulsar "Saltar".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El temporizador se crea aquí (y no en initState) porque necesita leer
    // las preferencias del InheritedWidget.
    _timer ??= Timer(
      AppScope.settingsOf(context, listen: false).animationsEnabled
          ? const Duration(milliseconds: 2800)
          : const Duration(milliseconds: 1200),
      _goToMenu,
    );
  }

  void _goToMenu() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timer?.cancel();
    Navigator.of(
      context,
    ).pushReplacement(buildAppRoute<void>(context, const MenuScreen()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Appear(
                        effect: AppearEffect.zoomIn,
                        duration: Duration(milliseconds: 700),
                        child: GameLogo(size: 128),
                      ),
                      const SizedBox(height: 28),
                      Appear(
                        delay: const Duration(milliseconds: 300),
                        child: Text(
                          '15-Puzzle Flutter',
                          textAlign: TextAlign.center,
                          style: textTheme.displaySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Appear(
                        delay: const Duration(milliseconds: 500),
                        child: Text(
                          'Desliza. Ordena. Gana.',
                          style: textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Appear(
                        delay: const Duration(milliseconds: 700),
                        child: SizedBox(
                          width: 160,
                          child: LinearProgressIndicator(
                            borderRadius: BorderRadius.circular(8),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: TextButton.icon(
                  onPressed: _goToMenu,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Saltar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
