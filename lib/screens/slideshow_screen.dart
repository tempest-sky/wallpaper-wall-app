import 'package:flutter/material.dart';

import '../models/wallpaper.dart';
import '../widgets/slideshow_viewer.dart';

class SlideshowScreen extends StatelessWidget {
  const SlideshowScreen({
    super.key,
    required this.wallpapers,
    required this.initialWallpaper,
  });

  final List<Wallpaper> wallpapers;
  final Wallpaper initialWallpaper;

  @override
  Widget build(BuildContext context) {
    final index = wallpapers.indexWhere((item) => item.id == initialWallpaper.id);
    return SlideshowViewer(
      wallpapers: wallpapers,
      initialIndex: index < 0 ? 0 : index,
      onClose: () => Navigator.of(context).maybePop(),
    );
  }
}