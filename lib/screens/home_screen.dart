import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings_state.dart';
import '../models/wallpaper.dart';
import '../models/wallpaper_state.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_panel.dart';
import '../widgets/source_filter_bar.dart';
import '../widgets/wallpaper_grid.dart';
import 'slideshow_screen.dart';
import 'wallpaper_preview_screen.dart';

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
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final state = context.read<WallpaperState>();
    final max = _scrollController.position.maxScrollExtent;
    if (max - offset < 720 && !state.loading && state.wallpapers.isNotEmpty) {
      state.fetch();
    }

    if (offset <= 24) {
      _lastOffset = offset;
      if (!_headerVisible) setState(() => _headerVisible = true);
      return;
    }

    final delta = offset - _lastOffset;
    _lastOffset = offset;
    if (offset < 120) return;

    if (delta > 12 && _headerVisible) {
      setState(() => _headerVisible = false);
    } else if (delta < -12 && !_headerVisible) {
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

  void _openPreview(BuildContext context, Wallpaper wallpaper) {
    final state = context.read<WallpaperState>();
    final related = state.relatedWallpapers(wallpaper);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: WallpaperPreviewScreen(
            wallpapers: related,
            initialWallpaper: wallpaper,
          ),
        ),
      ),
    );
  }

  void _openSlideshowFromTop(BuildContext context) {
    final state = context.read<WallpaperState>();
    final visible = state.visibleWallpapers;
    if (visible.isEmpty) return;
    final initial = state.selected ?? visible.first;
    _openSlideshow(context, initial);
  }

  void _openSlideshow(BuildContext context, Wallpaper wallpaper) {
    final state = context.read<WallpaperState>();
    final related = state.relatedWallpapers(wallpaper);
    state.select(wallpaper);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: SlideshowScreen(
            wallpapers: related,
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

  Future<void> _openExternalUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      messenger.showSnackBar(const SnackBar(content: Text('链接格式无效')));
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('无法打开外部链接')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WallpaperState>(
      builder: (context, state, _) {
        final visible = state.visibleWallpapers;
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
                    SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).top + 166)),
                    if (state.error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                          child: _ErrorBanner(message: state.error!, onRetry: () => state.fetch(reset: true)),
                        ),
                      ),
                    WallpaperGrid(
                      wallpapers: visible,
                      selected: state.selected,
                      loading: state.loading,
                      onSelect: state.select,
                      onOpenOriginal: (wallpaper) => _openPreview(context, wallpaper),
                      onSave: (wallpaper) => _save(context, wallpaper),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                top: _headerVisible ? 0 : -174,
                left: 0,
                right: 0,
                child: _FloatingHeader(
                  selectedCategory: state.category,
                  selectedSource: state.source,
                  count: visible.length,
                  totalCount: state.wallpapers.length,
                  loading: state.loading,
                  canPlay: visible.isNotEmpty,
                  onCategoryChanged: state.changeCategory,
                  onSourceChanged: state.changeSource,
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
                    onOpenOriginal: () => _openPreview(context, state.selected!),
                    onOpenSource: () => _openExternalUrl(context, state.selected!.sourceUrl),
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
    required this.selectedCategory,
    required this.selectedSource,
    required this.count,
    required this.totalCount,
    required this.loading,
    required this.canPlay,
    required this.onCategoryChanged,
    required this.onSourceChanged,
    required this.onRefresh,
    required this.onPlay,
    required this.onTop,
  });

  final WallpaperCategory selectedCategory;
  final WallpaperSource selectedSource;
  final int count;
  final int totalCount;
  final bool loading;
  final bool canPlay;
  final ValueChanged<WallpaperCategory> onCategoryChanged;
  final ValueChanged<WallpaperSource> onSourceChanged;
  final VoidCallback onRefresh;
  final VoidCallback onPlay;
  final VoidCallback onTop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<AppSettingsState>();
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 6),
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.74),
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
                            '$count/$totalCount 张 · ${selectedSource.longLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    GlassButton(icon: Icons.vertical_align_top_rounded, tooltip: '回到顶部', onPressed: onTop, blurred: true),
                    const SizedBox(width: 6),
                    GlassButton(icon: Icons.play_arrow_rounded, tooltip: '播放幻灯片', onPressed: canPlay ? onPlay : null, selected: true, blurred: true),
                    const SizedBox(width: 6),
                    GlassButton(
                      icon: settings.themeIcon,
                      tooltip: settings.themeLabel,
                      blurred: true,
                      onPressed: settings.toggleTheme,
                    ),
                    const SizedBox(width: 6),
                    GlassButton(
                      icon: loading ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                      tooltip: '刷新',
                      blurred: true,
                      onPressed: loading ? null : onRefresh,
                    ),
                  ],
                ),
              ),
              CategoryFilterBar(selected: selectedCategory, source: selectedSource, onChanged: onCategoryChanged),
              SourceFilterBar(selected: selectedSource, onChanged: onSourceChanged),
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
    required this.onOpenSource,
    required this.onSave,
  });

  final Wallpaper wallpaper;
  final bool saving;
  final VoidCallback onOpenOriginal;
  final VoidCallback onOpenSource;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassPanel(
      borderRadius: 24,
      opacity: 0.62,
      blurred: true,
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
                  wallpaper.authorName == null ? '${wallpaper.source.label} · ${wallpaper.origin}' : 'Photo by ${wallpaper.authorName} on Pexels',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          GlassButton(icon: Icons.open_in_full_rounded, tooltip: '放大预览', onPressed: onOpenOriginal),
          if (wallpaper.sourceUrl != null) ...<Widget>[
            const SizedBox(width: 6),
            GlassButton(icon: Icons.link_rounded, tooltip: '打开来源', onPressed: onOpenSource),
          ],
          const SizedBox(width: 6),
          GlassButton(
            icon: saving ? Icons.hourglass_top_rounded : Icons.download_rounded,
            tooltip: '保存',
            selected: true,
            onPressed: saving ? null : onSave,
          ),
        ],
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