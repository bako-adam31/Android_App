import 'package:flutter/material.dart';
import '../services/favorites_manager.dart';
import 'finder_results_screen.dart';

class FinderScreen extends StatefulWidget {
  final FavoritesManager favoritesManager;

  const FinderScreen({Key? key, required this.favoritesManager}) : super(key: key);

  @override
  State<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends State<FinderScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final Set<String> _selectedNotes = {};

  final List<Map<String, dynamic>> _wizardSteps = [
    {'title': 'Citrus Notes', 'notes': ['Lemon', 'Orange', 'Grapefruit', 'Yuzu', 'Lime', 'Bergamot']},
    {'title': 'Fruity Notes', 'notes': ['Raspberry', 'Cherry', 'Pineapple', 'Blackcurrant', 'Fig', 'Pear']},
    {'title': 'Oriental Notes', 'notes': ['Tobacco', 'Vanilla', 'Saffron', 'Cardamom', 'Pepper', 'Cinnamon']},
    {'title': 'Woody Notes', 'notes': ['Lavender', 'Vetiver', 'Patchouli', 'Sandalwood', 'Leather', 'Oak Moss']},
    {'title': 'Fresh Notes', 'notes': ['Rosemary', 'Sage', 'Mint', 'Green Tea', 'Salt', 'Sea']},
    {'title': 'Sweet Notes', 'notes': ['Caramel', 'Honey', 'Praline', 'Nutmeg', 'Chocolate', 'Cacao']},
  ];

  void _toggleNote(String note) {
    setState(() {
      if (_selectedNotes.contains(note)) {
        _selectedNotes.remove(note);
      } else {
        _selectedNotes.add(note);
      }
    });
  }

  void _nextStep() {
    final currentStepNotes = List<String>.from(_wizardSteps[_currentStep]['notes']);
    final hasSelection = currentStepNotes.any((note) => _selectedNotes.contains(note));

    if (!hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one note to continue.')),
      );
      return;
    }

    if (_currentStep < _wizardSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Final step -> Navigate to results
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FinderResultsScreen(
            selectedNotes: _selectedNotes,
            favoritesManager: widget.favoritesManager,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // If embedded in BottomNavBar, pop might exit app if not handled,
          // but visually required by specs.
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Pick your favorite notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_wizardSteps.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentStep == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentStep == index ? Colors.black87 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce selection
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemCount: _wizardSteps.length,
              itemBuilder: (context, index) {
                final step = _wizardSteps[index];
                final notes = List<String>.from(step['notes']);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: notes.length,
                          itemBuilder: (context, noteIndex) {
                            final note = notes[noteIndex];
                            final isSelected = _selectedNotes.contains(note);

                            return GestureDetector(
                              onTap: () => _toggleNote(note),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.black87 : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.black87 : Colors.grey.shade300,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  note,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _nextStep,
                child: Text(
                  _currentStep == _wizardSteps.length - 1 ? 'Find Perfumes' : 'Next',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}