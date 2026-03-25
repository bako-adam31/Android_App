import 'package:flutter/material.dart';
import '../models/accord_category.dart';
import '../services/favorites_manager.dart';
import 'category_swipe_screen.dart';

class SuggestionsScreen extends StatefulWidget {
  final FavoritesManager favoritesManager;
  final AccordCategory? initialCategory;

  const SuggestionsScreen({
    super.key,
    required this.favoritesManager,
    this.initialCategory,
  });

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  bool _didOpenInitialCategory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialCategoryIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant SuggestionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _didOpenInitialCategory = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInitialCategoryIfNeeded();
      });
    }
  }

  void _openInitialCategoryIfNeeded() {
    final initialCategory = widget.initialCategory;
    if (!mounted || _didOpenInitialCategory || initialCategory == null) {
      return;
    }

    _didOpenInitialCategory = true;
    _openCategory(initialCategory);
  }

  void _openCategory(AccordCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySwipeScreen(
          category: category,
          favoritesManager: widget.favoritesManager,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = AccordCategories.all;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return GestureDetector(
            onTap: () => _openCategory(category),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(category.icon, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
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
