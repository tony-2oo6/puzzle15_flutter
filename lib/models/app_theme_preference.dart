/// Preferencia de tema elegida por el usuario.
enum AppThemePreference {
  light(label: 'Claro'),
  dark(label: 'Oscuro'),
  system(label: 'Automático');

  const AppThemePreference({required this.label});

  final String label;

  static AppThemePreference fromName(String? name) {
    return AppThemePreference.values.firstWhere(
      (preference) => preference.name == name,
      orElse: () => AppThemePreference.system,
    );
  }
}
