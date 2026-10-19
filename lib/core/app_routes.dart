import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';

/// Transición común entre pantallas: fundido con un leve desplazamiento.
/// Si el usuario desactivó las animaciones, el cambio es instantáneo.
Route<T> buildAppRoute<T>(BuildContext context, Widget page) {
  final animate = AppScope.settingsOf(context, listen: false).animationsEnabled;
  final duration = animate
      ? const Duration(milliseconds: 320)
      : Duration.zero;
  return PageRouteBuilder<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, _, _) => page,
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
