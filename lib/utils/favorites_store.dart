import 'package:flutter/foundation.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';

class FavoritesStore {
  static const _favoritesKey = 'mirage_favorites';

  static Future<Set<String>> load() async {
    try {
      final raw = await SessionManager().get(_favoritesKey);
      if (raw is List) {
        return raw.map((e) => e.toString()).toSet();
      }
    } catch (error) {
      if (kDebugMode) {
        print('Unable to load favorites: $error');
      }
    }
    return {};
  }

  static Future<Set<String>> toggle(String id) async {
    final favorites = await load();
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.add(id);
    }
    await SessionManager().set(_favoritesKey, favorites.toList());
    return favorites;
  }

  static Future<void> setAll(Iterable<String> ids) async {
    await SessionManager().set(_favoritesKey, ids.toSet().toList());
  }
}
