import 'package:flutter/material.dart';
import '../models/parfum.dart';
import '../services/data_repository.dart';
import '../services/favorites_manager.dart';
import 'home_screen.dart'; // To reuse PerfumeCard
import 'perfume_detail_sheet.dart';

class FinderResultsScreen extends StatefulWidget {
  final Set<String> selectedNotes;
  final FavoritesManager favoritesManager;

  const FinderResultsScreen({
    Key? key,
    required this.selectedNotes,
    required this.favoritesManager,
  }) : super(key: key);

  @override
  State<FinderResultsScreen> createState() => _FinderResultsScreenState();
}

class _FinderResultsScreenState extends State<FinderResultsScreen> {
  final DataRepository _dataRepo = DataRepository();
  late Future<List<Parfum>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _dataRepo.getFinderResults(widget.selectedNotes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Your Matches', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Parfum>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.black87),
                  SizedBox(height: 20),
                  Text(
                    'Finding the perfect perfumes for you...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final perfumes = snapshot.data ?? [];

          if (perfumes.isEmpty) {
            return const Center(
              child: Text(
                'No perfumes matched your exact notes.\nTry modifying your selection.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

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

                  return GestureDetector(
                    onTap: () => PerfumeDetailSheet.show(context, parfum),
                    child: PerfumeCard(
                      parfum: parfum,
                      isFavorite: isFav,
                      onFavoriteToggle: () => widget.favoritesManager.toggle(parfum),
                    ),
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