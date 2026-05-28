enum WallpaperCategory {
  all,
  general,
  anime,
  people,
  random,
  pexelsWallpaper,
  pexelsBackground,
  pexelsFlowers,
  pexelsLandscape,
  pexelsNature,
  pexelsCity,
  pexelsPortrait,
  pexelsAnimals,
  pexelsMinimal,
  pexelsAbstract,
}

enum WallpaperSource {
  all,
  qh360,
  bing,
  picsum,
  pexels,
  yuanfang,
  yuanmeng,
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
      case WallpaperCategory.pexelsWallpaper:
        return '壁纸';
      case WallpaperCategory.pexelsBackground:
        return '背景';
      case WallpaperCategory.pexelsFlowers:
        return '花卉';
      case WallpaperCategory.pexelsLandscape:
        return '景观';
      case WallpaperCategory.pexelsNature:
        return '自然';
      case WallpaperCategory.pexelsCity:
        return '城市';
      case WallpaperCategory.pexelsPortrait:
        return '人像';
      case WallpaperCategory.pexelsAnimals:
        return '动物';
      case WallpaperCategory.pexelsMinimal:
        return '极简';
      case WallpaperCategory.pexelsAbstract:
        return '抽象';
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
      case WallpaperCategory.pexelsWallpaper:
        return 'Pexels 壁纸';
      case WallpaperCategory.pexelsBackground:
        return 'Pexels 背景';
      case WallpaperCategory.pexelsFlowers:
        return 'Pexels 花卉';
      case WallpaperCategory.pexelsLandscape:
        return 'Pexels 景观';
      case WallpaperCategory.pexelsNature:
        return 'Pexels 自然';
      case WallpaperCategory.pexelsCity:
        return 'Pexels 城市';
      case WallpaperCategory.pexelsPortrait:
        return 'Pexels 人像';
      case WallpaperCategory.pexelsAnimals:
        return 'Pexels 动物';
      case WallpaperCategory.pexelsMinimal:
        return 'Pexels 极简';
      case WallpaperCategory.pexelsAbstract:
        return 'Pexels 抽象';
    }
  }
  bool get isPexelsCategory {
    switch (this) {
      case WallpaperCategory.pexelsWallpaper:
      case WallpaperCategory.pexelsBackground:
      case WallpaperCategory.pexelsFlowers:
      case WallpaperCategory.pexelsLandscape:
      case WallpaperCategory.pexelsNature:
      case WallpaperCategory.pexelsCity:
      case WallpaperCategory.pexelsPortrait:
      case WallpaperCategory.pexelsAnimals:
      case WallpaperCategory.pexelsMinimal:
      case WallpaperCategory.pexelsAbstract:
        return true;
      case WallpaperCategory.all:
      case WallpaperCategory.general:
      case WallpaperCategory.anime:
      case WallpaperCategory.people:
      case WallpaperCategory.random:
        return false;
    }
  }

  String get pexelsQuery {
    switch (this) {
      case WallpaperCategory.pexelsWallpaper:
        return 'wallpaper';
      case WallpaperCategory.pexelsBackground:
        return 'background';
      case WallpaperCategory.pexelsFlowers:
        return 'flowers';
      case WallpaperCategory.pexelsLandscape:
        return 'landscape';
      case WallpaperCategory.pexelsNature:
        return 'nature';
      case WallpaperCategory.pexelsCity:
        return 'city';
      case WallpaperCategory.pexelsPortrait:
        return 'portrait';
      case WallpaperCategory.pexelsAnimals:
        return 'animals';
      case WallpaperCategory.pexelsMinimal:
        return 'minimal';
      case WallpaperCategory.pexelsAbstract:
        return 'abstract';
      case WallpaperCategory.all:
      case WallpaperCategory.general:
      case WallpaperCategory.anime:
      case WallpaperCategory.people:
      case WallpaperCategory.random:
        return 'nature wallpaper';
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
      case WallpaperSource.pexels:
        return 'Pexels';
      case WallpaperSource.yuanfang:
        return '远方';
      case WallpaperSource.yuanmeng:
        return '远梦';
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
      case WallpaperSource.pexels:
        return 'Pexels 高清图库';
      case WallpaperSource.yuanfang:
        return '远方随机风景';
      case WallpaperSource.yuanmeng:
        return '远梦网红壁纸';
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
    this.authorName,
    this.authorUrl,
    this.sourceUrl,
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
  final String? authorName;
  final String? authorUrl;
  final String? sourceUrl;

  double get aspectRatio {
    if (height == 0) return 16 / 9;
    return width / height;
  }
}
