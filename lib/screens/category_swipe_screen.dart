import 'package:flutter/material.dart';
import '../models/parfum.dart';
import '../services/data_repository.dart';
import '../services/favorites_manager.dart';
import 'perfume_detail_sheet.dart';

class CategorySwipeScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;
  final FavoritesManager favoritesManager;

  const CategorySwipeScreen({
    Key? key,
    required this.categoryId,
    required this.categoryTitle,
    required this.favoritesManager,
  }) : super(key: key);

  @override
  State<CategorySwipeScreen> createState() => _CategorySwipeScreenState();
}

class _CategorySwipeScreenState extends State<CategorySwipeScreen> with TickerProviderStateMixin {
  final DataRepository _dataRepo = DataRepository();

  List<Parfum> _perfumes = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isAnimating = false;

  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _angleAnimation;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _swipeAnimation = AlwaysStoppedAnimation(Offset.zero);
    _angleAnimation = const AlwaysStoppedAnimation(0);
    _swipeController.addListener(_onAnimationTick);

    _loadData();
  }

  void _onAnimationTick() {
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

  Future<void> _loadData() async {
    try {
      final results = await _dataRepo.getCategorySuggestions(widget.categoryId);
      setState(() {
        _perfumes = results;
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
    if (_isAnimating) return;
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

    _swipeAnimation = Tween<Offset>(begin: _dragOffset, end: Offset(targetX, _dragOffset.dy))
        .animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _angleAnimation = Tween<double>(begin: _dragAngle, end: targetAngle)
        .animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) {
      if (!mounted) return;
      if (toRight) {
        // Save to local favorites
        if (!widget.favoritesManager.isFavorite(_perfumes[_currentIndex])) {
          widget.favoritesManager.toggle(_perfumes[_currentIndex]);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites! ❤️'), duration: Duration(seconds: 1)),
        );
      }
      _advanceCard();
    });
  }

  void _animateBack() {
    _isAnimating = true;
    _swipeAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));
    _angleAnimation = Tween<double>(begin: _dragAngle, end: 0)
        .animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) {
      if (!mounted) return;
      _isAnimating = false;
    });
  }

  void _advanceCard() {
    _isAnimating = false;
    _swipeController.reset();
    setState(() {
      _dragOffset = Offset.zero;
      _dragAngle = 0;
      _currentIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.categoryTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.black87));
    if (_error != null) return Center(child: Text("Error: $_error"));

    if (_currentIndex >= _perfumes.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("You've seen them all!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Categories'),
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${_currentIndex + 1} of ${_perfumes.length}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_currentIndex + 1 < _perfumes.length)
                Transform.scale(scale: 0.92, child: Opacity(opacity: 0.5, child: _buildCardContent(_perfumes[_currentIndex + 1]))),
              KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _buildSwipeableCard(_perfumes[_currentIndex]),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.close, Colors.redAccent, () => _animateOffScreen(false)),
              _buildActionButton(Icons.favorite, Colors.green, () => _animateOffScreen(true)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
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
                    decoration: BoxDecoration(color: Colors.red.withOpacity((-swipeProgress * 0.4).clamp(0, 0.4)), borderRadius: BorderRadius.circular(24)),
                    alignment: Alignment.center,
                    child: Opacity(opacity: (-swipeProgress).clamp(0, 1), child: const Icon(Icons.close, color: Colors.white, size: 80)),
                  ),
                ),
              if (swipeProgress > 0.15)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.green.withOpacity((swipeProgress * 0.4).clamp(0, 0.4)), borderRadius: BorderRadius.circular(24)),
                    alignment: Alignment.center,
                    child: Opacity(opacity: swipeProgress.clamp(0, 1), child: const Icon(Icons.favorite, color: Colors.white, size: 80)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: parfum.imageUrl != null && parfum.imageUrl!.isNotEmpty
                  ? Image.network(parfum.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _FallbackImage())
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
                  Text(parfum.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2),
                  const SizedBox(height: 8),
                  Text(parfum.brand, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Text('Tap for details', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
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
    return Container(color: Colors.grey[200], child: const Icon(Icons.water_drop, size: 64, color: Colors.grey));
  }
}
