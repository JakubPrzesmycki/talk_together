import 'package:flutter/material.dart';
import '../models/round_result.dart';
import 'start_screen.dart';
import 'countdown_screen.dart';
import 'category_selection_screen.dart';

class SessionSummaryScreen extends StatelessWidget {
  final List<RoundResult> roundResults;
  final List<String> categories;
  final Map<String, CategoryData> categoriesData;
  final int numberOfPlayers;
  final int discussionTime;

  const SessionSummaryScreen({
    super.key,
    required this.roundResults,
    required this.categories,
    required this.categoriesData,
    required this.numberOfPlayers,
    required this.discussionTime,
  });

  double get _averageAgreement {
    if (roundResults.isEmpty) return 0;
    final sum = roundResults.fold<double>(
      0,
      (acc, r) => acc + r.agreementPercent,
    );
    return sum / roundResults.length;
  }

  String? get _categoryMostAgreement {
    if (roundResults.isEmpty) return null;
    final byCategory = <String, List<RoundResult>>{};
    for (final r in roundResults) {
      byCategory.putIfAbsent(r.categoryName, () => []).add(r);
    }
    String? best;
    double bestAvg = -1;
    for (final e in byCategory.entries) {
      final avg = e.value.fold<double>(0, (a, r) => a + r.agreementPercent) /
          e.value.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        best = e.key;
      }
    }
    return best;
  }

  String? get _categoryMostDifference {
    if (roundResults.isEmpty) return null;
    final byCategory = <String, List<RoundResult>>{};
    for (final r in roundResults) {
      byCategory.putIfAbsent(r.categoryName, () => []).add(r);
    }
    String? worst;
    double worstAvg = 101;
    for (final e in byCategory.entries) {
      final avg = e.value.fold<double>(0, (a, r) => a + r.agreementPercent) /
          e.value.length;
      if (avg < worstAvg) {
        worstAvg = avg;
        worst = e.key;
      }
    }
    return worst;
  }

  bool get _allCategoriesSimilar {
    if (roundResults.length < 2) return true;
    final byCategory = <String, List<RoundResult>>{};
    for (final r in roundResults) {
      byCategory.putIfAbsent(r.categoryName, () => []).add(r);
    }
    if (byCategory.length < 2) return true;
    final avgs = byCategory.entries
        .map((e) => e.value.fold<double>(0, (a, r) => a + r.agreementPercent) /
            e.value.length)
        .toList();
    final minAvg = avgs.reduce((a, b) => a < b ? a : b);
    final maxAvg = avgs.reduce((a, b) => a > b ? a : b);
    return (maxAvg - minAvg) < 15;
  }

  bool _isExactly(double value, double target, [double epsilon = 0.01]) {
    return (value - target).abs() < epsilon;
  }

  @override
  Widget build(BuildContext context) {
    final avg = _averageAgreement;
    final mostAgreement = _categoryMostAgreement;
    final mostDifference = _categoryMostDifference;
    final allSimilar = _allCategoriesSimilar;
    final hasVotes = roundResults.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFB2E0D8).withOpacity(0.2),
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _goHome(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[700],
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Podsumowanie sesji',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Poziom zgodności grupy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: hasVotes ? (avg / 100).clamp(0.0, 1.0) : 0,
                                minHeight: 12,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFB2E0D8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            hasVotes ? '${avg.round()}%' : '—',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      if (!hasVotes) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Brak danych z głosowania w tej sesji.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                if (hasVotes) ...[
                  if (_isExactly(avg, 100))
                    _buildInfoCard(
                      'Pełna zgodność! W tej sesji byliście wyjątkowo jednomyślni.',
                      Icons.emoji_events_outlined,
                    )
                  else if (_isExactly(avg, 50))
                    _buildInfoCard(
                      'Byliście podzieleni dokładnie po równo.',
                      Icons.balance,
                    )
                  else if (avg >= 45 && avg <= 55)
                    _buildInfoCard(
                      'Byliście podzieleni niemal po równo.',
                      Icons.balance,
                    )
                  else if (allSimilar)
                    _buildInfoCard(
                      'We wszystkich kategoriach mieliście podobny poziom zgodności.',
                      Icons.extension,
                    )
                  else ...[
                    if (mostAgreement != null)
                      _buildInfoCard(
                        'Najwięcej zgodności mieliście w kategorii: $mostAgreement',
                        Icons.thumb_up_outlined,
                      ),
                    if (mostAgreement != null && mostDifference != null)
                      const SizedBox(height: 12),
                    if (mostDifference != null)
                      _buildInfoCard(
                        'Najwięcej różnic było przy pytaniach: $mostDifference',
                        Icons.forum_outlined,
                      ),
                  ],
                ] else
                  _buildInfoCard(
                    'To była szybka sesja. Zagrajcie kolejną rundę, aby odkryć ciekawostki o grupie.',
                    Icons.auto_awesome_outlined,
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _playAgain(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB2E0D8),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'Zagraj ponownie',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _playAgain(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CountdownScreen(
          categories: categories,
          categoriesData: categoriesData,
          numberOfPlayers: numberOfPlayers,
          discussionTime: discussionTime,
        ),
      ),
      (route) => false,
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const StartScreen()),
      (route) => false,
    );
  }
}
