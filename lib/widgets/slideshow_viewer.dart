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
    this.onSave,
  });

  final List<Wallpaper> wallpapers;
  final int initialIndex;
  final VoidCallback onClose;
  final VoidCallback? onSave;

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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 560))..forward();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAround());
  }

  @override
  void didUpdateWidget(covariant SlideshowViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wallpapers.length != oldWidget.wallpapers.length) {
      _index = _index.clamp(0, widget.wallpapers.length - 1).toInt();
      WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAround());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _precacheAround() {
    if (!mounted || widget.wallpapers.isEmpty) return;
    final current = _current;
    final next = widget.wallpapers[(_index + 1) % widget.wallpapers.length];
    final previous = widget.wallpapers[(_index - 1 + widget.wallpapers.length) % widget.wallpapers.length];
    for (final item in <Wallpaper>[current, next, previous]) {
      precacheImage(CachedNetworkImageProvider(item.url), context);
    }
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAround());
  }

  void _previous() {
    if (widget.wallpapers.isEmpty) return;
    setState(() => _index = (_index - 1 + widget.wallpapers.length) % widget.wallpapers.length);
    _controller.forward(from: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAround());
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
        body: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: <Widget>[
              _SlideshowBlurredBackground(wallpaper: wallpaper),
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final curved = Curves.easeOutExpo.transform(_controller.value);
                    final flash = (1 - _controller.value).clamp(0.0, 1.0);
                    return Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: <Widget>[
                        Center(
                          child: Transform.scale(
                            scale: 0.965 + 0.035 * curved,
                            child: Opacity(opacity: 0.30 + 0.70 * curved, child: child),
                          ),
                        ),
                        IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(color: Colors.white.withOpacity(flash * 0.10)))),
                      ],
                    );
                  },
                  child: _RoundedSlideImage(
                    key: ValueKey('slide-${wallpaper.id}'),
                    wallpaper: wallpaper,
                  ),
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
                        GlassButton(icon: Icons.close_rounded, tooltip: '关闭', blurred: true, onPressed: widget.onClose),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassPanel(
                            borderRadius: 999,
                            opacity: 0.34,
                            blurred: true,
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
                            icon: _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            label: _playing ? '暂停' : '播放',
                            selected: true,
                            blurred: true,
                            onPressed: _togglePlay,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: GlassButton(icon: Icons.skip_next_rounded, label: '下一张', blurred: true, onPressed: _next)),
                        if (widget.onSave != null) ...<Widget>[
                          const SizedBox(width: 8),
                          GlassButton(icon: Icons.download_rounded, tooltip: '保存原图', blurred: true, onPressed: widget.onSave),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideshowBlurredBackground extends StatelessWidget {
  const _SlideshowBlurredBackground({required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF17171C), Color(0xFF040406)],
          ),
        ),
        child: ClipRect(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: ImageFiltered(
              key: ValueKey('slide-bg-${wallpaper.id}'),
              imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
              child: Transform.scale(
                scale: 1.48,
                child: CachedNetworkImage(
                  imageUrl: wallpaper.url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  fadeInDuration: const Duration(milliseconds: 90),
                  placeholder: (context, url) => const SizedBox.expand(),
                  errorWidget: (context, url, error) => const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedSlideImage extends StatelessWidget {
  const _RoundedSlideImage({super.key, required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                child: ColoredBox(
                  color: Colors.white.withOpacity(0.04),
                  child: CachedNetworkImage(
                    imageUrl: wallpaper.url,
                    fit: BoxFit.cover,
                    width: targetWidth,
                    height: targetHeight,
                    fadeInDuration: const Duration(milliseconds: 100),
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}