import 'package:flutter/material.dart';
import '../models/parfum.dart';
import '../models/accord_category.dart';
import '../services/data_repository.dart';
import '../services/favorites_manager.dart';
import 'perfume_detail_sheet.dart';

class CategorySwipeScreen extends StatefulWidget {
  final AccordCategory category;
  final FavoritesManager favoritesManager;

  const CategorySwipeScreen({
    Key? key,
    required this.category,
    required this.favoritesManager,
  }) : super(key: key);

  @override
  State<CategorySwipeScreen> createState() => _CategorySwipeScreenState();
}

class _CategorySwipeScreenState extends State<CategorySwipeScreen>
    with SingleTickerProviderStateMixin {
  final DataRepository _dataRepo = DataRepository();

  final List<Parfum> _queue = [];
  bool _isLoading = true;
  bool _isAnimating = false;
  bool _isRefilling = false;
  bool _isExhausted = false;
  String? _error;

  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;

  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _swipeAnimation = const AlwaysStoppedAnimation(Offset.zero);
    _angleAnimation = const AlwaysStoppedAnimation(0);
    _swipeController.addListener(_onAnimationTick);

    _initialLoad();
  }

  @override
  void dispose() {
    _swipeController.removeListener(_onAnimationTick);
    _swipeController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    if (!_isAnimating) return;
    setState(() {
      _dragOffset = _swipeAnimation.value;
      _dragAngle = _angleAnimation.value;
    });
  }

  Future<void> _initialLoad() async {
    try {
      final results = await _fetchBatch();

      if (!mounted) return;
      setState(() {
        _queue
          ..clear()
          ..addAll(results.perfumes);
        _isExhausted = results.exhausted;
        _isLoading = false;
      });

      _refillIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<CategoryFeedResult> _fetchBatch() {
    return _dataRepo.getAccordCategorySuggestions(
      category: widget.category,
      favoritesManager: widget.favoritesManager,
      targetCount: 10,
    );
  }

  Future<void> _refillIfNeeded() async {
    if (_isLoading || _isRefilling || _isExhausted) return;
    if (_queue.length >= 4) return;

    _isRefilling = true;
    try {
      final results = await _fetchBatch();
      if (!mounted) return;

      final existing = _queue.map((e) => e.stableKey).toSet();
      final incoming = results.perfumes
          .where((p) => !existing.contains(p.stableKey))
          .toList();

      setState(() {
        _queue.addAll(incoming);
        if (_queue.isEmpty && results.exhausted) {
          _isExhausted = true;
        }
      });
    } finally {
      _isRefilling = false;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating || _queue.isEmpty) return;

    setState(() {
      _dragOffset += details.delta;
      _dragAngle = (_dragOffset.dx / 300).clamp(-0.3, 0.3);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating || _queue.isEmpty) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.30;

    if (_dragOffset.dx > threshold) {
      _animateOffScreen(true);
    } else if (_dragOffset.dx < -threshold) {
      _animateOffScreen(false);
    } else {
      _animateBack();
    }
  }

  void _animateOffScreen(bool toRight) {
    if (_queue.isEmpty) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = toRight ? screenWidth * 1.4 : -screenWidth * 1.4;
    final targetAngle = toRight ? 0.28 : -0.28;

    _isAnimating = true;

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _angleAnimation = Tween<double>(
      begin: _dragAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) async {
      if (!mounted || _queue.isEmpty) return;

      final current = _queue.first;

      await _dataRepo.markCategorySeen(
        category: widget.category,
        parfum: current,
      );

      if (toRight && !widget.favoritesManager.isFavorite(current)) {
        await widget.favoritesManager.toggle(current);
      }

      if (!mounted) return;

      setState(() {
        _queue.removeAt(0);
        _dragOffset = Offset.zero;
        _dragAngle = 0;
        _isAnimating = false;
      });

      _swipeController.reset();
      _refillIfNeeded();
    });
  }

  void _animateBack() {
    _isAnimating = true;

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _angleAnimation = Tween<double>(
      begin: _dragAngle,
      end: 0,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) {
      if (!mounted) return;

      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0;
        _isAnimating = false;
      });

      _swipeController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _queue.isNotEmpty ? _queue[0] : null;
    final next = _queue.length > 1 ? _queue[1] : null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.category.label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(current, next),
    );
  }

  Widget _buildBody(Parfum? current, Parfum? next) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black87),
      );
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (current == null) {
      if (!_isExhausted) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.black87),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No more ${widget.category.label} suggestions',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You already used the current fallback pools.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${_queue.length} ready',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (next != null)
                IgnorePointer(
                  child: Transform.scale(
                    scale: 0.93,
                    child: Opacity(
                      opacity: 0.55,
                      child: _buildCardContent(next),
                    ),
                  ),
                ),
              _buildSwipeableCard(current),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.close, Colors.redAccent, () {
                _animateOffScreen(false);
              }),
              _buildActionButton(Icons.favorite, Colors.green, () {
                _animateOffScreen(true);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: _isAnimating ? null : onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }

  Widget _buildSwipeableCard(Parfum parfum) {
    final swipeProgress = (_dragOffset.dx / 120).clamp(-1.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: () => PerfumeDetailSheet.show(context, parfum),
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _dragAngle,
          child: Stack(
            children: [
              _buildCardContent(parfum),
              if (swipeProgress < -0.15)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(
                        (-swipeProgress * 0.4).clamp(0, 0.4),
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: (-swipeProgress).clamp(0, 1),
                      child: const Icon(Icons.close, color: Colors.white, size: 80),
                    ),
                  ),
                ),
              if (swipeProgress > 0.15)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(
                        (swipeProgress * 0.4).clamp(0, 0.4),
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: swipeProgress.clamp(0, 1),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 80),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(Parfum parfum) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                  ? Image.network(
                parfum.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _FallbackImage(),
              )
                  : const _FallbackImage(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    parfum.brand,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    parfum.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap for details',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
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

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.water_drop, size: 64, color: Colors.grey),
    );
  }
}