import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'game_settings_screen.dart';
import '../utils/app_scale.dart';
import '../models/daily_streak_status.dart';
import '../services/daily_streak_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLanguageHandlePressed = false;
  bool _isStreakHandlePressed = false;
  DailyStreakStatus _streakStatus = const DailyStreakStatus(
    streakDays: 0,
    hasAnsweredToday: false,
    lastAnsweredDate: null,
  );

  @override
  void initState() {
    super.initState();

    // Pulsating animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadStreakStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    final isTabletLike = MediaQuery.sizeOf(context).width >= 700;
    final languageHandleFactor = isTabletLike ? 1.25 : 1.0;
    final streakHandleFactor = isTabletLike ? 1.18 : 1.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  Image.asset(
                    'assets/images/talk_together_logo.png',
                    width: s.w(100),
                    height: s.w(100),
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if logo not found
                      return Container(
                        width: s.w(120),
                        height: s.w(120),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB2E0D8).withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: s.r(60),
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),

                  // Logo Section
                  Text(
                    'game_title'.tr(),
                    style: TextStyle(
                      fontSize: s.sp(48),
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: s.r(1.2),
                    ),
                  ),

                  SizedBox(height: s.h(12)),

                  Text(
                    'start_page.tagline'.tr(),
                    style: TextStyle(
                      fontSize: s.sp(16),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Start Button with animation
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: GestureDetector(
                      onTap: _openGameSettings,
                      child: Container(
                        width: s.w(160),
                        height: s.w(160),
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
                              blurRadius: s.r(30),
                              spreadRadius: s.r(5),
                              offset: Offset(0, s.h(8)),
                            ),
                            BoxShadow(
                              color: const Color(0xFFB2E0D8).withOpacity(0.3),
                              blurRadius: s.r(50),
                              spreadRadius: s.r(10),
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'buttons.start'.tr(),
                            style: TextStyle(
                              fontSize: s.sp(24),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                              letterSpacing: s.r(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  SizedBox(height: s.h(30)),
                ],
              ),
            ),
            Positioned(
              right: -6,
              bottom: s.h(24),
              child: GestureDetector(
                onTap: _showStreakDialog,
                onTapDown: (_) => setState(() => _isStreakHandlePressed = true),
                onTapUp: (_) => setState(() => _isStreakHandlePressed = false),
                onTapCancel:
                    () => setState(() => _isStreakHandlePressed = false),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 130),
                  curve: Curves.easeOutCubic,
                  scale: _isStreakHandlePressed ? 0.96 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: s.w(14 * streakHandleFactor),
                      vertical: s.h(10 * streakHandleFactor),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(s.r(16 * streakHandleFactor)),
                        bottomLeft: Radius.circular(
                          s.r(16 * streakHandleFactor),
                        ),
                      ),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(
                            _isStreakHandlePressed ? 0.08 : 0.15,
                          ),
                          blurRadius: s.r(_isStreakHandlePressed ? 6 : 10),
                          offset: Offset(
                            0,
                            s.h(_isStreakHandlePressed ? 1 : 3),
                          ),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          size: s.r(16 * streakHandleFactor),
                          color: Colors.grey[700],
                        ),
                        SizedBox(width: s.w(6 * streakHandleFactor)),
                        Text(
                          '${_streakStatus.streakDays}',
                          style: TextStyle(
                            fontSize: s.sp(14 * streakHandleFactor),
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(width: s.w(2 * streakHandleFactor)),
                        Icon(
                          Icons.chevron_left,
                          size: s.r(16 * streakHandleFactor),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -6,
              bottom: s.h(24),
              child: GestureDetector(
                onTap: _showLanguageDialog,
                onTapDown:
                    (_) => setState(() => _isLanguageHandlePressed = true),
                onTapUp:
                    (_) => setState(() => _isLanguageHandlePressed = false),
                onTapCancel:
                    () => setState(() => _isLanguageHandlePressed = false),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 130),
                  curve: Curves.easeOutCubic,
                  scale: _isLanguageHandlePressed ? 0.96 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: s.w(14 * languageHandleFactor),
                      vertical: s.h(10 * languageHandleFactor),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(
                          s.r(16 * languageHandleFactor),
                        ),
                        bottomRight: Radius.circular(
                          s.r(16 * languageHandleFactor),
                        ),
                      ),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(
                            _isLanguageHandlePressed ? 0.08 : 0.15,
                          ),
                          blurRadius: s.r(_isLanguageHandlePressed ? 6 : 10),
                          offset: Offset(
                            0,
                            s.h(_isLanguageHandlePressed ? 1 : 3),
                          ),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.translate,
                          size: s.r(15 * languageHandleFactor),
                          color: Colors.grey[700],
                        ),
                        SizedBox(width: s.w(4 * languageHandleFactor)),
                        Icon(
                          Icons.chevron_right,
                          size: s.r(16 * languageHandleFactor),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLanguageDialog() async {
    final s = AppScale.of(context);
    Locale selectedLocale = context.locale;
    final Locale? changed = await showDialog<Locale>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              final bool hasChanged = selectedLocale != context.locale;
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(s.r(22)),
                ),
                backgroundColor: Colors.white,
                contentPadding: EdgeInsets.fromLTRB(
                  s.w(20),
                  s.h(20),
                  s.w(20),
                  s.h(16),
                ),
                title: Text(
                  'language.select_language'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: s.sp(21),
                    color: Colors.grey[800],
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageTile(
                      title: 'language.polish'.tr(),
                      locale: const Locale('pl'),
                      selectedLocale: selectedLocale,
                      onTap:
                          () => setDialogState(
                            () => selectedLocale = const Locale('pl'),
                          ),
                    ),
                    SizedBox(height: s.h(10)),
                    _buildLanguageTile(
                      title: 'language.english'.tr(),
                      locale: const Locale('en'),
                      selectedLocale: selectedLocale,
                      onTap:
                          () => setDialogState(
                            () => selectedLocale = const Locale('en'),
                          ),
                    ),
                    SizedBox(height: s.h(10)),
                    _buildLanguageTile(
                      title: 'language.spanish'.tr(),
                      locale: const Locale('es'),
                      selectedLocale: selectedLocale,
                      onTap:
                          () => setDialogState(
                            () => selectedLocale = const Locale('es'),
                          ),
                    ),
                    SizedBox(height: s.h(10)),
                    _buildLanguageTile(
                      title: 'language.french'.tr(),
                      locale: const Locale('fr'),
                      selectedLocale: selectedLocale,
                      onTap:
                          () => setDialogState(
                            () => selectedLocale = const Locale('fr'),
                          ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(
                      'buttons.cancel'.tr(),
                      style: TextStyle(
                        fontSize: s.sp(14),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        hasChanged
                            ? () =>
                                Navigator.of(dialogContext).pop(selectedLocale)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB2E0D8),
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(s.r(14)),
                      ),
                      elevation: hasChanged ? 3 : 0,
                    ),
                    child: Text(
                      'language.apply'.tr(),
                      style: TextStyle(
                        fontSize: s.sp(14),
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    );

    if (changed != null && mounted) {
      await context.setLocale(changed);
      setState(() {});
    }
  }

  Future<void> _loadStreakStatus() async {
    final status = await DailyStreakService.instance.getStatus();
    if (!mounted) return;
    setState(() => _streakStatus = status);
  }

  Future<void> _openGameSettings() async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const GameSettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(animation);
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
    if (!mounted) return;
    await _loadStreakStatus();
  }

  Future<void> _showStreakDialog() async {
    await _loadStreakStatus();
    if (!mounted) return;

    final s = AppScale.of(context);
    final bool answeredToday = _streakStatus.hasAnsweredToday;
    final String statusKey =
        answeredToday
            ? 'streak.status_completed_today'
            : 'streak.status_ready_today';

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(s.r(22)),
            ),
            backgroundColor: Colors.white,
            contentPadding: EdgeInsets.fromLTRB(
              s.w(20),
              s.h(20),
              s.w(20),
              s.h(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  color: const Color(0xFF7FC4B3),
                  size: s.r(22),
                ),
                SizedBox(width: s.w(8)),
                Text(
                  'streak.title'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: s.sp(21),
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: s.h(14),
                    horizontal: s.w(14),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB2E0D8).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(s.r(14)),
                    border: Border.all(color: const Color(0xFF9FD4C7)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_streakStatus.streakDays}',
                        style: TextStyle(
                          fontSize: s.sp(32),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'streak.days_label'.tr(),
                        style: TextStyle(
                          fontSize: s.sp(13),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: s.h(12)),
                Text(
                  statusKey.tr(),
                  style: TextStyle(
                    fontSize: s.sp(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: s.h(6)),
                Text(
                  'streak.description'.tr(),
                  style: TextStyle(
                    fontSize: s.sp(13),
                    height: 1.35,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'streak.close'.tr(),
                  style: TextStyle(
                    fontSize: s.sp(14),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!answeredToday)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await _openGameSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2E0D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(s.r(14)),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'streak.answer_today'.tr(),
                    style: TextStyle(
                      fontSize: s.sp(14),
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildLanguageTile({
    required String title,
    required Locale locale,
    required Locale selectedLocale,
    required VoidCallback onTap,
  }) {
    final s = AppScale.of(context);
    final bool isSelected = locale == selectedLocale;
    return InkWell(
      borderRadius: BorderRadius.circular(s.r(14)),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: s.w(14), vertical: s.h(12)),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFFB2E0D8).withOpacity(0.28)
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(s.r(14)),
          border: Border.all(
            color: isSelected ? const Color(0xFF9FD4C7) : Colors.grey[300]!,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.language,
              size: s.r(18),
              color: isSelected ? Colors.grey[800] : Colors.grey[600],
            ),
            SizedBox(width: s.w(10)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: s.sp(15),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: s.r(20),
              color: isSelected ? const Color(0xFF7FC4B3) : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}
