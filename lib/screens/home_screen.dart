import 'package:flutter/material.dart';

import '../models/accord_category.dart';
import '../models/parfum.dart';
import '../services/data_repository.dart';
import '../services/favorites_manager.dart';
import '../services/profile_repository.dart';
import 'perfume_detail_sheet.dart';
import 'suggestions_screen.dart';

class HomeScreen extends StatefulWidget {
  final FavoritesManager favoritesManager;
  final bool isActive;

  const HomeScreen({
    super.key,
    required this.favoritesManager,
    this.isActive = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataRepository _repository = DataRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  late Future<_ForYouRecommendations> _forYouFuture;

  @override
  void initState() {
    super.initState();
    _forYouFuture = _loadForYouRecommendations();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _refreshForYou();
    }
  }

  Future<_ForYouRecommendations> _loadForYouRecommendations() async {
    final profile = await _profileRepository.getMyProfile();
    final favoriteAccord = profile.favoriteAccord;

    if (favoriteAccord != null) {
      final accordPerfumes = await _repository.getAccordRecommendations(
        category: favoriteAccord,
        limit: 4,
      );

      if (accordPerfumes.isNotEmpty) {
        return _ForYouRecommendations(
          perfumes: accordPerfumes,
          favoriteAccord: favoriteAccord,
          usedFallback: false,
        );
      }
    }

    final fallbackPerfumes = await _repository.getTomFordRecommendations(
      limit: 4,
    );

    return _ForYouRecommendations(
      perfumes: fallbackPerfumes,
      favoriteAccord: favoriteAccord,
      usedFallback: true,
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _forYouFuture = _loadForYouRecommendations();
    });
    await _forYouFuture;
  }

  void _refreshForYou() {
    if (!mounted) return;
    setState(() {
      _forYouFuture = _loadForYouRecommendations();
    });
  }

  void _openSuggestions({AccordCategory? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestionsScreen(
          favoritesManager: widget.favoritesManager,
          initialCategory: category,
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
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.black87,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _SectionHeader(
              title: 'Suggestions',
              subtitle:
                  'Jump straight into the category that matches your mood.',
              action: TextButton(
                onPressed: () => _openSuggestions(),
                child: const Text('See all'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 122,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return _CategoryShortcutCard(
                    category: category,
                    onTap: () => _openSuggestions(category: category),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            FutureBuilder<_ForYouRecommendations>(
              future: _forYouFuture,
              builder: (context, snapshot) {
                return _buildForYouSection(snapshot);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForYouSection(AsyncSnapshot<_ForYouRecommendations> snapshot) {
    final subtitle =
        snapshot.data?.subtitle ??
        'Personalized recommendations powered by your saved profile.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'For You',
          subtitle: subtitle,
          action: IconButton(
            onPressed: _refreshForYou,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh recommendations',
          ),
        ),
        const SizedBox(height: 12),
        if (snapshot.connectionState == ConnectionState.waiting)
          const _StateCard(
            icon: Icons.auto_awesome_outlined,
            message: 'Loading recommendations tailored to your profile...',
            child: CircularProgressIndicator(color: Colors.black87),
          )
        else if (snapshot.hasError)
          _StateCard(
            icon: Icons.error_outline_rounded,
            message:
                'We could not load your personalized recommendations right now.',
            actionLabel: 'Try again',
            onAction: _refreshForYou,
          )
        else if ((snapshot.data?.perfumes ?? []).isEmpty)
          _StateCard(
            icon: Icons.local_florist_outlined,
            message: 'No recommendations are available at the moment.',
            actionLabel: 'Refresh',
            onAction: _refreshForYou,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.perfumes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.68,
            ),
            itemBuilder: (context, index) {
              final parfum = snapshot.data!.perfumes[index];
              return _ForYouPerfumeCard(
                parfum: parfum,
                onTap: () => PerfumeDetailSheet.show(context, parfum),
              );
            },
          ),
      ],
    );
  }
}

class _ForYouRecommendations {
  final List<Parfum> perfumes;
  final AccordCategory? favoriteAccord;
  final bool usedFallback;

  const _ForYouRecommendations({
    required this.perfumes,
    required this.favoriteAccord,
    required this.usedFallback,
  });

  String get subtitle {
    if (favoriteAccord != null && !usedFallback) {
      return 'Inspired by your ${favoriteAccord!.label.toLowerCase()} profile preference.';
    }

    if (favoriteAccord != null && usedFallback) {
      return 'Your saved accord is ${favoriteAccord!.label}, so we prepared a Tom Ford fallback while better matches load.';
    }

    return 'Set a favorite accord in your profile to unlock more personal picks. For now, here are Tom Ford essentials.';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ],
    );
  }
}

class _CategoryShortcutCard extends StatelessWidget {
  final AccordCategory category;
  final VoidCallback onTap;

  const _CategoryShortcutCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category.icon, style: const TextStyle(fontSize: 28)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForYouPerfumeCard extends StatelessWidget {
  final Parfum parfum;
  final VoidCallback onTap;

  const _ForYouPerfumeCard({required this.parfum, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                    ? Image.network(
                        parfum.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      )
                    : const Icon(Icons.image_not_supported),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    parfum.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parfum.brand,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? child;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _StateCard({
    required this.icon,
    required this.message,
    this.child,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.black54),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (child != null) ...[const SizedBox(height: 16), child!],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
