import 'package:flutter/material.dart';
import '../services/favorites_manager.dart';
import 'category_swipe_screen.dart';

class SuggestionsScreen extends StatelessWidget {
  final FavoritesManager favoritesManager;

  const SuggestionsScreen({Key? key, required this.favoritesManager}) : super(key: key);

  final List<Map<String, String>> _categories = const [
    {
      'id': 'niche',
      'title': 'Niche Perfumes',
      'subtitle': 'Exclusive & Artistic (e.g. Xerjoff)',
      'icon': '💎'
    },
    {
      'id': 'designer',
      'title': 'Designer Perfumes',
      'subtitle': 'Classic & Popular (e.g. Dior)',
      'icon': '✨'
    },
    {
      'id': 'gourmand',
      'title': 'Gourmand Perfumes',
      'subtitle': 'Sweet, Vanilla & Edible notes',
      'icon': '🧁'
    },
    {
      'id': 'citrusy',
      'title': 'Citrusy Perfumes',
      'subtitle': 'Fresh, Zesty & Energizing',
      'icon': '🍋'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Discover', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[300],
        foregroundColor: Colors.blueGrey[900],
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategorySwipeScreen(
                    categoryId: cat['id']!,
                    categoryTitle: cat['title']!,
                    favoritesManager: favoritesManager,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueGrey[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(cat['icon']!, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat['title']!,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat['subtitle']!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black26),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}