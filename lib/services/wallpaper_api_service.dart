import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/wallpaper.dart';

class WallpaperApiService {
  static const String _endpoint = 'http://wallpaper.apc.360.cn/index.php';
  static const int perCategoryCount = 30;
  static const int mixedCount = 60;

  static const Map<WallpaperCategory, int> _categoryCid = {
    WallpaperCategory.general: 9,
    WallpaperCategory.anime: 26,
    WallpaperCategory.people: 6,
    WallpaperCategory.random: 36,
  };

  static const List<int> _mixedCids = <int>[9, 15, 26, 6, 36, 14, 12, 10];

  Future<List<Wallpaper>> fetchWallpapers({
    WallpaperCategory category = WallpaperCategory.all,
    int start = 0,
  }) async {
    if (category == WallpaperCategory.all) {
      return _fetchMixed(start: start);
    }

    final cid = _categoryCid[category] ?? 9;
    return _fetchByCid(
      cid: cid,
      category: category,
      start: start,
      count: perCategoryCount,
    );
  }

  Future<List<Wallpaper>> _fetchMixed({required int start}) async {
    final futures = _mixedCids.map(
      (cid) => _fetchByCid(
        cid: cid,
        category: _categoryFromCid(cid),
        start: start,
        count: 12,
      ),
    );

    final batches = await Future.wait(futures);
    final unique = <String, Wallpaper>{};
    for (final batch in batches) {
      for (final wallpaper in batch) {
        unique[wallpaper.downloadUrl] = wallpaper;
      }
    }

    final list = unique.values.toList()..shuffle(Random());
    if (list.length <= mixedCount) return list;
    return list.take(mixedCount).toList();
  }

  Future<List<Wallpaper>> _fetchByCid({
    required int cid,
    required WallpaperCategory category,
    required int start,
    required int count,
  }) async {
    final uri = Uri.parse(_endpoint).replace(
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
        .map((item) => _toWallpaper(item, category))
        .where((wallpaper) => wallpaper.url.isNotEmpty)
        .toList();
  }

  Wallpaper _toWallpaper(Map<String, dynamic> item, WallpaperCategory fallback) {
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
      origin: '${width > 0 ? width : '?'}×${height > 0 ? height : '?'} · 360 壁纸',
    );
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
}
