import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/wallpaper.dart';

class WallpaperCard extends StatelessWidget {
  const WallpaperCard({
    super.key,
    required this.wallpaper,
    required this.selected,
    required this.onSelect,
    required this.onPlay,
    required this.onSave,
  });

  final Wallpaper wallpaper;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPlay;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = wallpaper.aspectRatio.clamp(0.52, 1.78).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant.withOpacity(0.45),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: scheme.primary.withOpacity(0.35),
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Material(
          color: scheme.surfaceVariant.withOpacity(0.42),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InkWell(
                onTap: onSelect,
                child: Stack(
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: ratio,
                      child: CachedNetworkImage(
                        imageUrl: wallpaper.url,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 220),
                        placeholder: (context, url) => Container(
                          color: scheme.surfaceVariant,
                          child: const Center(
                            child: SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: scheme.errorContainer,
                          child: Icon(Icons.broken_image_rounded, color: scheme.error),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Pill(text: wallpaper.category.label),
                    ),
                    if (selected)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary),
                                const SizedBox(width: 4),
                                Text('已选', style: TextStyle(color: scheme.onPrimary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      wallpaper.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wallpaper.origin,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: onPlay,
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('播放'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onSave,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('保存'),
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}