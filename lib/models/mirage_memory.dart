class MirageMemory {
  MirageMemory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverUrl,
    required this.startAt,
    required this.endAt,
    this.photoIds = const [],
  });

  final String id;
  final String title;
  final String subtitle;
  final String coverUrl;
  final DateTime startAt;
  final DateTime endAt;
  final List<String> photoIds;

  factory MirageMemory.fromJson(Map<String, dynamic> json) {
    return MirageMemory(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      coverUrl: json['coverUrl'] as String,
      startAt: DateTime.tryParse(json['startAt'] as String? ?? '') ??
          DateTime.now(),
      endAt:
          DateTime.tryParse(json['endAt'] as String? ?? '') ?? DateTime.now(),
      photoIds: (json['photoIds'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'coverUrl': coverUrl,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt.toIso8601String(),
      'photoIds': photoIds,
    };
  }
}
