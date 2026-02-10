/// Wynik jednej rundy (jedno pytanie) - do statystyk sesji.
class RoundResult {
  final String categoryName;
  final int totalVotes;
  final int majorityVotes;

  RoundResult({
    required this.categoryName,
    required this.totalVotes,
    required this.majorityVotes,
  });

  /// Zgodność = większość / total (Metoda A).
  double get agreementPercent {
    if (totalVotes == 0) return 0;
    return (majorityVotes / totalVotes) * 100;
  }
}
