import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';

import '../data/questions_data.dart';
import 'game_settings_screen.dart';
import '../models/daily_streak_status.dart';
import '../services/daily_streak_service.dart';
import '../services/reminder_notification_service.dart';
import '../utils/app_scale.dart';

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
  bool _isStartButtonPressed = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleReminderIfEnabled();
      _maybeAskForReminderOnFirstLaunch();
    });
  }

  /// Po restarcie urządzenia harmonogram znika – przy każdym starcie aplikacji
  /// ponownie rejestrujemy alarm, jeśli użytkownik ma włączone przypomnienie.
  Future<void> _rescheduleReminderIfEnabled() async {
    if (!mounted) return;
    final enabled =
        await ReminderNotificationService.instance.isReminderEnabled();
    if (!enabled || !mounted) return;
    await ReminderNotificationService.instance.enableDailyReminder(
      hour: 20,
      minute: 0,
      title: 'notifications.daily_reminder_title'.tr(),
      body: 'notifications.daily_reminder_body'.tr(),
    );
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
    final streakHandleFactor = languageHandleFactor;
    final handleWidth = s.w(68 * languageHandleFactor);

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
                      onTapDown: (_) => _setStartButtonPressed(true),
                      onTapCancel: () => _setStartButtonPressed(false),
                      onTap: () {
                        _setStartButtonPressed(true);
                        _openGameSettings();
                        Future.delayed(const Duration(milliseconds: 120), () {
                          if (!mounted) return;
                          _setStartButtonPressed(false);
                        });
                      },
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOutCubic,
                        scale: _isStartButtonPressed ? 0.97 : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOutCubic,
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
                                color: const Color(
                                  0xFFB2E0D8,
                                ).withOpacity(_isStartButtonPressed ? 0.45 : 0.6),
                                blurRadius: s.r(_isStartButtonPressed ? 22 : 30),
                                spreadRadius: s.r(_isStartButtonPressed ? 3 : 5),
                                offset: Offset(
                                  0,
                                  s.h(_isStartButtonPressed ? 5 : 8),
                                ),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFFB2E0D8,
                                ).withOpacity(_isStartButtonPressed ? 0.2 : 0.3),
                                blurRadius: s.r(_isStartButtonPressed ? 36 : 50),
                                spreadRadius: s.r(_isStartButtonPressed ? 6 : 10),
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
                  ),

                  const Spacer(flex: 2),

                  SizedBox(height: s.h(30)),
                ],
              ),
            ),
            Positioned(
              left: -6,
              bottom: s.h(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
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
                        constraints: BoxConstraints.tightFor(width: handleWidth),
                        padding: EdgeInsets.symmetric(
                          horizontal: s.w(14 * streakHandleFactor),
                          vertical: s.h(10 * streakHandleFactor),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(s.r(16 * streakHandleFactor)),
                            bottomRight: Radius.circular(
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department_outlined,
                              size: s.r(15 * streakHandleFactor),
                              color: Colors.grey[700],
                            ),
                            SizedBox(width: s.w(4 * streakHandleFactor)),
                            Text(
                              '${_streakStatus.streakDays}',
                              style: TextStyle(
                                fontSize: s.sp(13 * streakHandleFactor),
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: s.h(14)),
                  GestureDetector(
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
                        constraints: BoxConstraints.tightFor(width: handleWidth),
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
                              color: Colors.grey[700],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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
    bool isCancelPressed = false;
    bool isApplyPressed = false;
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
                  ],
                ),
                actions: [
                  Listener(
                    onPointerDown: (_) => setDialogState(() => isCancelPressed = true),
                    onPointerCancel:
                        (_) => setDialogState(() => isCancelPressed = false),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 110),
                      curve: Curves.easeOutCubic,
                      scale: isCancelPressed ? 0.97 : 1.0,
                      child: TextButton(
                        onPressed: () async {
                          setDialogState(() => isCancelPressed = true);
                          await Future.delayed(const Duration(milliseconds: 110));
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(
                          'buttons.cancel'.tr(),
                          style: TextStyle(
                            fontSize: s.sp(14),
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Listener(
                    onPointerDown: (_) => setDialogState(() => isApplyPressed = true),
                    onPointerCancel:
                        (_) => setDialogState(() => isApplyPressed = false),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 110),
                      curve: Curves.easeOutCubic,
                      scale: isApplyPressed ? 0.97 : 1.0,
                      child: ElevatedButton(
                        onPressed:
                            hasChanged
                                ? () async {
                                  setDialogState(() => isApplyPressed = true);
                                  await Future.delayed(
                                    const Duration(milliseconds: 110),
                                  );
                                  if (!dialogContext.mounted) return;
                                  Navigator.of(dialogContext).pop(selectedLocale);
                                }
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
                    ),
                  ),
                ],
              );
            },
          ),
    );

    if (changed != null && mounted) {
      await context.setLocale(changed);
      if (!mounted) return;
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

  void _setStartButtonPressed(bool isPressed) {
    if (_isStartButtonPressed == isPressed || !mounted) return;
    setState(() => _isStartButtonPressed = isPressed);
  }

  Future<void> _maybeAskForReminderOnFirstLaunch() async {
    final shouldAsk =
        await ReminderNotificationService.instance.shouldAskForInitialPrompt();
    if (!mounted || !shouldAsk) return;

    final s = AppScale.of(context);
    final bool? enable = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(s.r(22)),
            ),
            title: Text(
              'notifications.prompt_title'.tr(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: s.sp(20),
                color: Colors.grey[800],
              ),
            ),
            content: Text(
              'notifications.prompt_description'.tr(args: ['20:00']),
              style: TextStyle(
                fontSize: s.sp(14),
                height: 1.35,
                color: Colors.grey[700],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'notifications.prompt_not_now'.tr(),
                  style: TextStyle(
                    fontSize: s.sp(14),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB2E0D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(s.r(14)),
                  ),
                ),
                child: Text(
                  'notifications.prompt_enable'.tr(),
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

    await ReminderNotificationService.instance.markInitialPromptShown();
    if (!mounted || enable != true) return;
    final enabled = await _enableDailyReminder();
    if (!enabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('notifications.enable_in_settings_hint'.tr()),
          action: SnackBarAction(
            label: 'notifications.open_settings'.tr(),
            onPressed: () {
              AppSettings.openAppSettings(
                type: AppSettingsType.notification,
              );
            },
          ),
        ),
      );
    }
  }

  Future<bool> _enableDailyReminder() {
    return ReminderNotificationService.instance.enableDailyReminder(
      hour: 20,
      minute: 0,
      title: 'notifications.daily_reminder_title'.tr(),
      body: 'notifications.daily_reminder_body'.tr(),
    );
  }

  Future<void> _showStreakDialog() async {
    await _loadStreakStatus();
    if (!mounted) return;

    final s = AppScale.of(context);
    bool dialogAnsweredToday = _streakStatus.hasAnsweredToday;
    String statusKey =
        dialogAnsweredToday
            ? 'streak.status_completed_today'
            : _streakStatus.streakDays == 0
            ? 'streak.status_start_today'
            : 'streak.status_ready_today';
    String resolveStreakDaysLabelKey() {
      return _streakStatus.streakDays == 1
          ? 'streak.day_label_singular'
          : 'streak.days_label';
    }
    String? dailyQuestionText = await DailyStreakService.instance
        .getShownDailyQuestionTextForToday(
          localeCode: context.locale.languageCode,
        );
    if (dailyQuestionText != null && !dialogAnsweredToday) {
      final updatedStatus = await DailyStreakService.instance.registerDailyAnswer();
      if (!mounted) return;
      setState(() => _streakStatus = updatedStatus);
      dialogAnsweredToday = updatedStatus.hasAnsweredToday;
      statusKey = 'streak.status_completed_today';
    }
    if (dailyQuestionText == null && dialogAnsweredToday) {
      final localizedQuestion = await _loadDailyQuestionOfTheDay();
      if (!mounted) return;
      if (localizedQuestion != null) {
        dailyQuestionText = localizedQuestion;
        await DailyStreakService.instance.saveShownDailyQuestionForToday(
          localizedQuestion,
          localeCode: context.locale.languageCode,
        );
      }
    }
    bool reminderEnabled =
        await ReminderNotificationService.instance.isReminderEnabled();
    bool hasCopyableDailyQuestion = dailyQuestionText != null;
    bool isReminderActionLoading = false;
    bool isLoadingDailyQuestion = false;
    bool isReminderButtonPressed = false;
    bool isShowDailyQuestionPressed = false;
    bool isCopyDailyQuestionPressed = false;
    bool isClosePressed = false;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
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
                              resolveStreakDaysLabelKey().tr(),
                              style: TextStyle(
                                fontSize: s.sp(13),
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: s.h(14)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: s.w(12)),
                        child: Text(
                          statusKey.tr(),
                          style: TextStyle(
                            fontSize: s.sp(14),
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      SizedBox(height: s.h(6)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: s.w(12)),
                        child: Text(
                          'streak.description'.tr(),
                          style: TextStyle(
                            fontSize: s.sp(13),
                            height: 1.35,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      SizedBox(height: s.h(12)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child:
                            dailyQuestionText == null
                                ? SizedBox(
                                  key: const ValueKey('show_daily_question_btn'),
                                  width: double.infinity,
                                  child: Listener(
                                    onPointerDown:
                                        (_) => setDialogState(
                                          () => isShowDailyQuestionPressed = true,
                                        ),
                                    onPointerUp:
                                        (_) => setDialogState(
                                          () => isShowDailyQuestionPressed = false,
                                        ),
                                    onPointerCancel:
                                        (_) => setDialogState(
                                          () => isShowDailyQuestionPressed = false,
                                        ),
                                    child: AnimatedScale(
                                      duration: const Duration(milliseconds: 110),
                                      curve: Curves.easeOutCubic,
                                      scale:
                                          isShowDailyQuestionPressed ? 0.97 : 1.0,
                                      child: OutlinedButton(
                                    onPressed:
                                        isLoadingDailyQuestion
                                            ? null
                                            : () async {
                                              if (!context.mounted) return;
                                              setDialogState(
                                                () => isLoadingDailyQuestion = true,
                                              );
                                              final questionText =
                                                  await _loadDailyQuestionOfTheDay();
                                              if (!mounted || !context.mounted) {
                                                return;
                                              }
                                              if (questionText != null &&
                                                  !dialogAnsweredToday) {
                                                final updatedStatus =
                                                    await DailyStreakService.instance
                                                        .registerDailyAnswer();
                                                if (!mounted ||
                                                    !context.mounted) {
                                                  return;
                                                }
                                                setState(
                                                  () => _streakStatus = updatedStatus,
                                                );
                                                dialogAnsweredToday =
                                                    updatedStatus.hasAnsweredToday;
                                                statusKey =
                                                    'streak.status_completed_today';
                                              }
                                              if (questionText != null) {
                                                await DailyStreakService.instance
                                                    .saveShownDailyQuestionForToday(
                                                      questionText,
                                                      localeCode:
                                                          context
                                                              .locale
                                                              .languageCode,
                                                    );
                                              }
                                              if (!context.mounted) return;
                                              setDialogState(() {
                                                isLoadingDailyQuestion = false;
                                                hasCopyableDailyQuestion =
                                                    questionText != null;
                                                dailyQuestionText =
                                                    questionText ??
                                                    'streak.daily_question_unavailable'
                                                        .tr();
                                              });
                                            },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFFB2E0D8,
                                      ).withOpacity(0.2),
                                      side: const BorderSide(
                                        color: Color(0xFFB8DFD5),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          s.r(12),
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: s.h(12),
                                      ),
                                    ),
                                    child:
                                        isLoadingDailyQuestion
                                            ? SizedBox(
                                              width: s.r(16),
                                              height: s.r(16),
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Color(0xFF7FC4B3),
                                              ),
                                            )
                                            : Text(
                                              'streak.show_daily_question'.tr(),
                                              style: TextStyle(
                                                fontSize: s.sp(14),
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey[800],
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                )
                                : Container(
                                  key: const ValueKey('daily_question_card'),
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: s.w(14),
                                    vertical: s.h(13),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFB2E0D8,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(s.r(12)),
                                    border: Border.all(
                                      color: const Color(0xFFB8DFD5),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: s.r(10),
                                        offset: Offset(0, s.h(2)),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'streak.daily_question_title'.tr(),
                                              style: TextStyle(
                                                fontSize: s.sp(12.5),
                                                fontWeight: FontWeight.w700,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          if (hasCopyableDailyQuestion)
                                            Listener(
                                              onPointerDown:
                                                  (_) => setDialogState(
                                                    () => isCopyDailyQuestionPressed = true,
                                                  ),
                                              onPointerUp:
                                                  (_) => setDialogState(
                                                    () => isCopyDailyQuestionPressed = false,
                                                  ),
                                              onPointerCancel:
                                                  (_) => setDialogState(
                                                    () => isCopyDailyQuestionPressed = false,
                                                  ),
                                              child: AnimatedScale(
                                                duration: const Duration(milliseconds: 110),
                                                curve: Curves.easeOutCubic,
                                                scale:
                                                    isCopyDailyQuestionPressed
                                                        ? 0.94
                                                        : 1.0,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        s.r(10),
                                                      ),
                                                  onTap: () async {
                                                    final text = dailyQuestionText;
                                                    if (text == null) return;
                                                    await Clipboard.setData(
                                                      ClipboardData(text: text),
                                                    );
                                                  },
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                      s.r(6),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.35),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            s.r(10),
                                                          ),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFB8DFD5,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.content_copy_rounded,
                                                      size: s.r(15),
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: s.h(6)),
                                      Text(
                                        dailyQuestionText!,
                                        style: TextStyle(
                                          fontSize: s.sp(15),
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: s.h(8)),
                                      Text(
                                        'streak.daily_question_hint'.tr(),
                                        style: TextStyle(
                                          fontSize: s.sp(12.5),
                                          height: 1.35,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                      SizedBox(height: s.h(12)),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: s.w(12),
                          vertical: s.h(10),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(s.r(12)),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                reminderEnabled
                                    ? 'notifications.reminder_enabled_at'.tr(
                                      args: ['20:00'],
                                    )
                                    : 'notifications.reminder_disabled'.tr(),
                                style: TextStyle(
                                  fontSize: s.sp(12.5),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            SizedBox(width: s.w(8)),
                            Listener(
                              onPointerDown:
                                  (_) => setDialogState(
                                    () => isReminderButtonPressed = true,
                                  ),
                              onPointerUp:
                                  (_) => setDialogState(
                                    () => isReminderButtonPressed = false,
                                  ),
                              onPointerCancel:
                                  (_) => setDialogState(
                                    () => isReminderButtonPressed = false,
                                  ),
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 110),
                                curve: Curves.easeOutCubic,
                                scale: isReminderButtonPressed ? 0.97 : 1.0,
                                child: OutlinedButton(
                                  onPressed:
                                      isReminderActionLoading
                                          ? null
                                          : () async {
                                            final ctx = context;
                                            setDialogState(
                                              () => isReminderActionLoading = true,
                                            );
                                            var enableAttemptFailed = false;
                                            try {
                                              if (reminderEnabled) {
                                                await ReminderNotificationService
                                                    .instance
                                                    .disableDailyReminder();
                                              } else {
                                                final enabled =
                                                    await _enableDailyReminder();
                                                if (!enabled) {
                                                  enableAttemptFailed = true;
                                                }
                                              }
                                              reminderEnabled =
                                                  await ReminderNotificationService
                                                      .instance
                                                      .isReminderEnabled();
                                            } finally {
                                              if (!ctx.mounted) return;
                                              setDialogState(() {
                                                isReminderActionLoading = false;
                                                isReminderButtonPressed = false;
                                              });
                                            }
                                            if (enableAttemptFailed &&
                                                ctx.mounted) {
                                              ScaffoldMessenger.of(ctx)
                                                  .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'notifications.enable_in_settings_hint'.tr(),
                                                      ),
                                                      action: SnackBarAction(
                                                        label: 'notifications.open_settings'.tr(),
                                                        onPressed: () {
                                                          AppSettings.openAppSettings(
                                                            type: AppSettingsType.notification,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  );
                                            }
                                          },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        s.r(10),
                                      ),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: s.w(12),
                                      vertical: s.h(8),
                                    ),
                                  ),
                                  child:
                                      isReminderActionLoading
                                          ? SizedBox(
                                            width: s.r(14),
                                            height: s.r(14),
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Text(
                                            reminderEnabled
                                                ? 'notifications.turn_off'.tr()
                                                : 'notifications.turn_on'.tr(),
                                            style: TextStyle(
                                              fontSize: s.sp(12),
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Listener(
                      onPointerDown:
                          (_) => setDialogState(() => isClosePressed = true),
                      onPointerCancel:
                          (_) => setDialogState(() => isClosePressed = false),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 110),
                        curve: Curves.easeOutCubic,
                        scale: isClosePressed ? 0.97 : 1.0,
                        child: TextButton(
                          onPressed: () async {
                            setDialogState(() => isClosePressed = true);
                            await Future.delayed(
                              const Duration(milliseconds: 110),
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                          },
                          child: Text(
                            'streak.close'.tr(),
                            style: TextStyle(
                              fontSize: s.sp(14),
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
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

  Future<String?> _loadDailyQuestionOfTheDay() async {
    final question = await QuestionsData.getDailyQuestionForDate(
      localeCode: context.locale.languageCode,
    );
    if (question == null) {
      return null;
    }

    return question.text;
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
