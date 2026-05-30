import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// PhotoView removed for rounded image fidelity.
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAround());
  }

  void _precacheAround() {
    if (!mounted || widget.wallpapers.isEmpty) return;
    final next = widget.wallpapers[(_index + 1) % widget.wallpapers.length];
    precacheImage(CachedNetworkImageProvider(next.url), context);
  }

  void _next() {
    if (widget.wallpapers.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.wallpapers.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAround());
  }

  void _previous() {
    if (widget.wallpapers.isEmpty) return;
    setState(() => _index = (_index - 1 + widget.wallpapers.length) % widget.wallpapers.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAround());
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
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: <Widget>[
            _BlurredPreviewBackground(wallpaper: wallpaper),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(18, 86, 18, 86),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final imageRatio = wallpaper.aspectRatio <= 0 ? 9 / 16 : wallpaper.aspectRatio;
                  final availableRatio = constraints.maxWidth / constraints.maxHeight;
                  final double targetWidth;
                  final double targetHeight;

                  if (imageRatio > availableRatio) {
                    targetWidth = constraints.maxWidth;
                    targetHeight = targetWidth / imageRatio;
                  } else {
                    targetHeight = constraints.maxHeight;
                    targetWidth = targetHeight * imageRatio;
                  }

                  return Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: targetWidth,
                        height: targetHeight,
                        child: RepaintBoundary(
                          child: InteractiveViewer(
                            minScale: 1,
                            maxScale: 3.2,
                            clipBehavior: Clip.hardEdge,
                            child: CachedNetworkImage(
                              key: ValueKey('preview-photo-${wallpaper.id}'),
                              imageUrl: wallpaper.url,
                              memCacheWidth: 1080,
                              width: targetWidth,
                              height: targetHeight,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 120),
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(Icons.broken_image_rounded, color: Colors.white, size: 42),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                bottom: false,
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
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(18, 0, 18, 24),
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
      ),
    );
  }
}

class _BlurredPreviewBackground extends StatelessWidget {
  const _BlurredPreviewBackground({required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF15151A), Color(0xFF030305)],
          ),
        ),
        child: ClipRect(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
            child: Transform.scale(
              scale: 1.45,
              child: CachedNetworkImage(
                key: ValueKey('preview-bg-${wallpaper.id}'),
                imageUrl: wallpaper.url,
                memCacheWidth: 360,
                memCacheHeight: 640,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (context, url) => const SizedBox.expand(),
                errorWidget: (context, url, error) => const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
