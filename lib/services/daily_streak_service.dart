import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_streak_status.dart';

class DailyStreakService {
  DailyStreakService._();

  static final DailyStreakService instance = DailyStreakService._();

  static const String _streakDaysKey = 'daily_streak.days';
  static const String _lastAnsweredKey = 'daily_streak.last_answered_date';
  static const String _shownDailyQuestionDateKey =
      'daily_streak.shown_daily_question_date';
  static const String _shownDailyQuestionTextKey =
      'daily_streak.shown_daily_question_text';

  Future<DailyStreakStatus> getStatus({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime today = _normalizeToLocalDate(now ?? DateTime.now());
    final int storedStreak = prefs.getInt(_streakDaysKey) ?? 0;
    final String? rawLastAnswered = prefs.getString(_lastAnsweredKey);
    final DateTime? lastAnsweredDate = _parseDate(rawLastAnswered);

    if (lastAnsweredDate == null) {
      if (storedStreak != 0) {
        await prefs.setInt(_streakDaysKey, 0);
      }
      return const DailyStreakStatus(
        streakDays: 0,
        hasAnsweredToday: false,
        lastAnsweredDate: null,
      );
    }

    final int daysSinceLastAnswer = _calendarDayDiff(
      from: lastAnsweredDate,
      to: today,
    );

    final bool hasAnsweredToday = daysSinceLastAnswer == 0;
    final bool activeStreak =
        daysSinceLastAnswer == 0 || daysSinceLastAnswer == 1;
    final int effectiveStreak = activeStreak ? storedStreak : 0;

    if (!activeStreak && storedStreak != 0) {
      await prefs.setInt(_streakDaysKey, 0);
    }

    return DailyStreakStatus(
      streakDays: effectiveStreak,
      hasAnsweredToday: hasAnsweredToday,
      lastAnsweredDate: lastAnsweredDate,
    );
  }

  Future<DailyStreakStatus> registerDailyAnswer({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime today = _normalizeToLocalDate(now ?? DateTime.now());
    final statusBeforeUpdate = await getStatus(now: today);

    if (statusBeforeUpdate.hasAnsweredToday) {
      return statusBeforeUpdate;
    }

    final int nextStreak = statusBeforeUpdate.streakDays + 1;
    await prefs.setInt(_streakDaysKey, nextStreak);
    await prefs.setString(_lastAnsweredKey, _formatDate(today));

    return DailyStreakStatus(
      streakDays: nextStreak,
      hasAnsweredToday: true,
      lastAnsweredDate: today,
    );
  }

  Future<String?> getShownDailyQuestionTextForToday({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final DateTime today = _normalizeToLocalDate(now ?? DateTime.now());
    final String todayKey = _formatDate(today);
    final String? savedDate = prefs.getString(_shownDailyQuestionDateKey);
    final String? savedText = prefs.getString(_shownDailyQuestionTextKey);

    if (savedDate == todayKey && savedText != null && savedText.isNotEmpty) {
      return savedText;
    }

    if (savedDate != null && savedDate != todayKey) {
      await prefs.remove(_shownDailyQuestionDateKey);
      await prefs.remove(_shownDailyQuestionTextKey);
    }
    return null;
  }

  Future<void> saveShownDailyQuestionForToday(
    String questionText, {
    DateTime? now,
  }) async {
    if (questionText.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final DateTime today = _normalizeToLocalDate(now ?? DateTime.now());
    await prefs.setString(_shownDailyQuestionDateKey, _formatDate(today));
    await prefs.setString(_shownDailyQuestionTextKey, questionText.trim());
  }

  DateTime _normalizeToLocalDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  int _calendarDayDiff({required DateTime from, required DateTime to}) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }
}
