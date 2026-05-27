import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

import '../models/wallpaper.dart';
import '../models/wallpaper_state.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_panel.dart';

class WallpaperPreviewScreen extends StatefulWidget {
  const WallpaperPreviewScreen({
    super.key,
    required this.wallpapers,
    required this.initialWallpaper,
  });

  final List<Wallpaper> wallpapers;
  final Wallpaper initialWallpaper;

  @override
  State<WallpaperPreviewScreen> createState() => _WallpaperPreviewScreenState();
}

class _WallpaperPreviewScreenState extends State<WallpaperPreviewScreen> {
  late int _index;

  Wallpaper get _current => widget.wallpapers[_index];

  @override
  void initState() {
    super.initState();
    final found = widget.wallpapers.indexWhere((item) => item.id == widget.initialWallpaper.id);
    _index = found < 0 ? 0 : found;
  }

  void _next() {
    if (widget.wallpapers.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.wallpapers.length);
  }

  void _previous() {
    if (widget.wallpapers.isEmpty) return;
    setState(() => _index = (_index - 1 + widget.wallpapers.length) % widget.wallpapers.length);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<WallpaperState>().saveToGallery(_current);
      messenger.showSnackBar(const SnackBar(content: Text('已保存到相册：Wallpaper Wall')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = _current;
    final saving = context.watch<WallpaperState>().saving;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Transform.scale(
                scale: 1.12,
                child: CachedNetworkImage(
                  key: ValueKey('preview-bg-${wallpaper.id}'),
                  imageUrl: wallpaper.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.46))),
          Positioned.fill(
            child: PhotoView(
              key: ValueKey('preview-photo-${wallpaper.id}'),
              imageProvider: CachedNetworkImageProvider(wallpaper.downloadUrl),
              minScale: PhotoViewComputedScale.contained,
              initialScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3.2,
              basePosition: Alignment.center,
              tightMode: true,
              backgroundDecoration: const BoxDecoration(color: Colors.transparent),
              loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 42),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  GlassButton(
                    icon: Icons.close_rounded,
                    tooltip: '关闭',
                    blurred: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassPanel(
                      borderRadius: 999,
                      opacity: 0.34,
                      blurred: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        '${_index + 1}/${widget.wallpapers.length} · ${wallpaper.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 24,
            child: SafeArea(
              child: GlassPanel(
                borderRadius: 30,
                opacity: 0.38,
                blurred: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: <Widget>[
                    Expanded(child: GlassButton(icon: Icons.skip_previous_rounded, label: '上一张', blurred: true, onPressed: _previous)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassButton(
                        icon: saving ? Icons.hourglass_top_rounded : Icons.download_rounded,
                        label: saving ? '保存中' : '保存',
                        blurred: true,
                        onPressed: saving ? null : _save,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: GlassButton(icon: Icons.skip_next_rounded, label: '下一张', blurred: true, onPressed: _next)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}