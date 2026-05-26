enum WallpaperCategory {
  all,
  general,
  anime,
  people,
  random,
}

extension WallpaperCategoryLabel on WallpaperCategory {
  String get label {
    switch (this) {
      case WallpaperCategory.all:
        return '全部';
      case WallpaperCategory.general:
        return '综合';
      case WallpaperCategory.anime:
        return '二次元';
      case WallpaperCategory.people:
        return '人物';
      case WallpaperCategory.random:
        return '随机';
    }
  }

  String get sourceLabel {
    switch (this) {
      case WallpaperCategory.all:
        return '360 · 混合分类';
      case WallpaperCategory.general:
        return '360 · 风景大片';
      case WallpaperCategory.anime:
        return '360 · 动漫卡通';
      case WallpaperCategory.people:
        return '360 · 美女模特';
      case WallpaperCategory.random:
        return '360 · 4K 专区';
    }
  }
}

class Wallpaper {
  const Wallpaper({
    required this.id,
    required this.name,
    required this.url,
    required this.downloadUrl,
    required this.width,
    required this.height,
    required this.category,
    required this.origin,
  });

  final String id;
  final String name;
  final String url;
  final String downloadUrl;
  final int width;
  final int height;
  final WallpaperCategory category;
  final String origin;

  double get aspectRatio {
    if (height == 0) return 16 / 9;
    return width / height;
  }
}