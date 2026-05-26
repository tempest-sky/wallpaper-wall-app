import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/wallpaper.dart';
import 'wallpaper_card.dart';

class WallpaperGrid extends StatelessWidget {
  const WallpaperGrid({
    super.key,
    required this.wallpapers,
    required this.selected,
    required this.onSelect,
    required this.onPlay,
    required this.onSave,
    required this.onLoadMore,
    required this.loading,
  });

  final List<Wallpaper> wallpapers;
  final Wallpaper? selected;
  final ValueChanged<Wallpaper> onSelect;
  final ValueChanged<Wallpaper> onPlay;
  final ValueChanged<Wallpaper> onSave;
  final VoidCallback onLoadMore;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (wallpapers.isEmpty && loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (wallpapers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.wallpaper_rounded, size: 52),
              const SizedBox(height: 12),
              Text('暂无壁纸', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.cloud_download_rounded),
                label: const Text('抓取壁纸'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final crossAxisCount = width >= 920 ? 3 : 2;
          return SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childCount: wallpapers.length + 1,
            itemBuilder: (context, index) {
              if (index == wallpapers.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator()
                        : FilledButton.icon(
                            onPressed: onLoadMore,
                            icon: const Icon(Icons.add_photo_alternate_rounded),
                            label: const Text('继续抓取'),
                          ),
                  ),
                );
              }

              final wallpaper = wallpapers[index];
              return WallpaperCard(
                wallpaper: wallpaper,
                selected: selected?.id == wallpaper.id,
                onSelect: () => onSelect(wallpaper),
                onPlay: () => onPlay(wallpaper),
                onSave: () => onSave(wallpaper),
              );
            },
          );
        },
      ),
    );
  }
}