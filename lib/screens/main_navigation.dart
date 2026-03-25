import 'package:flutter/material.dart';
import 'package:flutter_vizsgaprojekt/services/favorites_manager.dart';
import 'home_screen.dart';
import 'finder_screen.dart';
import 'suggestions_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final FavoritesManager _favoritesManager = FavoritesManager();
  /*
  final List<Widget> _screens = [
    const HomeScreen(),
    const FinderScreen(),
    const SuggestionsScreen(),
    ProfileScreen(),
  ];
 */

  @override
  void initState() {
    super.initState();
    _favoritesManager.load();
  }

  @override
  void dispose() {
    _favoritesManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(favoritesManager: _favoritesManager),
      FinderScreen(favoritesManager: _favoritesManager),
      SuggestionsScreen(favoritesManager: _favoritesManager),
      ProfileScreen(favoritesManager: _favoritesManager),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black38,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Finder',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'Suggestions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
