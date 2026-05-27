import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/wallpaper.dart';
import 'glass_button.dart';
import 'glass_panel.dart';

class SlideshowViewer extends StatefulWidget {
  const SlideshowViewer({
    super.key,
    required this.wallpapers,
    required this.initialIndex,
    required this.onClose,
  });

  final List<Wallpaper> wallpapers;
  final int initialIndex;
  final VoidCallback onClose;

  @override
  State<SlideshowViewer> createState() => _SlideshowViewerState();
}

class _SlideshowViewerState extends State<SlideshowViewer> with SingleTickerProviderStateMixin {
  late int _index;
  late AnimationController _controller;
  Timer? _timer;
  bool _playing = true;

  Wallpaper get _current => widget.wallpapers[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.wallpapers.length - 1).toInt();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 620))..forward();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _next());
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _startTimer();
  }

  void _next() {
    if (widget.wallpapers.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.wallpapers.length);
    _controller.forward(from: 0);
  }

  void _previous() {
    if (widget.wallpapers.isEmpty) return;
    setState(() => _index = (_index - 1 + widget.wallpapers.length) % widget.wallpapers.length);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = _current;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -200) _next();
        if (velocity > 200) _previous();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                child: ImageFiltered(
                  key: ValueKey('bg-${wallpaper.id}'),
                  imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: CachedNetworkImage(imageUrl: wallpaper.url, fit: BoxFit.cover),
                ),
              ),
            ),
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.42))),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final curved = Curves.easeOutExpo.transform(_controller.value);
                  final flash = (1 - _controller.value).clamp(0.0, 1.0);
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Transform.scale(
                        scale: 0.96 + 0.04 * curved,
                        child: Opacity(opacity: 0.22 + 0.78 * curved, child: child),
                      ),
                      IgnorePointer(child: Container(color: Colors.white.withOpacity(flash * 0.16))),
                    ],
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 86),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAlias,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: wallpaper.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const AspectRatio(
                          aspectRatio: 9 / 16,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => const AspectRatio(
                          aspectRatio: 9 / 16,
                          child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    GlassButton(icon: Icons.close_rounded, tooltip: '关闭', onPressed: widget.onClose),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassPanel(
                        borderRadius: 999,
                        opacity: 0.34,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: GlassButton(icon: Icons.skip_previous_rounded, label: '上一张', onPressed: _previous)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlassButton(
                          icon: _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          label: _playing ? '暂停' : '播放',
                          selected: true,
                          onPressed: _togglePlay,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: GlassButton(icon: Icons.skip_next_rounded, label: '下一张', onPressed: _next)),
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