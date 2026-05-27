import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/wallpaper.dart';
import '../models/wallpaper_state.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/wallpaper_grid.dart';
import 'slideshow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _headerVisible = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WallpaperState>().bootstrap();
    });
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final delta = offset - _lastOffset;
    _lastOffset = offset;

    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final state = context.read<WallpaperState>();
      if (max - offset < 720 && !state.loading && state.wallpapers.isNotEmpty) {
        state.fetch();
      }
    }

    if (offset < 80 && !_headerVisible) {
      setState(() => _headerVisible = true);
      return;
    }
    if (delta > 8 && _headerVisible) {
      setState(() => _headerVisible = false);
    } else if (delta < -8 && !_headerVisible) {
      setState(() => _headerVisible = true);
    }
  }

  Future<void> _save(BuildContext context, Wallpaper wallpaper) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<WallpaperState>().saveToGallery(wallpaper);
      messenger.showSnackBar(const SnackBar(content: Text('已保存到相册：Wallpaper Wall')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  Future<void> _openOriginal(BuildContext context, Wallpaper wallpaper) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(wallpaper.downloadUrl);
    if (uri == null) {
      messenger.showSnackBar(const SnackBar(content: Text('原图链接无效')));
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text('无法打开原图')));
    }
  }

  void _openSlideshowFromTop(BuildContext context) {
    final state = context.read<WallpaperState>();
    if (state.wallpapers.isEmpty) return;
    final initial = state.selected ?? state.wallpapers.first;
    _openSlideshow(context, initial);
  }

  void _openSlideshow(BuildContext context, Wallpaper wallpaper) {
    final state = context.read<WallpaperState>();
    state.select(wallpaper);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: SlideshowScreen(
            wallpapers: state.wallpapers,
            initialWallpaper: wallpaper,
          ),
        ),
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WallpaperState>(
      builder: (context, state, _) {
        return Scaffold(
          extendBody: true,
          body: Stack(
            children: <Widget>[
              RefreshIndicator(
                onRefresh: () => state.fetch(reset: true),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: <Widget>[
                    SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).top + 112)),
                    if (state.error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                          child: _ErrorBanner(message: state.error!, onRetry: () => state.fetch(reset: true)),
                        ),
                      ),
                    WallpaperGrid(
                      wallpapers: state.wallpapers,
                      selected: state.selected,
                      loading: state.loading,
                      onSelect: state.select,
                      onOpenOriginal: (wallpaper) => _openOriginal(context, wallpaper),
                      onSave: (wallpaper) => _save(context, wallpaper),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                top: _headerVisible ? 0 : -118,
                left: 0,
                right: 0,
                child: _FloatingHeader(
                  selected: state.category,
                  count: state.wallpapers.length,
                  loading: state.loading,
                  canPlay: state.wallpapers.isNotEmpty,
                  onCategoryChanged: state.changeCategory,
                  onRefresh: () => state.fetch(reset: true),
                  onPlay: () => _openSlideshowFromTop(context),
                  onTop: _scrollToTop,
                ),
              ),
              if (state.selected != null)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _SelectedSheet(
                    wallpaper: state.selected!,
                    saving: state.saving,
                    onOpenOriginal: () => _openOriginal(context, state.selected!),
                    onSave: () => _save(context, state.selected!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingHeader extends StatelessWidget {
  const _FloatingHeader({
    required this.selected,
    required this.count,
    required this.loading,
    required this.canPlay,
    required this.onCategoryChanged,
    required this.onRefresh,
    required this.onPlay,
    required this.onTop,
  });

  final WallpaperCategory selected;
  final int count;
  final bool loading;
  final bool canPlay;
  final ValueChanged<WallpaperCategory> onCategoryChanged;
  final VoidCallback onRefresh;
  final VoidCallback onPlay;
  final VoidCallback onTop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 6),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.86),
            border: Border(bottom: BorderSide(color: scheme.outlineVariant.withOpacity(0.28))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: <Color>[scheme.primary, scheme.tertiary]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.wallpaper_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Wallpaper Wall',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '$count 张 · ${selected.sourceLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      onPressed: onTop,
                      icon: const Icon(Icons.vertical_align_top_rounded, size: 20),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      onPressed: canPlay ? onPlay : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      onPressed: loading ? null : onRefresh,
                      icon: loading
                          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded, size: 20),
                    ),
                  ],
                ),
              ),
              CategoryFilterBar(selected: selected, onChanged: onCategoryChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedSheet extends StatelessWidget {
  const _SelectedSheet({
    required this.wallpaper,
    required this.saving,
    required this.onOpenOriginal,
    required this.onSave,
  });

  final Wallpaper wallpaper;
  final bool saving;
  final VoidCallback onOpenOriginal;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.35)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(wallpaper.url, width: 54, height: 70, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    wallpaper.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    wallpaper.origin,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(onPressed: onOpenOriginal, icon: const Icon(Icons.open_in_full_rounded, size: 20)),
            IconButton.filled(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: scheme.onErrorContainer))),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}