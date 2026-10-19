import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';

/// Botón grande del menú con animación de presión (escala y cambio de
/// color), efecto hover en escritorio/web y soporte de teclado.
class AnimatedMenuButton extends StatefulWidget {
  const AnimatedMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.subtitle,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onPressed;

  /// Destaca el botón con el color principal (acción "Jugar").
  final bool primary;

  @override
  State<AnimatedMenuButton> createState() => _AnimatedMenuButtonState();
}

class _AnimatedMenuButtonState extends State<AnimatedMenuButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final animate = AppScope.settingsOf(context).animationsEnabled;
    final duration = animate
        ? const Duration(milliseconds: 130)
        : Duration.zero;

    final baseColor = widget.primary ? scheme.primary : scheme.surfaceContainerHigh;
    final hoverColor = widget.primary
        ? Color.lerp(scheme.primary, Colors.white, 0.08)!
        : scheme.surfaceContainerHighest;
    final pressedColor = widget.primary
        ? Color.lerp(scheme.primary, Colors.black, 0.2)!
        : scheme.secondaryContainer;
    final foreground = widget.primary ? scheme.onPrimary : scheme.onSurface;
    final color = _pressed
        ? pressedColor
        : _hovered
        ? hoverColor
        : baseColor;
    final subtitle = widget.subtitle;

    return AnimatedScale(
        scale: _pressed ? 0.95 : (_hovered ? 1.02 : 1),
        duration: duration,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: duration,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: (widget.primary ? scheme.primary : scheme.shadow)
                    .withValues(alpha: _pressed ? 0.08 : 0.16),
                blurRadius: _pressed ? 6 : 18,
                offset: Offset(0, _pressed ? 2 : 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: widget.onPressed,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              onHover: (value) => setState(() => _hovered = value),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 72),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(widget.icon, color: foreground),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: textTheme.titleMedium?.copyWith(
                                color: foreground,
                                fontSize: 18,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                style: textTheme.bodySmall?.copyWith(
                                  color: foreground.withValues(alpha: 0.75),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: foreground.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}
