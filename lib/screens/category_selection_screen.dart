import 'package:flutter/material.dart';
import 'countdown_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  final int numberOfPlayers;
  final int discussionTime;

  const CategorySelectionScreen({
    super.key,
    required this.numberOfPlayers,
    required this.discussionTime,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final Set<String> selectedCategories = {};
  
  final Map<String, CategoryData> categories = {
    'Na luzie': CategoryData('😎', const Color(0xFFB2E0D8)),
    'Rodzinne': CategoryData('👨‍👩‍👧‍👦', const Color(0xFFFFD4B8)),
    'Znajomi': CategoryData('🎉', const Color(0xFFFFF4B8)),
    'Pikantne': CategoryData('🌶️', const Color(0xFFFFB8C6)),
    'Szalone': CategoryData('🤪', const Color(0xFFD4B8FF)),
    'Głębokie': CategoryData('💭', const Color(0xFFB8D4FF)),
  };

  void _toggleCategory(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
  }

  void _startGame() {
    if (selectedCategories.isEmpty) return;
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CountdownScreen(
          categories: selectedCategories.toList(),
          categoriesData: categories,
          numberOfPlayers: widget.numberOfPlayers,
          discussionTime: widget.discussionTime,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeIn,
          ));
          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.grey[700],
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Header
              Text(
                'Wybierz kategorie',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Możesz wybrać więcej niż jedną!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Categories Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.15,
                  children: categories.entries.map((entry) {
                    return _buildCategoryCard(
                      entry.key,
                      entry.value.emoji,
                      entry.value.color,
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedCategories.isEmpty ? null : _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2E0D8),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: selectedCategories.isEmpty ? 0 : 4,
                  ),
                  child: Text(
                    selectedCategories.isEmpty 
                        ? 'Wybierz co najmniej 1 kategorię'
                        : 'Start gry (${selectedCategories.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selectedCategories.isEmpty 
                          ? Colors.grey[600]
                          : Colors.grey[800],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String emoji,
    Color color,
  ) {
    final isSelected = selectedCategories.contains(title);
    
    Color _darkenColor(Color color, [double amount = 0.2]) {
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).toColor();
    }
    
    return GestureDetector(
      onTap: () => _toggleCategory(title),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: _darkenColor(color), width: 4)
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryData {
  final String emoji;
  final Color color;

  CategoryData(this.emoji, this.color);
}
