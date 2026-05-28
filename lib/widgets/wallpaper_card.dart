import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/wallpaper.dart';
import 'glass_button.dart';
import 'glass_panel.dart';

class WallpaperCard extends StatefulWidget {
  const WallpaperCard({
    super.key,
    required this.wallpaper,
    required this.selected,
    required this.onSelect,
    required this.onOpenOriginal,
    required this.onSave,
    this.batchMode = false,
    this.batchSelected = false,
  });

  final Wallpaper wallpaper;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpenOriginal;
  final VoidCallback onSave;
  final bool batchMode;
  final bool batchSelected;

  @override
  State<WallpaperCard> createState() => _WallpaperCardState();
}

class _WallpaperCardState extends State<WallpaperCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, 0.045), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WallpaperCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallpaper.id != widget.wallpaper.id) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = widget.wallpaper.aspectRatio.clamp(0.58, 1.35).toDouble();

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: AnimatedScale(
          scale: widget.selected ? 0.985 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: widget.selected ? scheme.primary.withOpacity(0.72) : scheme.outlineVariant.withOpacity(0.28),
                width: widget.selected ? 1.6 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: widget.selected ? scheme.primary.withOpacity(0.18) : Colors.black.withOpacity(0.10),
                  blurRadius: widget.selected ? 22 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: Material(
                color: scheme.surfaceVariant.withOpacity(0.22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    InkWell(
                      onTap: widget.onSelect,
                      borderRadius: BorderRadius.circular(21),
                      child: Stack(
                        children: <Widget>[
                          AspectRatio(
                            aspectRatio: ratio,
                            child: CachedNetworkImage(
                              imageUrl: widget.wallpaper.url,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 160),
                              fadeOutDuration: const Duration(milliseconds: 120),
                              placeholder: (context, url) => ColoredBox(
                                color: scheme.surfaceVariant.withOpacity(0.62),
                                child: const Center(
                                  child: SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => ColoredBox(
                                color: scheme.errorContainer,
                                child: Icon(Icons.broken_image_rounded, color: scheme.error),
                              ),
                            ),
                          ),
                          Positioned(left: 10, top: 10, child: _Pill(text: widget.wallpaper.category.label)),
                          Positioned(left: 10, bottom: 10, child: _Pill(text: widget.wallpaper.source.label)),
                          if (widget.selected)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: _SelectedPill(color: scheme.primary, textColor: scheme.onPrimary),
                            ),
                          if (widget.batchMode)
                            Positioned(
                              right: 10,
                              top: 10,
                              child: _BatchCheckPill(
                                selected: widget.batchSelected,
                                color: scheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.wallpaper.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.wallpaper.origin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.0,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: GlassButton(
                                  icon: Icons.open_in_full_rounded,
                                  label: '原图',
                                  tooltip: '放大预览',
                                  onPressed: widget.onOpenOriginal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GlassButton(
                                  icon: Icons.download_rounded,
                                  label: '保存',
                                  tooltip: '保存到相册',
                                  selected: true,
                                  onPressed: widget.onSave,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  const _SelectedPill({required this.color, required this.textColor});

  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.check_rounded, size: 14, color: textColor),
            const SizedBox(width: 3),
            Text('已选', style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 999,
      opacity: 0.32,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _BatchCheckPill extends StatelessWidget {
  const _BatchCheckPill({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? color : Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? color : Colors.white.withOpacity(0.7),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(
          selected ? Icons.check_rounded : Icons.circle_outlined,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}
