import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';

/// Efectos de aparición disponibles (basados en `animate_do`).
enum AppearEffect { fadeInUp, fadeInDown, zoomIn, elasticIn, bounceInDown }

/// Envuelve [child] en una animación de entrada que respeta la preferencia
/// "Animaciones". Si están desactivadas, muestra el contenido directamente.
class Appear extends StatelessWidget {
  const Appear({
    super.key,
    required this.child,
    this.effect = AppearEffect.fadeInUp,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
  });

  final Widget child;
  final AppearEffect effect;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final enabled = AppScope.settingsOf(context).animationsEnabled;
    if (!enabled) return child;
    return switch (effect) {
      AppearEffect.fadeInUp => FadeInUp(
        delay: delay,
        duration: duration,
        from: 24,
        child: child,
      ),
      AppearEffect.fadeInDown => FadeInDown(
        delay: delay,
        duration: duration,
        from: 24,
        child: child,
      ),
      AppearEffect.zoomIn => ZoomIn(
        delay: delay,
        duration: duration,
        child: child,
      ),
      AppearEffect.elasticIn => ElasticIn(
        delay: delay,
        duration: duration,
        child: child,
      ),
      AppearEffect.bounceInDown => BounceInDown(
        delay: delay,
        duration: duration,
        from: 60,
        child: child,
      ),
    };
  }
}
