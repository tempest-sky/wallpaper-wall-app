import 'dart:io';
import 'dart:math';

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
  WallpaperSource _source = WallpaperSource.all;
  Wallpaper? _selected;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  int _page = 0;
  int _sessionSeed = DateTime.now().millisecondsSinceEpoch;

  // ── Batch selection ──
  final Set<String> _batchSelectedIds = <String>{};
  bool _batchMode = false;

  List<Wallpaper> get wallpapers => List.unmodifiable(_wallpapers);
  List<Wallpaper> get visibleWallpapers {
    if (_source == WallpaperSource.all) return List.unmodifiable(_wallpapers);
    return List.unmodifiable(_wallpapers.where((wallpaper) => wallpaper.source == _source));
  }

  WallpaperCategory get category => _category;
  WallpaperSource get source => _source;
  Wallpaper? get selected => _selected;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  bool get hasSelected => _selected != null;

  // ── Batch getters ──
  Set<String> get batchSelectedIds => Set.unmodifiable(_batchSelectedIds);
  bool get batchMode => _batchMode;
  int get batchCount => _batchSelectedIds.length;

  Future<void> bootstrap() async {
    if (_wallpapers.isNotEmpty || _loading) return;
    await fetch(reset: true);
  }

  Future<void> changeCategory(WallpaperCategory category) async {
    if (_category == category && _wallpapers.isNotEmpty) return;
    _category = category;
    _selected = null;
    _batchMode = false;
    _batchSelectedIds.clear();
    await fetch(reset: true);
  }

  Future<void> changeSource(WallpaperSource source) async {
    if (_source == source && _wallpapers.isNotEmpty) return;
    _source = source;
    if (_source == WallpaperSource.pexels) {
      if (!_category.isPexelsCategory) _category = WallpaperCategory.all;
    } else if (_category.isPexelsCategory) {
      _category = WallpaperCategory.all;
    }
    _selected = null;
    _batchMode = false;
    _batchSelectedIds.clear();
    await fetch(reset: true);
  }

  List<Wallpaper> relatedWallpapers(Wallpaper wallpaper) {
    final visible = visibleWallpapers;
    if (visible.any((item) => item.id == wallpaper.id)) return visible;
    return _wallpapers;
  }

  Future<void> fetch({bool reset = false}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (reset) {
        _page = 0;
        _sessionSeed = _newSessionSeed();
        _wallpapers.clear();
        _knownUrls.clear();
      }

      final next = await _api.fetchWallpapers(
        category: _category,
        source: _source,
        start: _page * WallpaperApiService.perCategoryCount,
        seed: _sessionSeed,
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
    if (_batchMode) {
      toggleBatchSelection(wallpaper);
      return;
    }
    _selected = wallpaper;
    notifyListeners();
  }

  // ── Batch ──
  void toggleBatchMode() {
    _batchMode = !_batchMode;
    if (!_batchMode) {
      _batchSelectedIds.clear();
    }
    _selected = null;
    notifyListeners();
  }

  void toggleBatchSelection(Wallpaper wallpaper) {
    if (_batchSelectedIds.contains(wallpaper.id)) {
      _batchSelectedIds.remove(wallpaper.id);
    } else {
      _batchSelectedIds.add(wallpaper.id);
    }
    notifyListeners();
  }

  bool isBatchSelected(Wallpaper wallpaper) => _batchSelectedIds.contains(wallpaper.id);

  Future<void> saveSelectedToGallery() async {
    if (_batchSelectedIds.isEmpty) return;
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final targets = _wallpapers.where((w) => _batchSelectedIds.contains(w.id)).toList();
      for (final wallpaper in targets) {
        await _saveOne(wallpaper);
      }
      _batchSelectedIds.clear();
      _batchMode = false;
    } catch (error) {
      _error = '$error';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> saveToGallery(Wallpaper wallpaper) async {
    if (_saving) return;
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      await _saveOne(wallpaper);
    } catch (error) {
      _error = '$error';
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> _saveOne(Wallpaper wallpaper) async {
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
  }

  int _newSessionSeed() => DateTime.now().microsecondsSinceEpoch ^ Random().nextInt(1 << 31);

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
