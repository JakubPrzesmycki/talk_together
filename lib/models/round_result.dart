/// Wynik jednej rundy (jedno pytanie) - do statystyk sesji.
class RoundResult {
  final String categoryName;
  final String questionText;
  final int totalVotes;
  final int majorityVotes;
  final int extensionsCount;
  final int discussionDurationSeconds;

  RoundResult({
    required this.categoryName,
    required this.questionText,
    required this.totalVotes,
    required this.majorityVotes,
    this.extensionsCount = 0,
    this.discussionDurationSeconds = 0,
  });

  RoundResult copyWith({
    String? categoryName,
    String? questionText,
    int? totalVotes,
    int? majorityVotes,
    int? extensionsCount,
    int? discussionDurationSeconds,
  }) {
    return RoundResult(
      categoryName: categoryName ?? this.categoryName,
      questionText: questionText ?? this.questionText,
      totalVotes: totalVotes ?? this.totalVotes,
      majorityVotes: majorityVotes ?? this.majorityVotes,
      extensionsCount: extensionsCount ?? this.extensionsCount,
      discussionDurationSeconds:
          discussionDurationSeconds ?? this.discussionDurationSeconds,
    );
  }

  /// Zgodność = większość / total (Metoda A).
  double get agreementPercent {
    if (totalVotes == 0) return 0;
    return (majorityVotes / totalVotes) * 100;
  }
}
