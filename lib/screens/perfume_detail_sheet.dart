import 'package:flutter/material.dart';
import '../models/parfum.dart';

class PerfumeDetailSheet extends StatelessWidget {
  final Parfum parfum;

  const PerfumeDetailSheet({super.key, required this.parfum});

  static void show(BuildContext context, Parfum parfum) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PerfumeDetailSheet(parfum: parfum),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Image
              if (parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    parfum.imageUrl!,
                    height: 260,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(
                          height: 260,
                          child: Icon(
                            Icons.water_drop,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                  ),
                ),

              const SizedBox(height: 20),

              // Name & brand
              Text(
                parfum.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                parfum.brand,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 24),

              // Detail grid
              _buildDetailGrid(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailGrid() {
    final details = <_DetailItem>[
      if (parfum.year != null)
        _DetailItem(Icons.calendar_today, 'Release Year', parfum.year!),
      if (parfum.rating != null)
        _DetailItem(Icons.star_outline, 'Rating', parfum.rating!),
      if (parfum.gender != null)
        _DetailItem(
          Icons.person_outline,
          'Gender',
          _capitalize(parfum.gender!),
        ),
      if (parfum.price != null)
        _DetailItem(Icons.attach_money, 'Price', '\$${parfum.price}'),
      if (parfum.oilType != null)
        _DetailItem(Icons.water_drop_outlined, 'Oil Type', parfum.oilType!),
      if (parfum.longevity != null)
        _DetailItem(Icons.timelapse, 'Longevity', parfum.longevity!),
      if (parfum.sillage != null)
        _DetailItem(Icons.air, 'Sillage', parfum.sillage!),
    ];

    if (details.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'No additional details available.',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: details.map((d) => _buildDetailChip(d)).toList(),
    );
  }

  Widget _buildDetailChip(_DetailItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}
