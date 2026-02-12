import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'game_screen.dart';
import 'category_selection_screen.dart';

class CountdownScreen extends StatefulWidget {
  final List<String> categories;
  final Map<String, CategoryData> categoriesData;
  final int numberOfPlayers;
  final int discussionTime;

  const CountdownScreen({
    super.key,
    required this.categories,
    required this.categoriesData,
    required this.numberOfPlayers,
    required this.discussionTime,
  });

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with SingleTickerProviderStateMixin {
  int countdown = 3;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  
  bool get isSingleCategory => widget.categories.length == 1;
  late CategoryData singleCategoryData;

  @override
  void initState() {
    super.initState();
    
    if (isSingleCategory) {
      singleCategoryData = widget.categoriesData[widget.categories.first]!;
    }
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    // Ustaw animację na koniec, żeby 3 była od razu duża
    _animationController.value = 1.0;
    
    // Opóźnienie 0.5 sekundy przed rozpoczęciem odliczania
    Future.delayed(const Duration(milliseconds: 20), () {
      if (!mounted) return;

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (countdown > 0) {
          setState(() {
            countdown--;
          });
          _animationController.reset();
          _animationController.forward();
        } else {
          timer.cancel();
          _navigateToGame();
        }
      });
    });
  }

  void _navigateToGame() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GameScreen(
          categories: widget.categories,
          categoriesData: widget.categoriesData,
          numberOfPlayers: widget.numberOfPlayers,
          discussionTime: widget.discussionTime,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  String _getCountdownText() {
    return countdown.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isSingleCategory
                ? [
                    singleCategoryData.color.withOpacity(0.3),
                    Colors.white,
                    Colors.white,
                  ]
                : [
                    const Color(0xFFD0D0D0),
                    const Color(0xFFF5F5F5),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Emoji in top center
              Positioned(
                top: isSingleCategory ? 60 : 100,
                left: 0,
                right: 0,
                child: Center(
                  child: isSingleCategory
                      ? Text(
                          singleCategoryData.emoji,
                          style: const TextStyle(fontSize: 80),
                        )
                      : Image.asset(
                          'assets/images/question_mark_icon.png',
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if icon not found
                            return Text(
                              'countdown.fallback_icon'.tr(),
                              style: const TextStyle(fontSize: 80),
                            );
                          },
                        ),
                ),
              ),
              
              // Countdown number perfectly centered
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Text(
                    _getCountdownText(),
                    style: TextStyle(
                      fontSize: 180,
                      fontWeight: FontWeight.bold,
                      color: isSingleCategory
                          ? singleCategoryData.color.withOpacity(0.9)
                          : Colors.grey[700],
                      letterSpacing: 2,
                      height: 1,
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
}
