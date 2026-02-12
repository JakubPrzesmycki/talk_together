import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'category_selection_screen.dart';
import '../utils/app_scale.dart';

class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  State<GameSettingsScreen> createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  int selectedPlayers = 4;
  int selectedTime = 2; // w minutach

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: s.w(24)),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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

                      SizedBox(height: s.h(12)),

                      // Header
                      Text(
                        'game_settings.title'.tr(),
                        style: TextStyle(
                          fontSize: s.sp(32),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),

                      SizedBox(height: s.h(15)),

                      // Game description
                      Container(
                        padding: EdgeInsets.all(s.r(16)),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(s.r(20)),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('💬', style: TextStyle(fontSize: s.sp(24))),
                                SizedBox(width: s.w(12)),
                                Expanded(
                                  child: Text(
                                    'game_settings.how_to_play'.tr(),
                                    style: TextStyle(
                                      fontSize: s.sp(16),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: s.h(8)),
                            Text(
                              'game_settings.how_to_play_desc'.tr(),
                              style: TextStyle(
                                fontSize: s.sp(14),
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: s.h(30)),

                      // Players selection
                      _buildPlayerSelection(),

                      SizedBox(height: s.h(30)),

                      // Time selection
                      _buildTimeSelection(),

                      SizedBox(height: s.h(20)),
                    ],
                  ),
                ),
              ),

              // Continue button aligned like next screen CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            CategorySelectionScreen(
                          numberOfPlayers: selectedPlayers,
                          discussionTime: selectedTime,
                        ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2E0D8),
                    padding: EdgeInsets.symmetric(vertical: s.h(20)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(s.r(30)),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'buttons.continue'.tr(),
                    style: TextStyle(
                      fontSize: s.sp(20),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: s.r(1),
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

  Widget _buildPlayerSelection() {
    final s = AppScale.of(context);
    return Container(
      padding: EdgeInsets.all(s.r(24)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(s.r(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'game_settings.players'.tr(),
                style: TextStyle(
                  fontSize: s.sp(18),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: s.w(16),
                  vertical: s.h(8),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2E0D8),
                  borderRadius: BorderRadius.circular(s.r(12)),
                ),
                child: Text(
                  '$selectedPlayers',
                  style: TextStyle(
                    fontSize: s.sp(24),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: s.h(16)),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: s.h(6),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: s.r(12)),
              overlayShape: RoundSliderOverlayShape(overlayRadius: s.r(24)),
            ),
            child: Slider(
              value: selectedPlayers.toDouble(),
              min: 2,
              max: 20,
              divisions: 18,
              activeColor: const Color(0xFFB2E0D8),
              inactiveColor: Colors.grey[300],
              onChanged: (value) {
                setState(() {
                  selectedPlayers = value.toInt();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2',
                style: TextStyle(
                  fontSize: s.sp(14),
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '20',
                style: TextStyle(
                  fontSize: s.sp(14),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelection() {
    final s = AppScale.of(context);
    final times = [1, 2, 3, 5, 10];
    
    return Container(
      padding: EdgeInsets.all(s.r(24)),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(s.r(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'game_settings.discussion_time'.tr(),
            style: TextStyle(
              fontSize: s.sp(18),
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: s.h(20)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: times.map((time) {
              final isSelected = time == selectedTime;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTime = time;
                  });
                },
                child: Container(
                  width: s.w(58),
                  height: s.w(58),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFB2E0D8) : Colors.white,
                    borderRadius: BorderRadius.circular(s.r(14)),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFB2E0D8) : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$time',
                      style: TextStyle(
                        fontSize: s.sp(24),
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.grey[800] : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
