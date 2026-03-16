import 'package:flutter/foundation.dart';
import '../models/parfum.dart';
import 'shared_preferences.dart';

class FavoritesManager extends ChangeNotifier {
  final FavoritesService _service = FavoritesService();
  List<Parfum> _favorites = [];

  List<Parfum> get favorites => _favorites;

  Future<void> load() async {
    _favorites = await _service.getFavorites();
    notifyListeners();
  }

  bool isFavorite(Parfum parfum) {
    return _favorites.any((f) => f.name == parfum.name && f.brand == parfum.brand);
  }

  Future<void> toggle(Parfum parfum) async {
    if (isFavorite(parfum)) {
      await _service.removeFavorite(parfum);
    } else {
      await _service.addFavorite(parfum);
    }
    await load(); // reload & notify all listeners
  }

  Future<void> remove(Parfum parfum) async {
    await _service.removeFavorite(parfum);
    await load();
  }
}