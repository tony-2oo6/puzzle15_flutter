import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/app_theme_preference.dart';
import '../models/difficulty.dart';
import '../models/tile_style.dart';

/// Lee y guarda las preferencias del usuario en almacenamiento local.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _difficultyKey = 'settings.difficulty';
  static const String _difficultyConfirmedKey = 'settings.difficultyConfirmed';
  static const String _themeKey = 'settings.theme';
  static const String _tileStyleKey = 'settings.tileStyle';
  static const String _soundKey = 'settings.sound';
  static const String _animationsKey = 'settings.animations';
  static const String _timeAttackKey = 'settings.timeAttack';

  /// Lectura síncrona: `SharedPreferences` ya cargó los valores en memoria.
  AppSettings load() {
    const defaults = AppSettings();
    return AppSettings(
      difficulty: Difficulty.fromName(_prefs.getString(_difficultyKey)),
      difficultyConfirmed:
          _prefs.getBool(_difficultyConfirmedKey) ??
          defaults.difficultyConfirmed,
      themePreference: AppThemePreference.fromName(_prefs.getString(_themeKey)),
      tileStyle: TileStyle.fromName(_prefs.getString(_tileStyleKey)),
      soundEnabled: _prefs.getBool(_soundKey) ?? defaults.soundEnabled,
      animationsEnabled:
          _prefs.getBool(_animationsKey) ?? defaults.animationsEnabled,
      timeAttackEnabled:
          _prefs.getBool(_timeAttackKey) ?? defaults.timeAttackEnabled,
    );
  }

  Future<void> save(AppSettings settings) async {
    await Future.wait<bool>([
      _prefs.setString(_difficultyKey, settings.difficulty.name),
      _prefs.setBool(_difficultyConfirmedKey, settings.difficultyConfirmed),
      _prefs.setString(_themeKey, settings.themePreference.name),
      _prefs.setString(_tileStyleKey, settings.tileStyle.name),
      _prefs.setBool(_soundKey, settings.soundEnabled),
      _prefs.setBool(_animationsKey, settings.animationsEnabled),
      _prefs.setBool(_timeAttackKey, settings.timeAttackEnabled),
    ]);
  }
}
