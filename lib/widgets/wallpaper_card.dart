import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/wallpaper.dart';

class WallpaperCard extends StatelessWidget {
  const WallpaperCard({
    super.key,
    required this.wallpaper,
    required this.selected,
    required this.onSelect,
    required this.onOpenOriginal,
    required this.onSave,
  });

  final Wallpaper wallpaper;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpenOriginal;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = wallpaper.aspectRatio.clamp(0.58, 1.35).toDouble();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant.withOpacity(0.32),
          width: selected ? 2 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: selected ? scheme.primary.withOpacity(0.28) : Colors.black.withOpacity(0.18),
            blurRadius: selected ? 24 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Material(
          color: scheme.surfaceVariant.withOpacity(0.28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InkWell(
                onTap: onSelect,
                child: Stack(
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: ratio,
                      child: Hero(
                        tag: 'wallpaper-${wallpaper.id}',
                        child: CachedNetworkImage(
                          imageUrl: wallpaper.url,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 180),
                          placeholder: (context, url) => ColoredBox(
                            color: scheme.surfaceVariant,
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
                    ),
                    Positioned(left: 10, top: 10, child: _Pill(text: wallpaper.category.label)),
                    if (selected)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: _SelectedPill(color: scheme.primary, textColor: scheme.onPrimary),
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
                      wallpaper.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      wallpaper.origin,
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
                          child: _CompactActionButton(
                            icon: Icons.open_in_full_rounded,
                            label: '原图',
                            onPressed: onOpenOriginal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CompactActionButton(
                            icon: Icons.download_rounded,
                            label: '保存',
                            filled: true,
                            onPressed: onSave,
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

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: filled
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label, maxLines: 1),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 16),
              label: Text(label, maxLines: 1),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.46),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}