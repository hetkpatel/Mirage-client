import 'package:intl/intl.dart';

enum MirageAlbumType {
  user,
  shared,
  auto,
  favorites,
}

class MirageAlbum {
  MirageAlbum({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.itemCount,
    required this.updatedAt,
    this.type = MirageAlbumType.user,
    this.subtitle,
  });

  final String id;
  final String title;
  final String coverUrl;
  final int itemCount;
  final DateTime updatedAt;
  final MirageAlbumType type;
  final String? subtitle;

  String get formattedUpdatedAt => DateFormat.yMMMd().format(updatedAt);

  factory MirageAlbum.fromJson(Map<String, dynamic> json) {
    MirageAlbumType typeFromString(String? value) {
      switch ((value ?? '').toLowerCase()) {
        case 'user':
          return MirageAlbumType.user;
        case 'shared':
          return MirageAlbumType.shared;
        case 'auto':
        case 'highlight':
        case 'auto-created':
          return MirageAlbumType.auto;
        case 'favorites':
          return MirageAlbumType.favorites;
        default:
          return MirageAlbumType.user;
      }
    }

    return MirageAlbum(
      id: json['id'] as String,
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String,
      itemCount: json['itemCount'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      type: typeFromString(json['type'] as String?),
      subtitle: json['subtitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'itemCount': itemCount,
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.name,
      'subtitle': subtitle,
    };
  }
}
