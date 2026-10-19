import 'app_theme_preference.dart';
import 'difficulty.dart';
import 'tile_style.dart';

/// Preferencias del usuario. Es inmutable: para cambiar un valor se crea una
/// copia con [copyWith], lo que facilita comparar estados y persistirlos.
class AppSettings {
  const AppSettings({
    this.difficulty = Difficulty.medium,
    this.difficultyConfirmed = false,
    this.themePreference = AppThemePreference.system,
    this.tileStyle = TileStyle.classic,
    this.soundEnabled = true,
    this.animationsEnabled = true,
    this.timeAttackEnabled = false,
  });

  /// Dificultad por defecto al pulsar "Jugar".
  final Difficulty difficulty;

  /// `true` cuando el usuario ya eligió una dificultad alguna vez. Si es
  /// `false`, al pulsar "Jugar" se le pide elegirla primero.
  final bool difficultyConfirmed;

  final AppThemePreference themePreference;
  final TileStyle tileStyle;

  /// Efectos de sonido y vibración al mover piezas.
  final bool soundEnabled;
  final bool animationsEnabled;

  /// Modo contrarreloj: la partida se pierde si se agota el tiempo.
  final bool timeAttackEnabled;

  AppSettings copyWith({
    Difficulty? difficulty,
    bool? difficultyConfirmed,
    AppThemePreference? themePreference,
    TileStyle? tileStyle,
    bool? soundEnabled,
    bool? animationsEnabled,
    bool? timeAttackEnabled,
  }) {
    return AppSettings(
      difficulty: difficulty ?? this.difficulty,
      difficultyConfirmed: difficultyConfirmed ?? this.difficultyConfirmed,
      themePreference: themePreference ?? this.themePreference,
      tileStyle: tileStyle ?? this.tileStyle,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      timeAttackEnabled: timeAttackEnabled ?? this.timeAttackEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.difficulty == difficulty &&
        other.difficultyConfirmed == difficultyConfirmed &&
        other.themePreference == themePreference &&
        other.tileStyle == tileStyle &&
        other.soundEnabled == soundEnabled &&
        other.animationsEnabled == animationsEnabled &&
        other.timeAttackEnabled == timeAttackEnabled;
  }

  @override
  int get hashCode => Object.hash(
    difficulty,
    difficultyConfirmed,
    themePreference,
    tileStyle,
    soundEnabled,
    animationsEnabled,
    timeAttackEnabled,
  );
}
