import 'package:flutter/services.dart';

/// Efectos de sonido y vibración del juego. Se desactivan por completo
/// cuando el usuario apaga "Efectos de sonido" en Configuración.
class GameFeedback {
  const GameFeedback({required this.enabled});

  final bool enabled;

  void move() {
    if (!enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  void invalidMove() {
    if (!enabled) return;
    HapticFeedback.lightImpact();
  }

  void victory() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  void defeat() {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }
}
