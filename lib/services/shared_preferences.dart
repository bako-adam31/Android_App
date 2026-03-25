import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/parfum.dart';

class FavoritesService {
  static const _key = 'favorite_fragrances';

  Future<List<Parfum>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => Parfum.fromJson(e)).toList();
  }

  Future<void> addFavorite(Parfum parfum) async {
    final favorites = await getFavorites();
    if (favorites.any((f) => f.stableKey == parfum.stableKey)) return;
    favorites.add(parfum);
    await _save(favorites);
  }

  Future<void> removeFavorite(Parfum parfum) async {
    final favorites = await getFavorites();
    favorites.removeWhere((f) => f.stableKey == parfum.stableKey);
    await _save(favorites);
  }

  Future<bool> isFavorite(Parfum parfum) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f.stableKey == parfum.stableKey);
  }

  Future<void> _save(List<Parfum> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(favorites.map((f) => f.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }
}
