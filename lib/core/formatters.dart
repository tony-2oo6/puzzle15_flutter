String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// `mm:ss` (o `h:mm:ss` si pasa de una hora). Con [showTenths] añade décimas.
String formatDuration(Duration duration, {bool showTenths = false}) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  final base = hours > 0
      ? '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}'
      : '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  if (!showTenths) return base;
  final tenths = duration.inMilliseconds.remainder(1000) ~/ 100;
  return '$base.$tenths';
}

/// Fecha corta en formato local hispano: `17/10/2026 · 12:54`.
String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${_twoDigits(local.day)}/${_twoDigits(local.month)}/${local.year}'
      ' · ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
}

/// "1 movimiento" / "12 movimientos".
String pluralizeMoves(int moves) =>
    moves == 1 ? '1 movimiento' : '$moves movimientos';
