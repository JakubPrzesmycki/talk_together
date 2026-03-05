import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talk_together/services/daily_streak_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyStreakService', () {
    test('first answer starts streak at 1', () async {
      final status = await DailyStreakService.instance.registerDailyAnswer(
        now: DateTime(2026, 3, 2, 9, 0),
      );

      expect(status.streakDays, 1);
      expect(status.hasAnsweredToday, isTrue);
    });

    test(
      'multiple answers in same day do not increment more than once',
      () async {
        await DailyStreakService.instance.registerDailyAnswer(
          now: DateTime(2026, 3, 2, 9, 0),
        );

        final second = await DailyStreakService.instance.registerDailyAnswer(
          now: DateTime(2026, 3, 2, 23, 10),
        );

        expect(second.streakDays, 1);
        expect(second.hasAnsweredToday, isTrue);
      },
    );

    test('answer on consecutive days increments streak', () async {
      await DailyStreakService.instance.registerDailyAnswer(
        now: DateTime(2026, 3, 1, 10, 0),
      );

      final secondDay = await DailyStreakService.instance.registerDailyAnswer(
        now: DateTime(2026, 3, 2, 8, 30),
      );

      expect(secondDay.streakDays, 2);
      expect(secondDay.hasAnsweredToday, isTrue);
    });

    test('missing one day resets effective streak to 0', () async {
      await DailyStreakService.instance.registerDailyAnswer(
        now: DateTime(2026, 3, 1, 10, 0),
      );

      final statusAfterMiss = await DailyStreakService.instance.getStatus(
        now: DateTime(2026, 3, 3, 12, 0),
      );

      expect(statusAfterMiss.streakDays, 0);
      expect(statusAfterMiss.hasAnsweredToday, isFalse);
    });

    test('after reset, next answer starts new streak from 1', () async {
      await DailyStreakService.instance.registerDailyAnswer(
        now: DateTime(2026, 3, 1, 10, 0),
      );

      final restarted = await DailyStreakService.instance.registerDailyAnswer(
        now: DateTime(2026, 3, 3, 12, 0),
      );

      expect(restarted.streakDays, 1);
      expect(restarted.hasAnsweredToday, isTrue);
    });

    test('shown daily question persists through the same day', () async {
      await DailyStreakService.instance.saveShownDailyQuestionForToday(
        'Sample daily question',
        localeCode: 'en',
        now: DateTime(2026, 3, 2, 9, 0),
      );

      final shown = await DailyStreakService.instance
          .getShownDailyQuestionTextForToday(
            localeCode: 'en',
            now: DateTime(2026, 3, 2, 23, 59),
          );

      expect(shown, 'Sample daily question');
    });

    test('shown daily question resets on the next day', () async {
      await DailyStreakService.instance.saveShownDailyQuestionForToday(
        'Sample daily question',
        localeCode: 'en',
        now: DateTime(2026, 3, 2, 9, 0),
      );

      final shown = await DailyStreakService.instance
          .getShownDailyQuestionTextForToday(
            localeCode: 'en',
            now: DateTime(2026, 3, 3, 8, 0),
          );

      expect(shown, isNull);
    });

    test('shown daily question is locale-specific for the same day', () async {
      await DailyStreakService.instance.saveShownDailyQuestionForToday(
        'Pytanie po polsku',
        localeCode: 'pl',
        now: DateTime(2026, 3, 2, 9, 0),
      );

      final shownForEn = await DailyStreakService.instance
          .getShownDailyQuestionTextForToday(
            localeCode: 'en',
            now: DateTime(2026, 3, 2, 10, 0),
          );

      expect(shownForEn, isNull);
    });
  });
}
