import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flexible_scrollbar/flexible_scrollbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mirageclient/MirageClient.dart';
import 'package:mirageclient/MiragePhotoData.dart';
import 'package:mirageclient/models/mirage_memory.dart';
import 'package:mirageclient/utils/favorites_store.dart';
import 'package:mirageclient/utils/GalleryPhotoViewWrapper.dart';

enum PhotoFilter { all, favorites, videos, recent }

class PhotosTab extends StatefulWidget {
  final ValueChanged<int> selected;
  const PhotosTab({super.key, required this.selected});

  @override
  State<PhotosTab> createState() => PhotosTabState();
}

class PhotosTabState extends State<PhotosTab> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _sc = ScrollController();

  List<MiragePhotoData> _photos = [];
  List<PhotoCollection> _photoCollection = [];
  List<MiragePhotoData> _filteredPhotos = [];
  final List<String> _selected = [];
  Set<String> _favorites = {};
  bool _loading = true, _uploading = false, _processing = false;
  int _complete = 0, _total = 0;
  double _processingProgress = 0.0;
  bool _serverProcessing = false;
  Timer? _timer;
  String? _error;
  PhotoFilter _activeFilter = PhotoFilter.all;
  List<MirageMemory> _memories = [];
  bool _memoriesLoading = true;

  final ValueNotifier<String> _currentTitleNotifier =
      ValueNotifier<String>("---");

  final double targetRowHeight = 150;
  final double spacing = 4;

  @override
  void initState() {
    super.initState();
    _startPinging();
    _loadFavorites();
    _loadMemories();
    getPhotos();
  }

  Future<void> getPhotos() async {
    if (context.mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await MirageClient.getPhotos();
      items.sort((a, b) => b.created.compareTo(a.created));
      if (!mounted) return;
      setState(() {
        _photos = items;
        _rebuildCollections();
        _loading = false;
      });
    } catch (error) {
      if (kDebugMode) {
        print('Failed to get photos: $error');
      }
      if (!mounted) return;
      setState(() {
        _error = 'We couldn\'t load your photos right now.';
        _loading = false;
      });
    }
  }

  void _rebuildCollections() {
    _filteredPhotos = _applyFilterList(_photos);
    _photoCollection = _buildCollections(_filteredPhotos);
    if (_photoCollection.isEmpty) {
      _currentTitleNotifier.value = 'Photos';
    }
  }

  List<MiragePhotoData> _applyFilterList(List<MiragePhotoData> source) {
    switch (_activeFilter) {
      case PhotoFilter.favorites:
        return source.where((photo) => _favorites.contains(photo.id)).toList();
      case PhotoFilter.videos:
        return source.where((photo) => photo.type == MirageType.video).toList();
      case PhotoFilter.recent:
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        return source.where((photo) => photo.created.isAfter(cutoff)).toList();
      case PhotoFilter.all:
        return List<MiragePhotoData>.from(source);
    }
  }

  List<PhotoCollection> _buildCollections(List<MiragePhotoData> source) {
    final Map<int, PhotoCollection> grouped = {};
    for (final photo in source) {
      final key = photo.created.year * 100 + photo.created.month;
      grouped.putIfAbsent(
        key,
        () => PhotoCollection(
          date: DateTime(photo.created.year, photo.created.month),
        ),
      );
      grouped[key]!.mPhotoData.add(photo);
    }
    final collections = grouped.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return collections;
  }

  Future<void> _loadFavorites() async {
    final stored = await FavoritesStore.load();
    if (!mounted) return;
    setState(() {
      _favorites = stored;
      _rebuildCollections();
    });
  }

  Future<void> _loadMemories() async {
    if (mounted) {
      setState(() => _memoriesLoading = true);
    }
    try {
      final items = await MirageClient.getMemories();
      if (!mounted) return;
      setState(() {
        _memories = items;
        _memoriesLoading = false;
      });
    } catch (error) {
      if (kDebugMode) {
        print('Failed to load memories: $error');
      }
      if (!mounted) return;
      setState(() => _memoriesLoading = false);
    }
  }

  Future<Set<String>> _toggleFavorite(String id) async {
    final updated = await FavoritesStore.toggle(id);
    if (mounted) {
      setState(() {
        _favorites = updated;
        _rebuildCollections();
      });
    }
    return updated;
  }

  String _emptyMessage() {
    switch (_activeFilter) {
      case PhotoFilter.favorites:
        return 'Tap the star on a photo to add it to Favorites.';
      case PhotoFilter.videos:
        return 'No videos were found. Upload one to get started.';
      case PhotoFilter.recent:
        return 'No photos taken in the last 30 days.';
      case PhotoFilter.all:
        return 'No photos found';
    }
  }

  List<Widget> _buildPhotoSlivers() {
    return _photoCollection.map(
      (collection) {
        return SliverStickyHeader.builder(
          builder: (context, state) {
            final newCurrentTitle =
                DateFormat.yMMMM().format(collection.date);
            if (state.isPinned &&
                _currentTitleNotifier.value.toString() != newCurrentTitle) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _currentTitleNotifier.value = newCurrentTitle;
              });
            }

            return Container(
              height: 60,
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: Text(
                newCurrentTitle,
                style: const TextStyle(fontSize: 24),
              ),
            );
          },
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.crossAxisExtent - spacing * 2;
              final rows = _buildRows(
                collection.mPhotoData,
                availableWidth,
                targetRowHeight,
              );

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final row = rows[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        top: index == 0 ? spacing : 0,
                        bottom: spacing,
                        left: spacing,
                        right: spacing,
                      ),
                      child: Row(
                        children: List.generate(row.length, (i) {
                          final img = row[i];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: i < row.length - 1 ? spacing : 0,
                            ),
                            child: _buildPhotoTile(img),
                          );
                        }),
                      ),
                    );
                  },
                  childCount: rows.length,
                ),
              );
            },
          ),
        );
      },
    ).toList();
  }

  void _uploadItems(List<XFile> items) async {
    Future<List<T>> progressWait<T>(List<Future<T>> futures,
        void Function(int completed, int total) progress) {
      int total = futures.length;
      int completed = 0;
      void complete() {
        completed++;
        progress(completed, total);
      }

      return Future.wait<T>(
          [for (var future in futures) future.whenComplete(complete)]);
    }

    await progressWait(
      items
          .map(
            (e) => MirageClient.uploadFile(e),
          )
          .toList(),
      (complete, total) {
        if (context.mounted) {
          setState(() {
            _complete = complete;
            _total = total;
            _uploading = complete != total;
          });
        }
      },
    );

    await MirageClient.startProcessing(pullUploads: true);
    _startPinging();
  }

  void _startPinging() {
    checkStatus(_) async {
      try {
        String statusUrl = '${await SessionManager().get("server")}/status';
        final response = await http.get(Uri.parse(statusUrl), headers: {
          HttpHeaders.authorizationHeader: await SessionManager().get("auth"),
        });

        if (response.statusCode == 200) {
          _stopPinging();
        } else if (response.statusCode == 425) {
          Map<String, dynamic> result =
              (jsonDecode(response.body) as Map<String, dynamic>);
          if (context.mounted) {
            setState(() {
              _processing = true;
              _processingProgress = result['progress'];
              _serverProcessing = result['processing_similar'];
            });
          }
        } else {
          if (kDebugMode) {
            print('Ping failed: ${response.statusCode}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error occurred while pinging: $e');
        }
      }
    }

    checkStatus(null);
    _timer = Timer.periodic(const Duration(seconds: 15), checkStatus);
  }

  void _stopPinging() {
    _timer?.cancel();
    if (context.mounted) {
      setState(() {
        _processing = false;
        _serverProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  Widget _uploadStatus() {
    if (_uploading) {
      return SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          value: _complete / _total,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          strokeCap: StrokeCap.round,
        ),
      );
    } else if (_processing) {
      return SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          value: !_serverProcessing ? _processingProgress : null,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          strokeCap: StrokeCap.round,
        ),
      );
    } else {
      return const Icon(Icons.add_photo_alternate_outlined);
    }
  }

  void deselectAll() {
    setState(() => _selected.clear());
    widget.selected(_selected.length);
  }

  Future<void> trash() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Are you sure you want to delete ${_selected.length} items?'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        return;
                      },
                      child: Text(
                        'No',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (context.mounted) {
                          setState(() => _loading = true);
                        }

                        _photos.removeWhere(
                            (element) => _selected.contains(element.id));
                        _photos.sort((a, b) => b.created.compareTo(a.created));
                        _rebuildCollections();

                        // Trash on server side
                        for (String id in _selected) {
                          await MirageClient.trash(id);
                        }

                        _selected.clear();
                        widget.selected(0);

                        if (context.mounted) {
                          setState(() => _loading = false);
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        'Trash',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoTile(PhotoDataWithSize pd) {
    // Move hovering outside the builder
    bool hovering = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => hovering = true),
          onExit: (_) => setState(() => hovering = false),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                _createRoute(
                  GalleryPhotoViewWrapper(
                    galleryItems: _filteredPhotos,
                    copyOfSelectedIDs: _selected,
                    initialIndex: _filteredPhotos.indexOf(pd.mPhotoData),
                    alreadySelected: _selected.contains(pd.mPhotoData.id),
                    onSelectedCallback: (id) {
                      if (_selected.contains(id)) {
                        _selected.remove(id);
                      } else {
                        _selected.add(id);
                      }
                      widget.selected(_selected.length);
                    },
                    favoriteIds: _favorites,
                    onToggleFavorite: _toggleFavorite,
                  ),
                ),
              );
              setState(() {
                widget.selected(_selected.length);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  SizedBox(
                    width: pd.width,
                    height: pd.height,
                    child: BlurHash(
                      hash: pd.mPhotoData.metadata['BlurHash'],
                      image: "${pd.mPhotoData.url}?thumbnail=true",
                      imageFit: BoxFit.cover,
                    ),
                  ),
                  if (hovering || _selected.contains(pd.mPhotoData.id))
                    Positioned(
                      top: 4,
                      left: 4,
                      child: IconButton(
                        onPressed: () {
                          if (_selected.contains(pd.mPhotoData.id)) {
                            _selected.remove(pd.mPhotoData.id);
                          } else {
                            _selected.add(pd.mPhotoData.id);
                          }
                          widget.selected(_selected.length);
                        },
                        icon: Icon(
                          _selected.contains(pd.mPhotoData.id)
                              ? Icons.check_circle_rounded
                              : Icons.check_circle_outline_outlined,
                        ),
                        color: _selected.contains(pd.mPhotoData.id)
                            ? Colors.white
                            : Colors.white54,
                      ),
                    ),
                  if (_favorites.contains(pd.mPhotoData.id))
                    const Positioned(
                      bottom: 6,
                      right: 6,
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: const BouncingScrollPhysics(),
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad
            },
            scrollbars: false,
          ),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _error != null
                  ? _ErrorNotice(
                      message: _error!,
                      onRetry: getPhotos,
                    )
                  : FlexibleScrollbar(
                      controller: _sc,
                      jumpOnScrollLineTapped: false,
                      scrollThumbBuilder: (p0) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          width: 10,
                          height: p0.thumbMainAxisSize,
                        );
                      },
                      scrollLabelBuilder: (p0) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ValueListenableBuilder(
                              valueListenable: _currentTitleNotifier,
                              builder: (context, value, child) => Text(value),
                            ),
                          ),
                        );
                      },
                      child: CustomScrollView(
                        controller: _sc,
                        slivers: [
                          if (_memoriesLoading || _memories.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _MemoriesStrip(
                                memories: _memories,
                                loading: _memoriesLoading,
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: _QuickFilters(
                              selected: _activeFilter,
                              onChanged: (filter) {
                                if (_activeFilter == filter) return;
                                setState(() {
                                  _activeFilter = filter;
                                  _rebuildCollections();
                                });
                              },
                            ),
                          ),
                          if (_photoCollection.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  _emptyMessage(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            ..._buildPhotoSlivers(),
                        ],
                      ),
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _uploading || _processing
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : null,
        tooltip: _uploading
            ? "Uploading: ${((_complete / _total) * 100).round()}%"
            : _processing
                ? _serverProcessing
                    ? "Finalizing uploads"
                    : "Processing: ${(_processingProgress * 100).round()}%"
                : null,
        onPressed: _loading || _uploading || _processing
            ? null
            : () async {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return Dialog(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: FutureBuilder<List<XFile>>(
                          future: _picker.pickMultipleMedia(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CupertinoActivityIndicator();
                            } else if (snapshot.hasError) {
                              debugPrintStack(stackTrace: snapshot.stackTrace);
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            } else {
                              if (snapshot.data!.isEmpty) {
                                Navigator.pop(context);
                                return const SizedBox.shrink();
                              }
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      'Ready to upload ${snapshot.data!.length} items'),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (context.mounted) {
                                            setState(() {
                                              _complete = 0;
                                              _total = snapshot.data!.length;
                                              _uploading = _complete != _total;
                                            });
                                          }
                                          _uploadItems(snapshot.data!);
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: Text(
                                          'Upload',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
        heroTag: 'upload_fab',
        child: _uploadStatus(),
      ),
    );
  }

  List<List<PhotoDataWithSize>> _buildRows(
    List<MiragePhotoData> images,
    double maxWidth,
    double rowHeight,
  ) {
    List<List<PhotoDataWithSize>> rows = [];
    List<MiragePhotoData> currentRow = [];
    double totalWidth = 0;

    for (var img in images) {
      final scaledWidth = img.aspectRatio * rowHeight;

      // Account for spacing between images
      final spacingWidth = currentRow.isEmpty ? 0 : spacing;

      // If adding this image would exceed the max width, finalize the current row
      if (totalWidth + scaledWidth + spacingWidth > maxWidth &&
          currentRow.isNotEmpty) {
        final scale =
            (maxWidth - (currentRow.length - 1) * spacing) / totalWidth;
        rows.add(
          currentRow.map((image) {
            final w = image.aspectRatio * rowHeight * scale;
            final h = rowHeight * scale;
            return PhotoDataWithSize(mPhotoData: image, width: w, height: h);
          }).toList(),
        );
        currentRow = [];
        totalWidth = 0;
      }

      currentRow.add(img);
      totalWidth += scaledWidth;
    }

    // Handle the last row
    if (currentRow.isNotEmpty) {
      rows.add(
        currentRow.map((image) {
          final w = image.aspectRatio * rowHeight;
          final h = rowHeight;
          return PhotoDataWithSize(mPhotoData: image, width: w, height: h);
        }).toList(),
      );
    }

    return rows;
  }

  Route _createRoute(Widget toPage) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => toPage,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}

class _MemoriesStrip extends StatelessWidget {
  const _MemoriesStrip({
    required this.memories,
    required this.loading,
  });

  final List<MirageMemory> memories;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 140,
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (memories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Memories',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final memory = memories[index];
                return SizedBox(
                  width: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          memory.coverUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Icon(Icons.photo_outlined, size: 48),
                            );
                          },
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                memory.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                memory.subtitle,
                                style:
                                    Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                        ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Auto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: memories.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFilters extends StatelessWidget {
  const _QuickFilters({
    required this.selected,
    required this.onChanged,
  });

  final PhotoFilter selected;
  final ValueChanged<PhotoFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const entries = [
      (PhotoFilter.all, 'All photos', Icons.photo_library_outlined),
      (PhotoFilter.favorites, 'Favorites', Icons.star_outline_rounded),
      (PhotoFilter.videos, 'Videos', Icons.play_arrow_rounded),
      (PhotoFilter.recent, 'Recent', Icons.new_releases_outlined),
    ];
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final entry = entries[index];
          final isSelected = selected == entry.$1;
          return FilterChip(
            avatar: Icon(
              entry.$3,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            label: Text(entry.$2),
            selected: isSelected,
            onSelected: (_) => onChanged(entry.$1),
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: entries.length,
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
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

class PhotoCollection {
  final DateTime date;
  List<MiragePhotoData> mPhotoData = [];

  PhotoCollection({required this.date});
}

class PhotoDataWithSize {
  final MiragePhotoData mPhotoData;
  final double width;
  final double height;

  PhotoDataWithSize({
    required this.mPhotoData,
    required this.width,
    required this.height,
  });
}
