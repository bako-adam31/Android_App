import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/perfume_details.dart';
import '../services/perfume_repository.dart';

class PerfumeDetailsScreen extends StatefulWidget {
  final PerfumeDetails perfume;

  const PerfumeDetailsScreen({super.key, required this.perfume});

  @override
  State<PerfumeDetailsScreen> createState() => _PerfumeDetailsScreenState();
}

class _PerfumeDetailsScreenState extends State<PerfumeDetailsScreen> {
  final PerfumeRepository _repository = PerfumeRepository();
  late Future<PerfumeDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _repository.getPerfumeDetails(widget.perfume);
  }

  Future<void> _openPurchaseUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final didLaunch = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!didLaunch && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the purchase link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<PerfumeDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black87),
            );
          }

          if (snapshot.hasError) {
            return _PerfumeDetailsErrorView(
              onRetry: () {
                setState(() {
                  _detailsFuture = _repository.getPerfumeDetails(
                    widget.perfume,
                  );
                });
              },
            );
          }

          final perfume = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 360,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: _PerfumeHero(perfume: perfume),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PerfumeHeading(perfume: perfume),
                      const SizedBox(height: 20),
                      _PerfumeFactsGrid(perfume: perfume),
                      if (perfume.mainAccords.isNotEmpty ||
                          perfume.mainAccordLevels.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionCard(
                          title: 'Main Accords',
                          child: _MainAccordsSection(perfume: perfume),
                        ),
                      ],
                      if (perfume.generalNotes.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: 'General Notes',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: perfume.generalNotes
                                .map((note) => _PerfumeChip(label: note))
                                .toList(),
                          ),
                        ),
                      ],
                      if (perfume.topNotes.isNotEmpty ||
                          perfume.middleNotes.isNotEmpty ||
                          perfume.baseNotes.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: 'Note Pyramid',
                          child: Column(
                            children: [
                              if (perfume.topNotes.isNotEmpty)
                                _NoteGroupCard(
                                  title: 'Top Notes',
                                  notes: perfume.topNotes,
                                ),
                              if (perfume.middleNotes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _NoteGroupCard(
                                  title: 'Middle Notes',
                                  notes: perfume.middleNotes,
                                ),
                              ],
                              if (perfume.baseNotes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _NoteGroupCard(
                                  title: 'Base Notes',
                                  notes: perfume.baseNotes,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (perfume.seasonRanking.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: 'Season Ranking',
                          child: _RankingSection(
                            rankings: perfume.seasonRanking,
                          ),
                        ),
                      ],
                      if (perfume.occasionRanking.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _SectionCard(
                          title: 'Occasion Ranking',
                          child: _RankingSection(
                            rankings: perfume.occasionRanking,
                          ),
                        ),
                      ],
                      if (perfume.purchaseUrl != null) ...[
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _openPurchaseUrl(perfume.purchaseUrl!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Open Purchase Link'),
                          ),
                        ),
                      ],
                    ],
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

class _PerfumeHero extends StatelessWidget {
  final PerfumeDetails perfume;

  const _PerfumeHero({required this.perfume});

  @override
  Widget build(BuildContext context) {
    final heroImage = perfume.heroImageUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8F6F2), Color(0xFFECE7DF)],
            ),
          ),
        ),
        if (heroImage != null)
          Image.network(
            heroImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _PerfumeImagePlaceholder(iconSize: 64),
          )
        else
          const _PerfumeImagePlaceholder(iconSize: 64),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0),
                Colors.black.withValues(alpha: 0.4),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PerfumeHeading extends StatelessWidget {
  final PerfumeDetails perfume;

  const _PerfumeHeading({required this.perfume});

  @override
  Widget build(BuildContext context) {
    final infoChips = <Widget>[
      if (perfume.year != null) _PerfumeChip(label: perfume.year!),
      if (perfume.gender != null)
        _PerfumeChip(label: _titleCase(perfume.gender!)),
      if (perfume.country != null) _PerfumeChip(label: perfume.country!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          perfume.brand,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          perfume.name,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            height: 1.15,
          ),
        ),
        if (infoChips.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: infoChips),
        ],
      ],
    );
  }
}

class _PerfumeFactsGrid extends StatelessWidget {
  final PerfumeDetails perfume;

  const _PerfumeFactsGrid({required this.perfume});

  @override
  Widget build(BuildContext context) {
    final facts = <_FactItem>[
      if (perfume.rating != null) _FactItem('Rating', perfume.rating!),
      if (perfume.oilType != null) _FactItem('Oil Type', perfume.oilType!),
      if (perfume.price != null) _FactItem('Price', perfume.price!),
      if (perfume.longevity != null) _FactItem('Longevity', perfume.longevity!),
      if (perfume.sillage != null) _FactItem('Sillage', perfume.sillage!),
      if (perfume.popularity != null)
        _FactItem('Popularity', perfume.popularity!),
      if (perfume.confidence != null)
        _FactItem('Confidence', _titleCase(perfume.confidence!)),
      if (perfume.priceValue != null)
        _FactItem('Price Value', _titleCase(perfume.priceValue!)),
    ];

    if (facts.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: facts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final fact = facts[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fact.label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fact.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MainAccordsSection extends StatelessWidget {
  final PerfumeDetails perfume;

  const _MainAccordsSection({required this.perfume});

  @override
  Widget build(BuildContext context) {
    final accordRows = perfume.mainAccordLevels.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (perfume.mainAccords.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: perfume.mainAccords
                .map((accord) => _PerfumeChip(label: _titleCase(accord)))
                .toList(),
          ),
        if (accordRows.isNotEmpty) ...[
          const SizedBox(height: 18),
          Column(
            children: accordRows.map((entry) {
              final normalizedLevel = _mapAccordLevel(entry.value);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titleCase(entry.key),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          entry.value,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: normalizedLevel,
                        minHeight: 9,
                        backgroundColor: Colors.black.withValues(alpha: 0.06),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF1E3932),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _NoteGroupCard extends StatelessWidget {
  final String title;
  final List<PerfumeNote> notes;

  const _NoteGroupCard({required this.title, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: notes
                .map((note) => _PerfumeNoteChip(note: note))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final List<PerfumeRanking> rankings;

  const _RankingSection({required this.rankings});

  @override
  Widget build(BuildContext context) {
    final maxScore = rankings
        .map((ranking) => ranking.score)
        .fold<double>(0, (current, value) => value > current ? value : current);
    final safeMaxScore = maxScore <= 0 ? 1.0 : maxScore;

    return Column(
      children: rankings.map((ranking) {
        final progress = (ranking.score / safeMaxScore).clamp(0, 1).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  _titleCase(ranking.name),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF3B6256)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                ranking.score.toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PerfumeNoteChip extends StatelessWidget {
  final PerfumeNote note;

  const _PerfumeNoteChip({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NoteImage(imageUrl: note.imageUrl),
          const SizedBox(width: 8),
          Text(note.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PerfumeChip extends StatelessWidget {
  final String label;

  const _PerfumeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _NoteImage extends StatelessWidget {
  final String? imageUrl;

  const _NoteImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.spa_outlined, size: 14, color: Colors.grey),
      );
    }

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: 26,
        height: 26,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 26,
          height: 26,
          color: Colors.grey[100],
          alignment: Alignment.center,
          child: const Icon(Icons.spa_outlined, size: 14, color: Colors.grey),
        ),
      ),
    );
  }
}

class _PerfumeImagePlaceholder extends StatelessWidget {
  final double iconSize;

  const _PerfumeImagePlaceholder({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      alignment: Alignment.center,
      child: Icon(
        Icons.water_drop_outlined,
        size: iconSize,
        color: Colors.grey,
      ),
    );
  }
}

class _PerfumeDetailsErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PerfumeDetailsErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 34,
              color: Colors.black54,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load this perfume right now.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _FactItem {
  final String label;
  final String value;

  const _FactItem(this.label, this.value);
}

double _mapAccordLevel(String level) {
  switch (level.trim().toLowerCase()) {
    case 'dominant':
      return 1;
    case 'prominent':
      return 0.8;
    case 'moderate':
      return 0.6;
    case 'noticeable':
      return 0.4;
    case 'light':
      return 0.25;
    default:
      return 0.35;
  }
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
