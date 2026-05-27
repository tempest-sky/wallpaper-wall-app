import 'package:flutter/material.dart';

import '../models/wallpaper.dart';
import 'glass_button.dart';

class SourceFilterBar extends StatelessWidget {
  const SourceFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final WallpaperSource selected;
  final ValueChanged<WallpaperSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final source = WallpaperSource.values[index];
          return GlassButton(
            icon: _iconOf(source),
            label: source.label,
            selected: source == selected,
            tooltip: source.longLabel,
            onPressed: () => onChanged(source),
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
        return Icons.public_rounded;
      case WallpaperSource.qh360:
        return Icons.filter_3_rounded;
      case WallpaperSource.bing:
        return Icons.landscape_rounded;
      case WallpaperSource.picsum:
        return Icons.photo_camera_rounded;
    }
  }
}
