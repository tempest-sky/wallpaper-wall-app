import 'dart:ui';

import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = EdgeInsets.zero,
    this.opacity = 0.62,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final background = brightness == Brightness.dark ? scheme.surface : Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.34)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(brightness == Brightness.dark ? 0.22 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}