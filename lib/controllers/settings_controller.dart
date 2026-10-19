import 'package:flutter/material.dart';

import '../data/settings_repository.dart';
import '../models/app_settings.dart';
import '../models/app_theme_preference.dart';
import '../models/difficulty.dart';
import '../models/tile_style.dart';

/// Fuente única de verdad para las preferencias.
///
/// Las preferencias afectan a toda la app (tema, estilo de piezas,
/// animaciones), así que se exponen con un [ChangeNotifier] a través de
/// `AppScope`. Así cualquier pantalla se actualiza al instante cuando cambian,
/// sin pasar callbacks de pantalla en pantalla.
class SettingsController extends ChangeNotifier {
  SettingsController(this._repository) : _settings = _repository.load();

  final SettingsRepository _repository;
  AppSettings _settings;

  AppSettings get value => _settings;

  Future<void> _update(AppSettings next) async {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
    await _repository.save(next);
  }

  /// Cambia la dificultad por defecto y la marca como elegida.
  Future<void> setDifficulty(Difficulty difficulty) => _update(
    _settings.copyWith(difficulty: difficulty, difficultyConfirmed: true),
  );

  Future<void> setThemePreference(AppThemePreference preference) =>
      _update(_settings.copyWith(themePreference: preference));

  Future<void> setTileStyle(TileStyle style) =>
      _update(_settings.copyWith(tileStyle: style));

  Future<void> setSoundEnabled(bool enabled) =>
      _update(_settings.copyWith(soundEnabled: enabled));

  Future<void> setAnimationsEnabled(bool enabled) =>
      _update(_settings.copyWith(animationsEnabled: enabled));

  Future<void> setTimeAttackEnabled(bool enabled) =>
      _update(_settings.copyWith(timeAttackEnabled: enabled));

  Future<void> resetToDefaults() => _update(const AppSettings());
}
