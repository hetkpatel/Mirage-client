class MirageUtilityItem {
  const MirageUtilityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
    this.badge,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconName;
  final String? badge;

  factory MirageUtilityItem.fromJson(Map<String, dynamic> json) {
    return MirageUtilityItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'spark',
      badge: json['badge'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'iconName': iconName,
      'badge': badge,
    };
  }
}
