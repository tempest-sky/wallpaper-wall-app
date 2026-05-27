import 'dart:ui';

import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = EdgeInsets.zero,
    this.opacity = 0.62,
    this.blurred = false,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final bool blurred;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final background = brightness == Brightness.dark ? scheme.surface : Colors.white;
    final radius = BorderRadius.circular(borderRadius);

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: background.withOpacity(opacity),
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.30)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withOpacity(brightness == Brightness.dark ? 0.08 : 0.42),
            background.withOpacity(opacity),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(brightness == Brightness.dark ? 0.16 : 0.08),
            blurRadius: blurred ? 22 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (!blurred) {
      return ClipRRect(borderRadius: radius, child: panel);
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: panel,
      ),
    );
  }
}