import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mirageclient/MirageClient.dart';
import 'package:mirageclient/models/mirage_album.dart';

class AlbumsTab extends StatefulWidget {
  const AlbumsTab({super.key});

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  final Map<MirageAlbumType, List<MirageAlbum>> _albumsByType = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final albums = await MirageClient.getAlbums();
      final grouped = <MirageAlbumType, List<MirageAlbum>>{};
      for (final album in albums) {
        grouped.putIfAbsent(album.type, () => []).add(album);
      }
      if (!mounted) return;
      setState(() {
        _albumsByType
          ..clear()
          ..addAll(grouped);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load albums.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _AlbumsError(message: _error!, onRetry: _loadAlbums);
    }
    final hasAlbums =
        _albumsByType.values.any((list) => list.isNotEmpty == true);
    if (!hasAlbums) {
      return const _AlbumsEmpty();
    }

    return RefreshIndicator(
      onRefresh: _loadAlbums,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_albumsByType[MirageAlbumType.auto]?.isNotEmpty ?? false)
            _AlbumSection(
              label: 'Auto-created',
              albums: _albumsByType[MirageAlbumType.auto]!,
            ),
          if (_albumsByType[MirageAlbumType.shared]?.isNotEmpty ?? false)
            _AlbumSection(
              label: 'Shared albums',
              albums: _albumsByType[MirageAlbumType.shared]!,
            ),
          if (_albumsByType[MirageAlbumType.favorites]?.isNotEmpty ?? false)
            _AlbumSection(
              label: 'Favorites',
              albums: _albumsByType[MirageAlbumType.favorites]!,
            ),
          if (_albumsByType[MirageAlbumType.user]?.isNotEmpty ?? false)
            _AlbumSection(
              label: 'Your albums',
              albums: _albumsByType[MirageAlbumType.user]!,
              showCreateButton: true,
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}

class _AlbumSection extends StatelessWidget {
  const _AlbumSection({
    required this.label,
    required this.albums,
    this.showCreateButton = false,
  });

  final String label;
  final List<MirageAlbum> albums;
  final bool showCreateButton;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (showCreateButton) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Album creation is coming in a future update.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create album'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _AlbumsGrid(albums: albums),
          ],
        ),
      ),
    );
  }
}

class _AlbumsGrid extends StatelessWidget {
  const _AlbumsGrid({required this.albums});

  final List<MirageAlbum> albums;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth ~/ 220;
        final effectiveCrossAxisCount = crossAxisCount.clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: effectiveCrossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return Material(
              color: theme.colorScheme.surface,
              elevation: 1,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(album.coverUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _AlbumBadge(type: album.type),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  album.title,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (album.type == MirageAlbumType.shared)
                                Tooltip(
                                  message: 'Shared album',
                                  child: Icon(
                                    Icons.group_outlined,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                          if (album.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              album.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${album.itemCount} items • Updated ${DateFormat.MMMd().format(album.updatedAt)}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AlbumBadge extends StatelessWidget {
  const _AlbumBadge({required this.type});

  final MirageAlbumType type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case MirageAlbumType.favorites:
        return const _PillBadge(
          icon: Icons.star_rounded,
          label: 'Favorites',
        );
      case MirageAlbumType.auto:
        return const _PillBadge(
          icon: Icons.auto_awesome_outlined,
          label: 'Auto',
        );
      case MirageAlbumType.shared:
        return const _PillBadge(
          icon: Icons.group_outlined,
          label: 'Shared',
        );
      case MirageAlbumType.user:
        return const SizedBox.shrink();
    }
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumsError extends StatelessWidget {
  const _AlbumsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_album_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _AlbumsEmpty extends StatelessWidget {
  const _AlbumsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_album_outlined, size: 56),
          const SizedBox(height: 12),
          Text(
            'Create your first album to keep memories organised.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
