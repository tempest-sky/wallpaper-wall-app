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
    required this.onOpenOriginal,
    required this.onSave,
    this.batchMode = false,
    this.batchSelectedIds = const <String>{},
    required this.loading,
    this.batchMode = false,
    this.batchSelectedIds = const <String>{},
  });

  final List<Wallpaper> wallpapers;
  final Wallpaper? selected;
  final ValueChanged<Wallpaper> onSelect;
  final ValueChanged<Wallpaper> onOpenOriginal;
  final ValueChanged<Wallpaper> onSave;
  final bool loading;
  final bool batchMode;
  final Set<String> batchSelectedIds;

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
              const Icon(Icons.wallpaper_rounded, size: 48),
              const SizedBox(height: 10),
              Text('暂无壁纸', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('下拉刷新或切换分类', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 102),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final crossAxisCount = width >= 980 ? 3 : 2;
          final gap = width < 390 ? 10.0 : 14.0;
          return SliverMasonryGrid.count(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childCount: wallpapers.length + 1,
            itemBuilder: (context, index) {
              if (index == wallpapers.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: loading
                        ? const SizedBox.square(
                            dimension: 26,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(
                            '继续下滑自动加载',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                  ),
                );
              }

              final wallpaper = wallpapers[index];
              return WallpaperCard(
                wallpaper: wallpaper,
                selected: selected?.id == wallpaper.id,
                batchMode: batchMode,
                batchSelected: batchSelectedIds.contains(wallpaper.id),
                onSelect: () => onSelect(wallpaper),
                onOpenOriginal: () => onOpenOriginal(wallpaper),
                onSave: () => onSave(wallpaper),
              );
            },
          );
        },
      ),
    );
  }
}