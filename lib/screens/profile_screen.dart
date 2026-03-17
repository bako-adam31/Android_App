import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/favorites_manager.dart';
import '../models/parfum.dart';

class ProfileScreen extends StatelessWidget {
  final FavoritesManager favoritesManager;

  ProfileScreen({Key? key, required this.favoritesManager}) : super(key: key);

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: favoritesManager,
        builder: (context, _) {
          final favorites = favoritesManager.favorites;

          return CustomScrollView(
            slivers: [
              // ── User Info ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.person, size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? 'Fragrance Lover',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Favorites Header ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Favorites',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (favorites.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${favorites.length}',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Favorites List or Empty State ──
              if (favorites.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      children: [
                        Icon(Icons.favorite_border, size: 48, color: Colors.black.withOpacity(0.12)),
                        const SizedBox(height: 12),
                        Text(
                          'No favorites yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the heart on any fragrance to save it here',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final parfum = favorites[index];
                        return _FavoriteListItem(
                          parfum: parfum,
                          onRemove: () => favoritesManager.remove(parfum),
                        );
                      },
                      childCount: favorites.length,
                    ),
                  ),
                ),

              // ── Logout Button ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Log out'),
                            content: const Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await _authService.logout();
                        }
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Log out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoriteListItem extends StatelessWidget {
  final Parfum parfum;
  final VoidCallback onRemove;

  const _FavoriteListItem({required this.parfum, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 52,
            height: 52,
            child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                ? Image.network(
              parfum.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.water_drop, color: Colors.grey),
            )
                : const Icon(Icons.water_drop, color: Colors.grey),
          ),
        ),
        title: Text(
          parfum.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          parfum.brand,
          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
        ),
        trailing: GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
        ),
      ),
    );
  }
}