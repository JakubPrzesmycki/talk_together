import 'package:flutter/material.dart';
import 'game_settings_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pulsating animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Logo Image
              // Image.asset(
              //   'assets/images/TalkTogether_logo.png',
              //   width: 340,
              //   height: 340,
              //   errorBuilder: (context, error, stackTrace) {
              //     // Fallback if logo not found
              //     return Container(
              //       width: 120,
              //       height: 120,
              //       decoration: BoxDecoration(
              //         color: const Color(0xFFB2E0D8).withOpacity(0.3),
              //         shape: BoxShape.circle,
              //       ),
              //       child: Icon(
              //         Icons.chat_bubble_outline,
              //         size: 60,
              //         color: Colors.grey[600],
              //       ),
              //     );
              //   },
              // ),
              
              const SizedBox(height: 0),
              
              // Logo Section
              Text(
                'TalkTogether',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  letterSpacing: 1.2,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Let\'s start the conversation',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Start Button with animation
              ScaleTransition(
                scale: _pulseAnimation,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const GameSettingsScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                              .animate(animation);
                          return FadeTransition(
                            opacity: fadeAnimation,
                            child: SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFD4F5ED), // Jaśniejszy miętowy
                          Color(0xFF7FC4B3), // Ciemniejszy miętowy
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB2E0D8).withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(0xFFB2E0D8).withOpacity(0.3),
                          blurRadius: 50,
                          spreadRadius: 10,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'START',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const Spacer(flex: 2),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
