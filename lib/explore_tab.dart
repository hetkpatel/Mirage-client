import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mirageclient/MirageClient.dart';
import 'package:mirageclient/MiragePhotoData.dart';
import 'package:mirageclient/models/mirage_memory.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  bool _loading = true;
  String? _error;
  List<MirageMemory> _memories = const [];
  List<List<MiragePhotoData>> _similarGroups = const [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        MirageClient.getMemories(),
        MirageClient.getSimilar(),
        MirageClient.getPhotos(),
      ]);

      final memories = results[0] as List<MirageMemory>;
      final similarIds = results[1] as List<List<String>>;
      final photos = results[2] as List<MiragePhotoData>;

      final lookup = {for (final p in photos) p.id: p};
      final groups = similarIds
          .map(
            (group) => group
                .map((id) => lookup[id])
                .whereType<MiragePhotoData>()
                .toList(),
          )
          .where((group) => group.length >= 2)
          .toList();

      if (!mounted) return;
      setState(() {
        _memories = memories;
        _similarGroups = groups.take(6).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Explore content is currently unavailable.';
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
      return _ExploreError(message: _error!, onRetry: _loadContent);
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_memories.isNotEmpty) ...[
            Text(
              'On this day',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final memory = _memories[index];
                  return SizedBox(
                    width: 260,
                    child: _MemoryCard(memory: memory),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: _memories.length,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Similar shots',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_similarGroups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Nothing to review right now. Check back after uploading more photos.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._similarGroups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SimilarGroupCard(group: group),
              ),
            ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.memory});

  final MirageMemory memory;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            memory.coverUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                child: const Icon(Icons.photo_outlined, size: 42),
              );
            },
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  memory.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarGroupCard extends StatelessWidget {
  const _SimilarGroupCard({required this.group});

  final List<MiragePhotoData> group;

  @override
  Widget build(BuildContext context) {
    final representative = group.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Review similar shots',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('Review'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                '${representative.url}?thumbnail=true',
                fit: BoxFit.cover,
                height: 180,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.black12),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${group.length} photos • ${DateFormat.yMMMd().format(representative.created)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreError extends StatelessWidget {
  const _ExploreError({
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
          const Icon(Icons.explore_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
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
