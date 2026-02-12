import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import '../models/question.dart';
import '../models/round_result.dart';
import '../data/questions_data.dart';
import 'category_selection_screen.dart';
import 'session_summary_screen.dart';
import '../utils/app_scale.dart';

class QuestionWithCategory {
  final Question question;
  final String categoryName;
  final CategoryData categoryData;

  QuestionWithCategory(this.question, this.categoryName, this.categoryData);
}

enum TimeUpAction {
  needMoreTime,
  nextQuestion,
}

class GameScreen extends StatefulWidget {
  final List<String> categories;
  final Map<String, CategoryData> categoriesData;
  final int numberOfPlayers;
  final int discussionTime;

  const GameScreen({
    super.key,
    required this.categories,
    required this.categoriesData,
    required this.numberOfPlayers,
    required this.discussionTime,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late QuestionWithCategory currentQuestionWithCategory;
  List<QuestionWithCategory> allQuestions = [];
  bool _isLoadingQuestions = true;
  bool _didStartInit = false;
  final List<RoundResult> sessionRounds = [];
  int votesOption1 = 0;
  int votesOption2 = 0;
  bool votingComplete = false;
  bool timerStarted = false;
  int remainingSeconds = 0;
  Timer? timer;
  bool _isTimeUpDialogOpen = false;
  bool _isInExtraTime = false;
  int? _currentRoundResultIndex;
  int _currentRoundExtensions = 0;
  DateTime? _discussionStartedAt;
  
  late AnimationController _resultsAnimationController;
  late AnimationController _timerAnimationController;
  late AnimationController _questionAnimationController;
  late AnimationController _buttonsAnimationController;
  late AnimationController _tickAnimationController;
  late Animation<double> _resultsOpacityAnimation;
  late Animation<Offset> _timerSlideAnimation;
  late Animation<double> _timerOpacityAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late Animation<double> _questionOpacityAnimation;
  late Animation<double> _buttonsOpacityAnimation;
  late Animation<double> _tickScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation for results (fade in)
    _resultsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _resultsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _resultsAnimationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Animation for timer (slide up + fade in)
    _timerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _timerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _timerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _timerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _timerAnimationController,
        curve: Curves.easeIn,
      ),
    );
    
    // Animation for question transition (slide + fade)
    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _questionAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _questionOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _questionAnimationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Animation for buttons (fade)
    _buttonsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _buttonsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonsAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // Subtle ticking pulse for the last 10 seconds.
    _tickAnimationController = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    );
    _tickScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _tickAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartInit) return;
    _didStartInit = true;
    _initializeQuestions();
  }

  Future<void> _initializeQuestions() async {
    try {
      await _prepareQuestions();

      if (!mounted) return;
      if (allQuestions.isNotEmpty) {
        _loadRandomQuestion();
      } else {
        _setFallbackQuestion();
      }
    } catch (_) {
      if (!mounted) return;
      _setFallbackQuestion();
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingQuestions = false;
        remainingSeconds = widget.discussionTime * 60;
      });
      _questionAnimationController.forward();
      _buttonsAnimationController.forward();
    }
  }

  Future<void> _prepareQuestions() async {
    final localeCode = context.locale.languageCode;
    allQuestions = [];
    for (String categoryName in widget.categories) {
      final questions = await QuestionsData.getQuestionsByCategory(
        categoryName: categoryName,
        localeCode: localeCode,
      );
      final categoryData = widget.categoriesData[categoryName]!;
      for (Question question in questions) {
        allQuestions.add(QuestionWithCategory(question, categoryName, categoryData));
      }
    }
  }

  void _setFallbackQuestion() {
    final fallbackCategoryName =
        widget.categories.isNotEmpty ? widget.categories.first : 'chill';
    final fallbackCategoryData = widget.categoriesData[fallbackCategoryName] ??
        CategoryData('💭', const Color(0xFFB8D4FF));
    currentQuestionWithCategory = QuestionWithCategory(
      Question(
        text: 'No questions available',
        option1: '1',
        option2: '2',
      ),
      fallbackCategoryName,
      fallbackCategoryData,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _resultsAnimationController.dispose();
    _timerAnimationController.dispose();
    _questionAnimationController.dispose();
    _buttonsAnimationController.dispose();
    _tickAnimationController.dispose();
    super.dispose();
  }

  void _loadRandomQuestion() {
    final random = Random();
    if (allQuestions.isEmpty) return;
    
    // Animate old question out, then load new question
    if (votingComplete) {
      // Fade out buttons and question
      _buttonsAnimationController.reverse();
      _questionAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            currentQuestionWithCategory = allQuestions[random.nextInt(allQuestions.length)];
            votesOption1 = 0;
            votesOption2 = 0;
            votingComplete = false;
            timerStarted = false;
            remainingSeconds = widget.discussionTime * 60;
            _isInExtraTime = false;
            _currentRoundResultIndex = null;
            _currentRoundExtensions = 0;
            _discussionStartedAt = null;
          });
          timer?.cancel();
          _resultsAnimationController.reset();
          _timerAnimationController.reset();
          _syncTickAnimationState();
          // Fade in buttons and question
          _questionAnimationController.forward();
          _buttonsAnimationController.forward();
        }
      });
    } else {
      setState(() {
        currentQuestionWithCategory = allQuestions[random.nextInt(allQuestions.length)];
        votesOption1 = 0;
        votesOption2 = 0;
        votingComplete = false;
        timerStarted = false;
        remainingSeconds = widget.discussionTime * 60;
        _isInExtraTime = false;
        _currentRoundResultIndex = null;
        _currentRoundExtensions = 0;
        _discussionStartedAt = null;
      });
      timer?.cancel();
      _resultsAnimationController.reset();
      _timerAnimationController.reset();
      _syncTickAnimationState();
    }
  }

  void _vote(int option) {
    if (votingComplete) return;

    setState(() {
      if (option == 1) {
        votesOption1++;
      } else {
        votesOption2++;
      }

      if (votesOption1 + votesOption2 == widget.numberOfPlayers) {
        votingComplete = true;
        final total = votesOption1 + votesOption2;
        final majority = votesOption1 >= votesOption2 ? votesOption1 : votesOption2;
        sessionRounds.add(RoundResult(
          categoryName: currentQuestionWithCategory.categoryName,
          questionText: currentQuestionWithCategory.question.text,
          totalVotes: total,
          majorityVotes: majority,
          extensionsCount: 0,
          discussionDurationSeconds: 0,
        ));
        _currentRoundResultIndex = sessionRounds.length - 1;
        _currentRoundExtensions = 0;
        _isInExtraTime = false;
        _discussionStartedAt = DateTime.now();
        
        // Start animations with delays
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _resultsAnimationController.forward();
          }
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _timerAnimationController.forward();
          }
        });
        
        _startTimer();
      }
    });
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 1) {
          remainingSeconds--;
        } else if (remainingSeconds == 1) {
          remainingSeconds = 0;
          timer.cancel();
          _onDiscussionTimeEnded();
        } else {
          timer.cancel();
        }
        _syncTickAnimationState();
      });
    });
  }

  Future<void> _onDiscussionTimeEnded() async {
    if (!mounted || _isTimeUpDialogOpen) return;
    _isTimeUpDialogOpen = true;
    final action = await _showContinueDiscussionDialog();
    _isTimeUpDialogOpen = false;

    if (!mounted) return;
    if (action == TimeUpAction.nextQuestion) {
      _goToNextQuestion();
      return;
    }

    setState(() {
      _isInExtraTime = true;
      _currentRoundExtensions++;
      final index = _currentRoundResultIndex;
      if (index != null && index >= 0 && index < sessionRounds.length) {
        sessionRounds[index] = sessionRounds[index].copyWith(
          extensionsCount: _currentRoundExtensions,
        );
      }
      _syncTickAnimationState();
    });
  }

  void _goToNextQuestion() {
    _finalizeCurrentRoundDuration();
    _loadRandomQuestion();
  }

  void _finalizeCurrentRoundDuration() {
    final index = _currentRoundResultIndex;
    final startedAt = _discussionStartedAt;
    if (index == null || startedAt == null) return;
    if (index < 0 || index >= sessionRounds.length) return;

    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    sessionRounds[index] = sessionRounds[index].copyWith(
      discussionDurationSeconds: elapsed < 0 ? 0 : elapsed,
    );
    _discussionStartedAt = null;
  }

  Future<TimeUpAction> _showContinueDiscussionDialog() async {
    final s = AppScale.of(context);
    final result = await showGeneralDialog<TimeUpAction>(
          context: context,
          barrierDismissible: false,
          barrierLabel: 'continueDiscussionDialog',
          barrierColor: Colors.black.withOpacity(0.25),
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, __, ___) {
            return Center(
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: s.w(392)),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: s.w(18)),
                    padding: EdgeInsets.fromLTRB(
                      s.w(22),
                      s.h(20),
                      s.w(22),
                      s.h(16),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(s.r(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: s.r(20),
                          offset: Offset(0, s.h(6)),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'game.extend_title'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: s.sp(22),
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: s.h(10)),
                        Text(
                          'game.extend_message'.tr(),
                          style: TextStyle(
                            fontSize: s.sp(16),
                            color: Colors.grey[600],
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: s.h(18)),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(
                                  TimeUpAction.nextQuestion,
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: s.h(12)),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'buttons.next_short'.tr(),
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: s.sp(15),
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: s.w(8)),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(
                                  TimeUpAction.needMoreTime,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB2E0D8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(s.r(12)),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: s.w(12),
                                    vertical: s.h(12),
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'buttons.need_more_time'.tr(),
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: s.sp(15),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
                child: child,
              ),
            );
          },
        );

    return result ?? TimeUpAction.nextQuestion;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool get _shouldShowTickPulse =>
      votingComplete &&
      !_isInExtraTime &&
      remainingSeconds > 0 &&
      remainingSeconds <= 10;

  void _syncTickAnimationState() {
    if (_shouldShowTickPulse) {
      if (!_tickAnimationController.isAnimating) {
        _tickAnimationController.repeat(reverse: true);
      }
      return;
    }
    if (_tickAnimationController.isAnimating) {
      _tickAnimationController.stop();
    }
    if (_tickAnimationController.value != 0) {
      _tickAnimationController.value = 0;
    }
  }

  double _getPercentage(int votes) {
    final total = votesOption1 + votesOption2;
    if (total == 0) return 0;
    return (votes / total) * 100;
  }

  Color _lightenColor(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Color _darkenColor(Color color, [double amount = 0.15]) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  Future<bool> _showExitDialog() async {
    final s = AppScale.of(context);
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(s.r(20)),
        ),
        title: Text(
          'game.exit_title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: s.sp(22),
            color: Colors.grey[800],
          ),
        ),
        content: Text(
          'game.exit_message'.tr(),
          style: TextStyle(
            fontSize: s.sp(16),
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'buttons.cancel'.tr(),
              style: TextStyle(
                fontSize: s.sp(16),
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB2E0D8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(s.r(12)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: s.w(24),
                vertical: s.h(12),
              ),
            ),
            child: Text(
              'buttons.exit'.tr(),
              style: TextStyle(
                fontSize: s.sp(16),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _openSessionSummary() {
    _finalizeCurrentRoundDuration();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SessionSummaryScreen(
          roundResults: sessionRounds,
          categories: widget.categories,
          categoriesData: widget.categoriesData,
          numberOfPlayers: widget.numberOfPlayers,
          discussionTime: widget.discussionTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenHeight < 760;
    final useScrollFallback = screenHeight < 700;
    final questionFontSize = isCompact ? s.sp(24) : s.sp(28);
    final sectionGap = isCompact ? s.h(18) : s.h(30);
    final timerFontSize = isCompact ? s.sp(40) : s.sp(48);
    final nextButtonVerticalPadding = isCompact ? s.h(12) : s.h(16);
    _syncTickAnimationState();

    if (_isLoadingQuestions) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFB2E0D8),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog().then((shouldExit) {
          if (shouldExit && mounted) _openSessionSummary();
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentQuestionWithCategory.categoryData.color.withOpacity(0.3),
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(s.r(24)),
            child: useScrollFallback
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              onPressed: () async {
                                final shouldExit = await _showExitDialog();
                                if (shouldExit && mounted) {
                                  _openSessionSummary();
                                }
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.grey[700],
                                size: s.r(24),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),

                        SizedBox(height: isCompact ? s.h(24) : s.h(40)),

                        // Question with animation
                        SizedBox(
                          height: s.h(165),
                          child: Center(
                            child: FadeTransition(
                              opacity: _questionOpacityAnimation,
                              child: SlideTransition(
                                position: _questionSlideAnimation,
                                child: Text(
                                  currentQuestionWithCategory.question.text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: questionFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? s.h(24) : s.h(40)),

                        // Voting buttons with animation
                        FadeTransition(
                          opacity: _buttonsOpacityAnimation,
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildVotingButton(
                                  '1',
                                  1,
                                  votesOption1,
                                  _lightenColor(
                                    currentQuestionWithCategory.categoryData.color,
                                    0.1,
                                  ),
                                  isCompact,
                                ),
                              ),
                              SizedBox(width: s.w(20)),
                              Expanded(
                                child: _buildVotingButton(
                                  '2',
                                  2,
                                  votesOption2,
                                  _darkenColor(
                                    currentQuestionWithCategory.categoryData.color,
                                    0.1,
                                  ),
                                  isCompact,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isCompact ? s.h(12) : s.h(20)),

                        // Vote counter
                        Text(
                          'game.votes'.tr(args: [
                            '${votesOption1 + votesOption2}',
                            '${widget.numberOfPlayers}',
                          ]),
                          style: TextStyle(
                            fontSize: s.sp(16),
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: sectionGap),

                        // Timer (pokazuje się po zakończeniu głosowania)
                        if (votingComplete) ...[
                          FadeTransition(
                            opacity: _timerOpacityAnimation,
                            child: SlideTransition(
                              position: _timerSlideAnimation,
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(isCompact ? s.r(16) : s.r(20)),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(s.r(20)),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          _isInExtraTime
                                              ? 'game.extra_time'.tr()
                                              : remainingSeconds > 0
                                                  ? 'game.discussion_time'.tr()
                                                  : 'game.time_up'.tr(),
                                          style: TextStyle(
                                            fontSize: s.sp(16),
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: isCompact ? s.h(6) : s.h(8)),
                                        ScaleTransition(
                                          scale: _shouldShowTickPulse
                                              ? _tickScaleAnimation
                                              : const AlwaysStoppedAnimation(1.0),
                                          child: Text(
                                            _isInExtraTime ? '∞' : _formatTime(remainingSeconds),
                                            style: TextStyle(
                                              fontSize: timerFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? s.h(14) : s.h(20)),
                                  ElevatedButton(
                                    onPressed: _goToNextQuestion,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          currentQuestionWithCategory.categoryData.color,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: s.w(40),
                                        vertical: nextButtonVerticalPadding,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(s.r(30)),
                                      ),
                                    ),
                                    child: Text(
                                      'buttons.next'.tr(),
                                      style: TextStyle(
                                        fontSize: s.sp(18),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: isCompact ? s.h(12) : s.h(20)),
                      ],
                    ),
                  )
                : Column(
              children: [
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final shouldExit = await _showExitDialog();
                        if (shouldExit && mounted) {
                          _openSessionSummary();
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.grey[700],
                        size: s.r(24),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),

                SizedBox(height: isCompact ? s.h(24) : s.h(40)),

              // Question with animation
              Expanded(
                child: Center(
                  child: FadeTransition(
                    opacity: _questionOpacityAnimation,
                    child: SlideTransition(
                      position: _questionSlideAnimation,
                      child: Text(
                        currentQuestionWithCategory.question.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: questionFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: isCompact ? s.h(24) : s.h(40)),

              // Voting buttons with animation
              FadeTransition(
                opacity: _buttonsOpacityAnimation,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildVotingButton(
                        '1',
                        1,
                        votesOption1,
                        _lightenColor(currentQuestionWithCategory.categoryData.color, 0.1),
                        isCompact,
                      ),
                    ),
                    SizedBox(width: s.w(20)),
                    Expanded(
                      child: _buildVotingButton(
                        '2',
                        2,
                        votesOption2,
                        _darkenColor(currentQuestionWithCategory.categoryData.color, 0.1),
                        isCompact,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isCompact ? s.h(12) : s.h(20)),

              // Vote counter
              Text(
                'game.votes'.tr(args: [
                  '${votesOption1 + votesOption2}',
                  '${widget.numberOfPlayers}',
                ]),
                style: TextStyle(
                  fontSize: s.sp(16),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: sectionGap),

              // Timer (pokazuje się po zakończeniu głosowania)
              if (votingComplete) ...[
                FadeTransition(
                  opacity: _timerOpacityAnimation,
                  child: SlideTransition(
                    position: _timerSlideAnimation,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isCompact ? s.r(16) : s.r(20)),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(s.r(20)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _isInExtraTime
                                    ? 'game.extra_time'.tr()
                                    : remainingSeconds > 0
                                        ? 'game.discussion_time'.tr()
                                        : 'game.time_up'.tr(),
                                style: TextStyle(
                                  fontSize: s.sp(16),
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: isCompact ? s.h(6) : s.h(8)),
                              ScaleTransition(
                                scale: _shouldShowTickPulse
                                    ? _tickScaleAnimation
                                    : const AlwaysStoppedAnimation(1.0),
                                child: Text(
                                  _isInExtraTime ? '∞' : _formatTime(remainingSeconds),
                                  style: TextStyle(
                                    fontSize: timerFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isCompact ? s.h(14) : s.h(20)),
                        ElevatedButton(
                          onPressed: _goToNextQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentQuestionWithCategory.categoryData.color,
                            padding: EdgeInsets.symmetric(
                              horizontal: s.w(40),
                              vertical: nextButtonVerticalPadding,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s.r(30)),
                            ),
                          ),
                          child: Text(
                            'buttons.next'.tr(),
                            style: TextStyle(
                              fontSize: s.sp(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: isCompact ? s.h(12) : s.h(20)),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildVotingButton(
    String label,
    int option,
    int votes,
    Color color,
    bool isCompact,
  ) {
    final s = AppScale.of(context);
    final percentage = _getPercentage(votes);
    final isVotingComplete = votingComplete;

    return GestureDetector(
      onTap: () => _vote(option),
      child: Container(
        height: isCompact ? s.h(122) : s.h(140),
        decoration: BoxDecoration(
          color: isVotingComplete ? color.withOpacity(0.6) : color,
          borderRadius: BorderRadius.circular(s.r(20)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: s.r(10),
              offset: Offset(0, s.h(4)),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isCompact ? s.sp(42) : s.sp(48),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            if (isVotingComplete) ...[
              FadeTransition(
                opacity: _resultsOpacityAnimation,
                child: Column(
                  children: [
                    SizedBox(height: isCompact ? s.h(4) : s.h(8)),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: isCompact ? s.sp(20) : s.sp(24),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      votes == 1
                          ? 'game.vote_singular'.tr(args: ['$votes'])
                          : 'game.vote_plural'.tr(args: ['$votes']),
                      style: TextStyle(
                        fontSize: isCompact ? s.sp(11) : s.sp(14),
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
