import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/round_result.dart';
import 'start_screen.dart';
import 'countdown_screen.dart';
import 'category_selection_screen.dart';
import '../utils/app_scale.dart';

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

  static const Map<String, String> _categoryTranslationKeys = {
    'chill': 'categories.chill',
    'family': 'categories.family',
    'friends': 'categories.friends',
    'spicy': 'categories.spicy',
    'wild': 'categories.wild',
    'deep': 'categories.deep',
  };

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

  MapEntry<String, int>? get _topExtendedCategory {
    final byCategory = <String, int>{};
    for (final r in roundResults) {
      if (r.extensionsCount <= 0) continue;
      byCategory.update(
        r.categoryName,
        (value) => value + r.extensionsCount,
        ifAbsent: () => r.extensionsCount,
      );
    }
    if (byCategory.isEmpty) return null;
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first;
  }

  int get _averageDiscussionSeconds {
    if (roundResults.isEmpty) return 0;
    final sum = roundResults.fold<int>(
      0,
      (acc, r) => acc + r.discussionDurationSeconds,
    );
    return (sum / roundResults.length).round();
  }

  int get _longestDiscussionSeconds {
    if (roundResults.isEmpty) return 0;
    return roundResults
        .map((r) => r.discussionDurationSeconds)
        .reduce((a, b) => a > b ? a : b);
  }

  int get _fullAgreementCount {
    return roundResults.where((r) => (r.agreementPercent - 100).abs() < 0.01).length;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    final avg = _averageAgreement;
    final hasVotes = roundResults.isNotEmpty;
    final mostAgreement = _categoryMostAgreement;
    final mostDifference = _categoryMostDifference;
    final allSimilar = _allCategoriesSimilar;
    final topExtendedCategory = _topExtendedCategory;
    final avgDiscussion = _averageDiscussionSeconds;
    final longestDiscussion = _longestDiscussionSeconds;
    final fullAgreementCount = _fullAgreementCount;

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
            padding: EdgeInsets.symmetric(horizontal: s.w(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: s.h(16)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _goHome(context),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[700],
                        size: s.r(28),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                SizedBox(height: s.h(24)),
                Text(
                  'summary.title'.tr(),
                  style: TextStyle(
                    fontSize: s.sp(28),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: s.h(32)),
                Container(
                  padding: EdgeInsets.all(s.r(24)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(s.r(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: s.r(20),
                        offset: Offset(0, s.h(6)),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'summary.group_agreement'.tr(),
                        style: TextStyle(
                          fontSize: s.sp(16),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: s.h(12)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(s.r(12)),
                              child: LinearProgressIndicator(
                                value: hasVotes ? (avg / 100).clamp(0.0, 1.0) : 0,
                                minHeight: s.h(12),
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFB2E0D8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: s.w(16)),
                          Text(
                            hasVotes ? '${avg.round()}%' : '—',
                            style: TextStyle(
                              fontSize: s.sp(24),
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      if (!hasVotes) ...[
                        SizedBox(height: s.h(10)),
                        Text(
                          'summary.no_votes_hint'.tr(),
                          style: TextStyle(
                            fontSize: s.sp(13),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: s.h(28)),
                if (hasVotes) ...[
                  if (_isExactly(avg, 100))
                    _buildInfoCard(
                      context,
                      'summary.full_agreement'.tr(),
                      Icons.emoji_events_outlined,
                    )
                  else if (_isExactly(avg, 50))
                    _buildInfoCard(
                      context,
                      'summary.split_evenly'.tr(),
                      Icons.balance,
                    )
                  else if (avg >= 45 && avg <= 55)
                    _buildInfoCard(
                      context,
                      'summary.split_nearly'.tr(),
                      Icons.balance,
                    )
                  else if (allSimilar)
                    _buildInfoCard(
                      context,
                      'summary.all_categories_similar'.tr(),
                      Icons.extension,
                    )
                  else ...[
                    if (mostAgreement != null)
                      _buildInfoCard(
                        context,
                        'summary.most_agreement'.tr(
                          args: [_translateCategory(mostAgreement)],
                        ),
                        Icons.thumb_up_outlined,
                      ),
                    if (mostAgreement != null && mostDifference != null)
                      SizedBox(height: s.h(12)),
                    if (mostDifference != null)
                      _buildInfoCard(
                        context,
                        'summary.most_difference'.tr(
                          args: [_translateCategory(mostDifference)],
                        ),
                        Icons.forum_outlined,
                      ),
                  ],
                  SizedBox(height: s.h(12)),
                  if (topExtendedCategory != null)
                    _buildInfoCard(
                      context,
                      'summary.extended_top'.tr(
                        args: [
                          _translateCategory(topExtendedCategory.key),
                          '${topExtendedCategory.value}',
                        ],
                      ),
                      Icons.schedule,
                    ),
                  if (topExtendedCategory != null) SizedBox(height: s.h(12)),
                  _buildInfoCard(
                    context,
                    'summary.talk_time_stats'.tr(
                      args: [
                        _formatDuration(avgDiscussion),
                        _formatDuration(longestDiscussion),
                      ],
                    ),
                    Icons.timelapse,
                  ),
                  SizedBox(height: s.h(12)),
                  _buildInfoCard(
                    context,
                    fullAgreementCount == 0
                        ? 'summary.full_agreement_none'.tr()
                        : fullAgreementCount == 1
                            ? 'summary.full_agreement_count_one'.tr(
                                args: ['$fullAgreementCount'],
                              )
                            : 'summary.full_agreement_count_other'.tr(
                                args: ['$fullAgreementCount'],
                              ),
                    Icons.emoji_events_outlined,
                  ),
                ] else
                  _buildInfoCard(
                    context,
                    'summary.no_votes_card'.tr(),
                    Icons.auto_awesome_outlined,
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _playAgain(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB2E0D8),
                      padding: EdgeInsets.symmetric(vertical: s.h(18)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(s.r(30)),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'buttons.play_again'.tr(),
                      style: TextStyle(
                        fontSize: s.sp(18),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: s.h(24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _translateCategory(String value) {
    final key = _categoryTranslationKeys[value];
    if (key == null) return value;
    return key.tr();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoCard(BuildContext context, String text, IconData icon) {
    final s = AppScale.of(context);
    return Container(
      padding: EdgeInsets.all(s.r(20)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(s.r(16)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: s.r(24), color: Colors.grey[600]),
          SizedBox(width: s.w(14)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: s.sp(15),
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
