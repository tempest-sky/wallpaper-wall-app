enum WallpaperCategory {
  all,
  general,
  anime,
  people,
  random,
}

enum WallpaperSource {
  all,
  qh360,
  bing,
  picsum,
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
        return '混合内容';
      case WallpaperCategory.general:
        return '风景大片';
      case WallpaperCategory.anime:
        return '动漫卡通';
      case WallpaperCategory.people:
        return '人物写真';
      case WallpaperCategory.random:
        return '随机精选';
    }
  }
}

extension WallpaperSourceLabel on WallpaperSource {
  String get label {
    switch (this) {
      case WallpaperSource.all:
        return '全部来源';
      case WallpaperSource.qh360:
        return '360';
      case WallpaperSource.bing:
        return 'Bing';
      case WallpaperSource.picsum:
        return 'Picsum';
    }
  }

  String get longLabel {
    switch (this) {
      case WallpaperSource.all:
        return '全部来源';
      case WallpaperSource.qh360:
        return '360 壁纸';
      case WallpaperSource.bing:
        return 'Bing 每日壁纸';
      case WallpaperSource.picsum:
        return 'Picsum 随机摄影';
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
    required this.source,
    required this.origin,
  });

  final String id;
  final String name;
  final String url;
  final String downloadUrl;
  final int width;
  final int height;
  final WallpaperCategory category;
  final WallpaperSource source;
  final String origin;

  double get aspectRatio {
    if (height == 0) return 16 / 9;
    return width / height;
  }
}