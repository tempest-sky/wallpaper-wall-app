import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';

import '../services/wallpaper_api_service.dart';
import 'wallpaper.dart';

class WallpaperState extends ChangeNotifier {
  WallpaperState({WallpaperApiService? api}) : _api = api ?? WallpaperApiService();

  final WallpaperApiService _api;

  final List<Wallpaper> _wallpapers = <Wallpaper>[];
  final Set<String> _knownUrls = <String>{};

  WallpaperCategory _category = WallpaperCategory.all;
  Wallpaper? _selected;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  int _page = 0;

  List<Wallpaper> get wallpapers => List.unmodifiable(_wallpapers);
  WallpaperCategory get category => _category;
  Wallpaper? get selected => _selected;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  bool get hasSelected => _selected != null;

  Future<void> bootstrap() async {
    if (_wallpapers.isNotEmpty || _loading) return;
    await fetch(reset: true);
  }

  Future<void> changeCategory(WallpaperCategory category) async {
    if (_category == category && _wallpapers.isNotEmpty) return;
    _category = category;
    _selected = null;
    await fetch(reset: true);
  }

  Future<void> fetch({bool reset = false}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (reset) {
        _page = 0;
        _wallpapers.clear();
        _knownUrls.clear();
      }

      final next = await _api.fetchWallpapers(
        category: _category,
        start: _page * WallpaperApiService.perCategoryCount,
      );

      for (final wallpaper in next) {
        if (_knownUrls.add(wallpaper.downloadUrl)) {
          _wallpapers.add(wallpaper);
        }
      }
      _page += 1;
    } catch (error) {
      _error = '$error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void select(Wallpaper wallpaper) {
    _selected = wallpaper;
    notifyListeners();
  }

  Future<void> saveToGallery(Wallpaper wallpaper) async {
    if (_saving) return;
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final permission = await _requestSavePermission();
      if (!permission) {
        throw const WallpaperSaveException('未获得相册/存储权限');
      }

      final response = await http.get(Uri.parse(wallpaper.downloadUrl));
      if (response.statusCode != 200) {
        throw WallpaperSaveException('下载失败：HTTP ${response.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      final safeName = wallpaper.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/wallpaper_$safeName.jpg');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await Gal.putImage(file.path, album: 'Wallpaper Wall');
    } catch (error) {
      _error = '$error';
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> _requestSavePermission() async {
    if (Platform.isAndroid) {
      final photos = await Permission.photos.request();
      if (photos.isGranted || photos.isLimited) return true;
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
    return true;
  }
}

class WallpaperSaveException implements Exception {
  const WallpaperSaveException(this.message);

  final String message;

  @override
  String toString() => message;
}
