import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';

class QuestionsData {
  static const String _fallbackLocale = 'en';
  static const String _questionsPath = 'assets/questions';
  static const String _fallbackCategoryId = 'chill';

  static const Set<String> _categoryIds = {
    'chill',
    'family',
    'friends',
    'spicy',
    'wild',
    'deep',
  };

  static final Map<String, Map<String, List<Question>>> _cache = {};

  static Future<List<Question>> getQuestionsByCategory({
    required String categoryName,
    required String localeCode,
  }) async {
    final categoryId =
        _categoryIds.contains(categoryName) ? categoryName : _fallbackCategoryId;
    final localizedData = await _loadQuestionsForLocale(localeCode);
    final localizedQuestions = localizedData[categoryId];
    if (localizedQuestions != null && localizedQuestions.isNotEmpty) {
      return localizedQuestions;
    }

    final fallbackData = await _loadQuestionsForLocale(_fallbackLocale);
    final fallbackQuestions = fallbackData[categoryId];
    if (fallbackQuestions != null && fallbackQuestions.isNotEmpty) {
      return fallbackQuestions;
    }

    return fallbackData[_fallbackCategoryId] ?? const [];
  }

  static Future<Map<String, List<Question>>> _loadQuestionsForLocale(
    String localeCode,
  ) async {
    if (_cache.containsKey(localeCode)) {
      return _cache[localeCode]!;
    }

    try {
      final jsonString = await rootBundle.loadString(
        '$_questionsPath/$localeCode.json',
      );
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final categories = decoded['categories'] as Map<String, dynamic>? ?? {};

      final parsed = <String, List<Question>>{};
      for (final entry in categories.entries) {
        final rawList = entry.value as List<dynamic>? ?? const [];
        parsed[entry.key] = rawList
            .whereType<Map>()
            .map((item) => item.map((k, v) => MapEntry('$k', v)))
            .map(Question.fromJson)
            .where(
              (q) =>
                  q.text.isNotEmpty &&
                  q.option1.isNotEmpty &&
                  q.option2.isNotEmpty,
            )
            .toList();
      }

      _cache[localeCode] = parsed;
      return parsed;
    } catch (_) {
      _cache[localeCode] = {};
      return _cache[localeCode]!;
    }
  }
}
