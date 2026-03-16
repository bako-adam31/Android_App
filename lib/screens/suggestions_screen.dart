import 'dart:math';
import 'package:flutter/material.dart';
import '../models/parfum.dart';
import '../services/data_repository.dart';
import '../services/favorites_manager.dart';
import 'perfume_detail_sheet.dart';

class SuggestionsScreen extends StatefulWidget {
  final FavoritesManager favoritesManager;

  const SuggestionsScreen({Key? key, required this.favoritesManager}) : super(key: key);

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> with TickerProviderStateMixin {
  final DataRepository _dataRepo = DataRepository();

  List<Parfum> _perfumes = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  // Swipe animation state
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isAnimating = false; // ← guard flag

  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize with dummy animations so they're never null
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _swipeAnimation = AlwaysStoppedAnimation(Offset.zero);
    _angleAnimation = const AlwaysStoppedAnimation(0);

    _swipeController.addListener(_onAnimationTick);
    _loadSuggestions();
  }

  void _onAnimationTick() {
    // Only apply animation values while we're actively animating
    if (!_isAnimating) return;
    setState(() {
      _dragOffset = _swipeAnimation.value;
      _dragAngle = _angleAnimation.value;
    });
  }

  @override
  void dispose() {
    _swipeController.removeListener(_onAnimationTick);
    _swipeController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _dataRepo.getLattafaSuggestions();
      setState(() {
        _perfumes = results;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return; // ignore drag while animating
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = (_dragOffset.dx / 300).clamp(-0.3, 0.3);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.35;

    if (_dragOffset.dx.abs() > threshold) {
      final isRight = _dragOffset.dx > 0;
      _animateOffScreen(isRight);
    } else {
      _animateBack();
    }
  }

  void _animateOffScreen(bool toRight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = toRight ? screenWidth * 1.5 : -screenWidth * 1.5;
    final targetAngle = toRight ? 0.3 : -0.3;

    _isAnimating = true;

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _angleAnimation = Tween<double>(
      begin: _dragAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) {
      if (!mounted) return;

      if (toRight) {
        widget.favoritesManager.toggle(_perfumes[_currentIndex]);
        _showSwipeFeedback('Added to favorites! ❤️');
      }
      _advanceCard();
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
      _isAnimating = false;
    });
  }

  void _advanceCard() {
    // 1. Stop the animation flag FIRST so the listener won't overwrite
    _isAnimating = false;

    // 2. Reset the controller BEFORE setState so the listener no-ops
    _swipeController.reset();

    // 3. Now safely update state with clean values
    setState(() {
      _dragOffset = Offset.zero;
      _dragAngle = 0;
      _currentIndex++;
    });
  }

  // ... existing code ...

  void _showSwipeFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      ),
    );
  }

  bool get _hasCards => _currentIndex < _perfumes.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black87));
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (!_hasCards) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text('Skip', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(width: 24),
              Text('Favorite', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            // Use a unique key per index so Flutter rebuilds the card widget cleanly
            children: [
              if (_currentIndex + 1 < _perfumes.length)
                _buildStaticCard(_perfumes[_currentIndex + 1]),
              KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _buildSwipeableCard(_perfumes[_currentIndex]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 8),
          child: Text(
            '${_currentIndex + 1} / ${_perfumes.length}',
            style: TextStyle(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.w500),
          ),
        ),
      ],
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Colors.red.withOpacity((-swipeProgress * 0.4).clamp(0, 0.4)),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: (-swipeProgress).clamp(0, 1),
                        child: const Icon(Icons.close, color: Colors.white, size: 64),
                      ),
                    ),
                  ),
                ),
              if (swipeProgress > 0.15)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      color: Colors.green.withOpacity((swipeProgress * 0.4).clamp(0, 0.4)),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: swipeProgress.clamp(0, 1),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 64),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ... existing code ...

  Widget _buildStaticCard(Parfum parfum) {
    return Transform.scale(
      scale: 0.92,
      child: Opacity(
        opacity: 0.5,
        child: _buildCardContent(parfum),
      ),
    );
  }

  Widget _buildCardContent(Parfum parfum) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.58,
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
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.water_drop, size: 64, color: Colors.grey),
                ),
              )
                  : Container(
                color: Colors.grey[200],
                child: const Icon(Icons.water_drop, size: 64, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    parfum.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    parfum.brand,
                    style: TextStyle(fontSize: 15, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.black.withOpacity(0.12)),
            const SizedBox(height: 16),
            const Text("You've seen them all!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Check back later for new suggestions', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadSuggestions,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Start over'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black26),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text('Something went wrong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadSuggestions,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Colors.black26),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}