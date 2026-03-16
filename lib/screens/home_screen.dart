import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/data_repository.dart';
import '../models/parfum.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
            },
          )
        ],
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
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 cards per row
              crossAxisSpacing: 16, // Space between columns
              mainAxisSpacing: 16, // Space between rows
              childAspectRatio: 0.7, // Taller cards (width / height ratio)
            ),
            itemCount: perfumes.length,
            itemBuilder: (context, index) {
              return PerfumeCard(parfum: perfumes[index]);
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

  const PerfumeCard({Key? key, required this.parfum}) : super(key: key);

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
          // Top Half: The Image
          Expanded(
            flex: 3,

            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                  ? Image.network(
                parfum.imageUrl!,
                fit: BoxFit.cover, // Ensures the image fills the space beautifully
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.water_drop, size: 50, color: Colors.grey),
              )
                  : const Icon(Icons.water_drop, size: 50, color: Colors.grey),
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