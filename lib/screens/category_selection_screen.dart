import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'countdown_screen.dart';
import '../utils/app_scale.dart';

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
  static const Map<String, String> _categoryTranslationKeys = {
    'Na luzie': 'categories.na_luzie',
    'Rodzinne': 'categories.rodzinne',
    'Znajomi': 'categories.znajomi',
    'Pikantne': 'categories.pikantne',
    'Szalone': 'categories.szalone',
    'Głębokie': 'categories.glebokie',
  };
  
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
    final s = AppScale.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletLike = screenWidth >= 700;
    final crossAxisCount = isTabletLike ? 3 : 2;
    final gridAspectRatio = isTabletLike ? 1.05 : 1.15;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.w(24)),
          child: Column(
            children: [
              SizedBox(height: s.h(20)),
              
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
                    size: s.r(24),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              
              SizedBox(height: s.h(20)),
              
              // Header
              Text(
                'category_page.title'.tr(),
                style: TextStyle(
                  fontSize: s.sp(32),
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              
              SizedBox(height: s.h(8)),
              
              Text(
                'category_page.subtitle'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: s.sp(15),
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: s.h(20)),
              
              // Categories Grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: s.w(16),
                          mainAxisSpacing: s.h(16),
                          childAspectRatio: gridAspectRatio,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: categories.entries.map((entry) {
                            return _buildCategoryCard(
                              entry.key,
                              entry.value.emoji,
                              entry.value.color,
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: s.h(20)),
              
              // Start button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedCategories.isEmpty ? null : _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2E0D8),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: EdgeInsets.symmetric(vertical: s.h(18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(s.r(30)),
                    ),
                    elevation: selectedCategories.isEmpty ? 0 : 4,
                  ),
                  child: Text(
                    selectedCategories.isEmpty 
                        ? 'buttons.select_at_least_one_category'.tr()
                        : 'buttons.start_game'.tr(),
                    style: TextStyle(
                      fontSize: s.sp(18),
                      fontWeight: FontWeight.bold,
                      color: selectedCategories.isEmpty 
                          ? Colors.grey[600]
                          : Colors.grey[800],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: s.h(20)),
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
    final s = AppScale.of(context);
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
          borderRadius: BorderRadius.circular(s.r(24)),
          border: isSelected
              ? Border.all(color: _darkenColor(color), width: s.r(4))
              : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: s.r(12),
              offset: Offset(0, s.h(6)),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: s.sp(48)),
            ),
            SizedBox(height: s.h(8)),
            Text(
              _translateCategory(title),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: s.sp(17),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateCategory(String key) {
    final translationKey = _categoryTranslationKeys[key];
    if (translationKey == null) return key;
    return translationKey.tr();
  }
}

class CategoryData {
  final String emoji;
  final Color color;

  CategoryData(this.emoji, this.color);
}
