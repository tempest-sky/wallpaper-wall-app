import 'package:flutter/material.dart';

import '../models/wallpaper.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.source,
    required this.onChanged,
  });

  final WallpaperCategory selected;
  final WallpaperSource source;
  final ValueChanged<WallpaperCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = _categoriesFor(source);
    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = category == selected;
          return FilterChip(
            selected: active,
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
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

  List<WallpaperCategory> _categoriesFor(WallpaperSource source) {
    if (source == WallpaperSource.pexels) {
      return const <WallpaperCategory>[
        WallpaperCategory.all,
        WallpaperCategory.pexelsWallpaper,
        WallpaperCategory.pexelsBackground,
        WallpaperCategory.pexelsFlowers,
        WallpaperCategory.pexelsLandscape,
        WallpaperCategory.pexelsNature,
        WallpaperCategory.pexelsCity,
        WallpaperCategory.pexelsPortrait,
        WallpaperCategory.pexelsAnimals,
        WallpaperCategory.pexelsMinimal,
        WallpaperCategory.pexelsAbstract,
      ];
    }
    return const <WallpaperCategory>[
      WallpaperCategory.all,
      WallpaperCategory.general,
      WallpaperCategory.anime,
      WallpaperCategory.people,
      WallpaperCategory.random,
    ];
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
      case WallpaperCategory.pexelsWallpaper:
        return Icons.wallpaper_rounded;
      case WallpaperCategory.pexelsBackground:
        return Icons.layers_rounded;
      case WallpaperCategory.pexelsFlowers:
        return Icons.local_florist_rounded;
      case WallpaperCategory.pexelsLandscape:
        return Icons.terrain_rounded;
      case WallpaperCategory.pexelsNature:
        return Icons.eco_rounded;
      case WallpaperCategory.pexelsCity:
        return Icons.location_city_rounded;
      case WallpaperCategory.pexelsPortrait:
        return Icons.person_rounded;
      case WallpaperCategory.pexelsAnimals:
        return Icons.pets_rounded;
      case WallpaperCategory.pexelsMinimal:
        return Icons.crop_square_rounded;
      case WallpaperCategory.pexelsAbstract:
        return Icons.blur_on_rounded;
    }
  }
}