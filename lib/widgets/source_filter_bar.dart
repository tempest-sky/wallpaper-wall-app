import 'package:flutter/material.dart';

import '../models/wallpaper.dart';

class SourceFilterBar extends StatelessWidget {
  const SourceFilterBar({super.key, required this.selected, required this.onChanged});

  final WallpaperSource selected;
  final ValueChanged<WallpaperSource> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final source = WallpaperSource.values[index];
          final active = source == selected;
          return AnimatedScale(
            scale: active ? 1.025 : 1,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: ChoiceChip(
                avatar: Icon(
                  _iconOf(source),
                  size: 17,
                  color: active ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                ),
                label: Text(source.label),
                selected: active,
                labelStyle: TextStyle(
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? scheme.onPrimaryContainer : scheme.onSurface,
                ),
                selectedColor: scheme.primaryContainer,
                backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.52),
                side: BorderSide(
                  color: active ? scheme.primary.withOpacity(0.38) : scheme.outlineVariant.withOpacity(0.32),
                ),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => onChanged(source),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: WallpaperSource.values.length,
      ),
    );
  }

  IconData _iconOf(WallpaperSource source) {
    switch (source) {
      case WallpaperSource.all:
        return Icons.all_inclusive_rounded;
      case WallpaperSource.qh360:
        return Icons.public_rounded;
      case WallpaperSource.bing:
        return Icons.landscape_rounded;
      case WallpaperSource.picsum:
        return Icons.camera_alt_rounded;
      case WallpaperSource.pexels:
        return Icons.hd_rounded;
      case WallpaperSource.yuanfang:
        return Icons.terrain_rounded;
      case WallpaperSource.yuanmeng:
        return Icons.person_pin_circle_rounded;
    }
  }
}
