import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/wallpaper.dart';

class WallpaperApiService {
  static const String _endpoint360 = 'http://wallpaper.apc.360.cn/index.php';
  static const String _bingEndpoint = 'https://www.bing.com/HPImageArchive.aspx';
  static const String _picsumEndpoint = 'https://picsum.photos/v2/list';
  static const String _pexelsEndpoint = 'https://api.pexels.com/v1/search';
  static const String _pexelsApiKey = String.fromEnvironment('PEXELS_API_KEY');
  static const String _yuanfangEndpoint = 'https://tu.ltyuanfang.cn/api/fengjing.php';
  static const String _yuanmengEndpoint = 'https://api.mmp.cc/api/kswallpaper';

  static const int perCategoryCount = 30;
  static const int mixedCount = 120;

  static const Map<WallpaperCategory, int> _categoryCid = {
    WallpaperCategory.general: 9,
    WallpaperCategory.anime: 26,
    WallpaperCategory.people: 6,
    WallpaperCategory.random: 36,
  };

  static const List<int> _mixedCids = <int>[9, 15, 26, 6, 36, 14, 12, 10];

  Future<List<Wallpaper>> fetchWallpapers({
    WallpaperCategory category = WallpaperCategory.all,
    WallpaperSource source = WallpaperSource.all,
    int start = 0,
    required int seed,
  }) async {
    if (source != WallpaperSource.all) {
      return _fetchBySource(source: source, category: category, start: start, seed: seed);
    }

    if (category == WallpaperCategory.all) {
      return _fetchMixed(start: start, seed: seed);
    }

    final cid = _categoryCid[category] ?? 9;
    return _fetchByCid(
      cid: cid,
      category: category,
      start: _random360Start(seed: seed, start: start, cid: cid),
      count: perCategoryCount,
    );
  }

  Future<List<Wallpaper>> _fetchBySource({
    required WallpaperSource source,
    required WallpaperCategory category,
    required int start,
    required int seed,
  }) async {
    switch (source) {
      case WallpaperSource.all:
        return fetchWallpapers(category: category, start: start, seed: seed);
      case WallpaperSource.qh360:
        if (category == WallpaperCategory.all) {
          return _fetchMixed360(start: start, seed: seed);
        }
        final cid = _categoryCid[category] ?? 9;
        return _fetchByCid(
          cid: cid,
          category: category,
          start: _random360Start(seed: seed, start: start, cid: cid),
          count: perCategoryCount,
        );
      case WallpaperSource.bing:
        return _fetchBing(start: start, seed: seed);
      case WallpaperSource.picsum:
        return _fetchPicsum(start: start, seed: seed);
      case WallpaperSource.pexels:
        return _fetchPexels(start: start, seed: seed);
      case WallpaperSource.yuanfang:
        return _fetchYuanfang(start: start, seed: seed);
      case WallpaperSource.yuanmeng:
        return _fetchYuanmeng(start: start, seed: seed);
    }
  }

  Future<List<Wallpaper>> _fetchMixed360({required int start, required int seed}) async {
    final batches = await Future.wait(
      _mixedCids.map(
        (cid) => _fetchByCid(
          cid: cid,
          category: _categoryFromCid(cid),
          start: _random360Start(seed: seed, start: start, cid: cid),
          count: 10,
        ).catchError((_) => <Wallpaper>[]),
      ),
    );
    return batches.expand((batch) => batch).toList();
  }

  Future<List<Wallpaper>> _fetchMixed({required int start, required int seed}) async {
    final futures = <Future<List<Wallpaper>>>[
      ..._mixedCids.map(
        (cid) => _fetchByCid(
          cid: cid,
          category: _categoryFromCid(cid),
          start: _random360Start(seed: seed, start: start, cid: cid),
          count: 10,
        ).catchError((_) => <Wallpaper>[]),
      ),
      _fetchBing(start: start, seed: seed).catchError((_) => <Wallpaper>[]),
      _fetchPicsum(start: start, seed: seed).catchError((_) => <Wallpaper>[]),
      if (_pexelsApiKey.isNotBlank) _fetchPexels(start: start, seed: seed).catchError((_) => <Wallpaper>[]),
      _fetchYuanfang(start: start, seed: seed).catchError((_) => <Wallpaper>[]),
      _fetchYuanmeng(start: start, seed: seed).catchError((_) => <Wallpaper>[]),
    ];

    final batches = await Future.wait(futures);
    final unique = <String, Wallpaper>{};
    for (final batch in batches) {
      for (final wallpaper in batch) {
        unique[wallpaper.downloadUrl] = wallpaper;
      }
    }

    final list = unique.values.toList()..shuffle(Random(seed + start + 7));
    if (list.length <= mixedCount) return list;
    return list.take(mixedCount).toList();
  }

  Future<List<Wallpaper>> _fetchByCid({
    required int cid,
    required WallpaperCategory category,
    required int start,
    required int count,
  }) async {
    final uri = Uri.parse(_endpoint360).replace(
      queryParameters: <String, String>{
        'c': 'WallPaper',
        'a': 'getAppsByCategory',
        'cid': '$cid',
        'start': '$start',
        'count': '$count',
        'from': '360chrome',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw WallpaperApiException('360 API 请求失败：HTTP ${response.statusCode}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['errno'] != '0' && payload['errno'] != 0) {
      throw WallpaperApiException('360 API 返回异常：${payload['errmsg'] ?? payload['errno']}');
    }

    final data = payload['data'];
    if (data is! List) return <Wallpaper>[];

    return data
        .whereType<Map<String, dynamic>>()
        .map((item) => _to360Wallpaper(item, category))
        .where((wallpaper) => wallpaper.url.isNotEmpty)
        .toList();
  }

  Future<List<Wallpaper>> _fetchBing({required int start, required int seed}) async {
    final uri = Uri.parse(_bingEndpoint).replace(
      queryParameters: <String, String>{
        'format': 'js',
        'idx': '${((seed ~/ 17) + start) % 8}',
        'n': '8',
        'mkt': 'zh-CN',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return <Wallpaper>[];

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final images = payload['images'];
    if (images is! List) return <Wallpaper>[];

    final list = images.whereType<Map<String, dynamic>>().map((item) {
      final urlPart = '${item['url'] ?? ''}';
      final url = urlPart.startsWith('http') ? urlPart : 'https://www.bing.com$urlPart';
      final title = '${item['title'] ?? item['copyright'] ?? 'Bing 每日壁纸'}';
      final id = 'bing-${item['startdate'] ?? url.hashCode}';
      return Wallpaper(
        id: id,
        name: title.isBlank ? 'Bing 每日壁纸' : title,
        url: url,
        downloadUrl: url,
        width: 1920,
        height: 1080,
        category: WallpaperCategory.general,
        source: WallpaperSource.bing,
        origin: '1920×1080 · Bing 每日壁纸',
      );
    }).toList();

    return list..shuffle(Random(seed + start + 31));
  }

  Future<List<Wallpaper>> _fetchPicsum({required int start, required int seed}) async {
    final pageOffset = (seed.abs() % 80) + 1;
    final page = pageOffset + (start ~/ 20);
    final uri = Uri.parse(_picsumEndpoint).replace(
      queryParameters: <String, String>{
        'page': '$page',
        'limit': '20',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return <Wallpaper>[];

    final data = jsonDecode(response.body);
    if (data is! List) return <Wallpaper>[];

    final list = data.whereType<Map<String, dynamic>>().map((item) {
      final id = 'picsum-${item['id'] ?? item.hashCode}';
      final author = '${item['author'] ?? 'Unknown'}';
      final width = int.tryParse('${item['width'] ?? 1080}') ?? 1080;
      final height = int.tryParse('${item['height'] ?? 1920}') ?? 1920;
      final imageSeed = item['id'] ?? '$id-$seed';
      final imageUrl = 'https://picsum.photos/seed/$imageSeed/1080/1920';
      return Wallpaper(
        id: id,
        name: '随机摄影 · $author',
        url: imageUrl,
        downloadUrl: imageUrl,
        width: width,
        height: height,
        category: WallpaperCategory.random,
        source: WallpaperSource.picsum,
        origin: '$width×$height · Picsum 随机图',
      );
    }).toList();

    return list..shuffle(Random(seed + start + 53));
  }

  Future<List<Wallpaper>> _fetchPexels({required int start, required int seed}) async {
    if (_pexelsApiKey.isBlank) {
      throw const WallpaperApiException('Pexels API Key 未配置：请通过 --dart-define=PEXELS_API_KEY 或 GitHub Secret 注入');
    }

    final queries = <String>['nature wallpaper', 'landscape', 'mountain', 'ocean', 'city night', 'forest'];
    final query = queries[(seed + start).abs() % queries.length];
    final page = ((seed.abs() + start) % 40) + 1;
    final uri = Uri.parse(_pexelsEndpoint).replace(
      queryParameters: <String, String>{
        'query': query,
        'orientation': 'portrait',
        'per_page': '24',
        'page': '$page',
      },
    );

    final response = await http
        .get(uri, headers: const <String, String>{'Authorization': _pexelsApiKey})
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return <Wallpaper>[];

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final photos = payload['photos'];
    if (photos is! List) return <Wallpaper>[];

    final list = photos.whereType<Map<String, dynamic>>().map((item) {
      final id = 'pexels-${item['id'] ?? item.hashCode}';
      final src = item['src'];
      final original = src is Map<String, dynamic> ? '${src['original'] ?? src['large2x'] ?? src['large'] ?? ''}' : '';
      final display = src is Map<String, dynamic> ? '${src['large2x'] ?? src['large'] ?? original}' : original;
      final width = int.tryParse('${item['width'] ?? 1080}') ?? 1080;
      final height = int.tryParse('${item['height'] ?? 1920}') ?? 1920;
      final photographer = '${item['photographer'] ?? 'Pexels'}';
      final photographerUrl = '${item['photographer_url'] ?? ''}';
      final pageUrl = '${item['url'] ?? ''}';
      return Wallpaper(
        id: id,
        name: 'Pexels · $photographer',
        url: display,
        downloadUrl: original.isBlank ? display : original,
        width: width,
        height: height,
        category: WallpaperCategory.general,
        source: WallpaperSource.pexels,
        origin: '$width×$height · Photo by $photographer on Pexels',
        authorName: photographer,
        authorUrl: photographerUrl.isBlank ? null : photographerUrl,
        sourceUrl: pageUrl.isBlank ? 'https://www.pexels.com' : pageUrl,
      );
    }).where((wallpaper) => wallpaper.url.isNotEmpty).toList();

    return list..shuffle(Random(seed + start + 71));
  }

  Future<List<Wallpaper>> _fetchYuanfang({required int start, required int seed}) async {
    return List<Wallpaper>.generate(12, (index) {
      final nonce = seed + start + index;
      final imageUrl = '$_yuanfangEndpoint?_t=$nonce';
      return Wallpaper(
        id: 'yuanfang-$nonce',
        name: '远方随机风景',
        url: imageUrl,
        downloadUrl: imageUrl,
        width: 2160,
        height: 3840,
        category: WallpaperCategory.general,
        source: WallpaperSource.yuanfang,
        origin: '4K 风景 · 远方随机 API',
      );
    });
  }

  Future<List<Wallpaper>> _fetchYuanmeng({required int start, required int seed}) async {
    const categories = <String>['kuaishou', 'taobao', 'meizi', 'cos'];
    return List<Wallpaper>.generate(16, (index) {
      final category = categories[(seed + start + index).abs() % categories.length];
      final nonce = seed + start + index;
      final imageUrl = Uri.parse(_yuanmengEndpoint).replace(
        queryParameters: <String, String>{
          'category': category,
          'type': 'jpg',
          '_t': '$nonce',
        },
      ).toString();
      return Wallpaper(
        id: 'yuanmeng-$category-$nonce',
        name: '远梦网红壁纸 · $category',
        url: imageUrl,
        downloadUrl: imageUrl,
        width: 1080,
        height: 1920,
        category: WallpaperCategory.people,
        source: WallpaperSource.yuanmeng,
        origin: '手机竖屏 · 远梦网红壁纸',
      );
    });
  }

  Wallpaper _to360Wallpaper(Map<String, dynamic> item, WallpaperCategory fallback) {
    final id = '${item['id'] ?? item['utag'] ?? item['url'] ?? DateTime.now().microsecondsSinceEpoch}';
    final name = '${item['utag'] ?? item['title'] ?? '360 壁纸'}';
    final rawUrl = '${item['url'] ?? item['img_1600_900'] ?? item['img_1024_768'] ?? ''}';
    final downloadUrl = _upgradeHttps(rawUrl);
    final width = int.tryParse('${item['width'] ?? item['imgcut_width'] ?? 0}') ?? 0;
    final height = int.tryParse('${item['height'] ?? item['imgcut_height'] ?? 0}') ?? 0;
    final classId = int.tryParse('${item['class_id'] ?? ''}');
    final category = classId == null ? fallback : _categoryFromCid(classId);

    return Wallpaper(
      id: id,
      name: name.isBlank ? '未命名壁纸' : name,
      url: downloadUrl,
      downloadUrl: downloadUrl,
      width: width,
      height: height,
      category: category,
      source: WallpaperSource.qh360,
      origin: '${width > 0 ? width : '?'}×${height > 0 ? height : '?'} · 360 壁纸',
    );
  }

  int _random360Start({required int seed, required int start, required int cid}) {
    final base = (seed.abs() + cid * 37) % 260;
    return base + start;
  }

  WallpaperCategory _categoryFromCid(int cid) {
    switch (cid) {
      case 26:
        return WallpaperCategory.anime;
      case 6:
        return WallpaperCategory.people;
      case 36:
        return WallpaperCategory.random;
      default:
        return WallpaperCategory.general;
    }
  }

  String _upgradeHttps(String url) => url.replaceFirst(RegExp(r'^http://'), 'https://');
}

class WallpaperApiException implements Exception {
  const WallpaperApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension _StringBlank on String {
  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => trim().isNotEmpty;
}
