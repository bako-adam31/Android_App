import 'package:flutter/material.dart';
import 'package:flutter_vizsgaprojekt/services/favorites_manager.dart';
import '../services/auth_service.dart';
import '../services/data_repository.dart';
import '../models/parfum.dart';

class HomeScreen extends StatefulWidget {
  final FavoritesManager favoritesManager;

  const HomeScreen({Key? key, required this.favoritesManager}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final DataRepository _dataRepo = DataRepository();

  late Future<List<Parfum>> _tomFordFragrances;

  @override
  void initState() {
    super.initState();
    _tomFordFragrances = _dataRepo.getTomFordFragrances();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Slightly lighter background to make cards pop
      appBar: AppBar(
        title: const Text('Sharqi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,

      ),
      body: FutureBuilder<List<Parfum>>(
        future: _tomFordFragrances,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black87));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No fragrances found.'));
          }

          final perfumes = snapshot.data!;

          // Using a GridView instead of a ListView to show cards side-by-side

          return AnimatedBuilder(
            animation: widget.favoritesManager,
            builder: (context, _) {
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemCount: perfumes.length,
                itemBuilder: (context, index) {
                  final parfum = perfumes[index];
                  final isFav = widget.favoritesManager.isFavorite(parfum);
                  return PerfumeCard(
                    parfum: parfum,
                    isFavorite: isFav,
                    onFavoriteToggle: () => widget.favoritesManager.toggle(parfum),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Your Custom Perfume Card Widget (Translating 'createGlassCard' from Java)
class PerfumeCard extends StatelessWidget {
  final Parfum parfum;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const PerfumeCard({
    Key? key,
    required this.parfum,
    required this.isFavorite,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Matches your JavaFX clip radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Soft, modern shadow
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          Expanded(
            flex: 3,
            child: Stack (
              children: [
                ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox.expand(
                  child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                      ? Image.network(
                    parfum.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.water_drop, size: 50, color: Colors.grey),
                  )
                      : const Icon(Icons.water_drop, size: 50, color: Colors.grey),
                ),
              ),


                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),

              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        parfum.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parfum.brand,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
