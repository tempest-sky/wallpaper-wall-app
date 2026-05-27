import 'package:flutter/material.dart';

import 'glass_panel.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    this.label,
    this.onPressed,
    this.selected = false,
    this.tooltip,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final foreground = enabled
        ? (selected ? scheme.primary : scheme.onSurface)
        : scheme.onSurface.withOpacity(0.36);

    final content = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: GlassPanel(
        borderRadius: 999,
        opacity: enabled ? (selected ? 0.72 : 0.50) : 0.24,
        padding: EdgeInsets.symmetric(horizontal: label == null ? 10 : 8, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 18, color: foreground),
            if (label != null) ...<Widget>[
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label!,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Tooltip(message: tooltip ?? label ?? '', child: content);
  }
}