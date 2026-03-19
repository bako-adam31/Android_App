import 'package:shared_preferences/shared_preferences.dart';

class SuggestionsSeenService {
  static String _key(String seenKey) => 'suggestions_$seenKey';

  Future<Set<String>> getSeenIds(String seenKey) async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key(seenKey)) ?? <String>[];
    return values.toSet();
  }

  Future<void> markSeen(String seenKey, String perfumeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key(seenKey)) ?? <String>[]).toSet();

    if (current.add(perfumeKey)) {
      await prefs.setStringList(_key(seenKey), current.toList());
    }
  }
}