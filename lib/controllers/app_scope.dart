import 'package:flutter/material.dart';

import '../data/high_score_repository.dart';
import '../models/app_settings.dart';
import 'settings_controller.dart';

/// Pone las dependencias compartidas a disposición de todo el árbol de widgets.
///
/// Hereda de [InheritedNotifier], de modo que los widgets que leen las
/// preferencias con `listen: true` se reconstruyen automáticamente cuando el
/// [SettingsController] notifica un cambio.
class AppScope extends InheritedNotifier<SettingsController> {
  const AppScope({
    super.key,
    required SettingsController settings,
    required this.highScores,
    required super.child,
  }) : super(notifier: settings);

  final HighScoreRepository highScores;

  static AppScope _scope(BuildContext context, {required bool listen}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context.getInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw FlutterError('No se encontró AppScope en el árbol de widgets.');
    }
    return scope;
  }

  /// Preferencias actuales. Con `listen: true` (por defecto) el widget se
  /// reconstruye cuando cambian; usar `listen: false` dentro de callbacks.
  static AppSettings settingsOf(BuildContext context, {bool listen = true}) =>
      _scope(context, listen: listen).notifier!.value;

  /// Controlador para modificar las preferencias (sin suscribirse).
  static SettingsController controllerOf(BuildContext context) =>
      _scope(context, listen: false).notifier!;

  static HighScoreRepository highScoresOf(BuildContext context) =>
      _scope(context, listen: false).highScores;
}
