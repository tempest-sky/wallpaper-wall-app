import 'package:flutter/material.dart';

import '../models/wallpaper.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final WallpaperCategory selected;
  final ValueChanged<WallpaperCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: WallpaperCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = WallpaperCategory.values[index];
          final active = category == selected;
          return FilterChip(
            selected: active,
            showCheckmark: false,
            label: Text(category.label),
            avatar: Icon(
              _iconFor(category),
              size: 18,
              color: active
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onSelected: (_) => onChanged(category),
          );
        },
      ),
    );
  }

  IconData _iconFor(WallpaperCategory category) {
    switch (category) {
      case WallpaperCategory.all:
        return Icons.auto_awesome;
      case WallpaperCategory.general:
        return Icons.landscape_rounded;
      case WallpaperCategory.anime:
        return Icons.palette_rounded;
      case WallpaperCategory.people:
        return Icons.face_4_rounded;
      case WallpaperCategory.random:
        return Icons.shuffle_rounded;
    }
  }
}