import 'models/mirage_album.dart';
import 'models/mirage_memory.dart';
import 'models/mirage_utility.dart';

class SampleData {
  static List<MirageAlbum> albums() {
    return [
      MirageAlbum(
        id: 'album_highlights',
        title: 'Highlights',
        subtitle: 'Auto-created',
        coverUrl:
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
        itemCount: 124,
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        type: MirageAlbumType.auto,
      ),
      MirageAlbum(
        id: 'album_recent_trip',
        title: 'Summer Trip',
        subtitle: 'Shared with 2 people',
        coverUrl:
            'https://images.unsplash.com/photo-1549888834-05b73d8cfcff?auto=format&fit=crop&w=900&q=80',
        itemCount: 86,
        updatedAt: DateTime.now().subtract(const Duration(days: 6)),
        type: MirageAlbumType.shared,
      ),
      MirageAlbum(
        id: 'album_family',
        title: 'Family',
        coverUrl:
            'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
        itemCount: 212,
        updatedAt: DateTime.now().subtract(const Duration(days: 12)),
        type: MirageAlbumType.user,
      ),
      MirageAlbum(
        id: 'album_places',
        title: 'Places',
        subtitle: 'Auto-created',
        coverUrl:
            'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=900&q=80',
        itemCount: 54,
        updatedAt: DateTime.now().subtract(const Duration(days: 9)),
        type: MirageAlbumType.auto,
      ),
      MirageAlbum(
        id: 'album_favorites',
        title: 'Favorites',
        coverUrl:
            'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=900&q=80',
        itemCount: 33,
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        type: MirageAlbumType.favorites,
      ),
    ];
  }

  static List<MirageUtilityItem> utilities() {
    return const [
      MirageUtilityItem(
        id: 'locked_folder',
        title: 'Locked Folder',
        subtitle: 'Keep sensitive content hidden and secure.',
        iconName: 'lock',
        badge: 'New',
      ),
      MirageUtilityItem(
        id: 'photo_scan',
        title: 'PhotoScan',
        subtitle: 'Digitise prints using your phone\'s camera.',
        iconName: 'scanner',
      ),
      MirageUtilityItem(
        id: 'clean_up',
        title: 'Clean up utility',
        subtitle: 'Review blurry photos, screenshots, and large videos.',
        iconName: 'spark',
      ),
      MirageUtilityItem(
        id: 'print_store',
        title: 'Print store',
        subtitle: 'Turn memories into books, canvases, and photo prints.',
        iconName: 'print',
      ),
      MirageUtilityItem(
        id: 'storage',
        title: 'Storage manager',
        subtitle: 'Check usage and free up space across your devices.',
        iconName: 'storage',
      ),
    ];
  }

  static List<MirageMemory> memories() {
    final now = DateTime.now();
    return [
      MirageMemory(
        id: 'memories_on_this_day',
        title: 'On this day',
        subtitle: '5 years ago • Beach weekend',
        coverUrl:
            'https://images.unsplash.com/photo-1493558103817-58b2924bce98?auto=format&fit=crop&w=1200&q=80',
        startAt: DateTime(now.year - 5, now.month, now.day),
        endAt: DateTime(now.year - 5, now.month, now.day + 2),
        photoIds: const [],
      ),
      MirageMemory(
        id: 'memories_recent_highlight',
        title: 'Recent highlights',
        subtitle: 'Curated for you',
        coverUrl:
            'https://images.unsplash.com/photo-1500534623283-312aade485b7?auto=format&fit=crop&w=1200&q=80',
        startAt: now.subtract(const Duration(days: 30)),
        endAt: now.subtract(const Duration(days: 7)),
        photoIds: const [],
      ),
      MirageMemory(
        id: 'memories_city_break',
        title: '48 hours in Kyoto',
        subtitle: 'Weekend getaway • 24 items',
        coverUrl:
            'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1200&q=80',
        startAt: now.subtract(const Duration(days: 90)),
        endAt: now.subtract(const Duration(days: 89)),
        photoIds: const [],
      ),
    ];
  }
}
