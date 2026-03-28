import 'package:vastuscan_ar/models/vastu_result.dart';

/// Represents a scanning session with aggregate statistics.
class ScanSession {
  /// All Vastu evaluation results in this session.
  final List<VastuResult> results;

  /// The current overall Vastu score (0–100).
  final double score;

  /// Number of compliant items.
  final int compliantCount;

  /// Number of non-compliant items.
  final int nonCompliantCount;

  /// Session start time.
  final DateTime startTime;

  const ScanSession({
    required this.results,
    required this.score,
    required this.compliantCount,
    required this.nonCompliantCount,
    required this.startTime,
  });

  factory ScanSession.empty() {
    return ScanSession(
      results: const [],
      score: 0,
      compliantCount: 0,
      nonCompliantCount: 0,
      startTime: DateTime.now(),
    );
  }

  ScanSession copyWith({
    List<VastuResult>? results,
    double? score,
    int? compliantCount,
    int? nonCompliantCount,
  }) {
    return ScanSession(
      results: results ?? this.results,
      score: score ?? this.score,
      compliantCount: compliantCount ?? this.compliantCount,
      nonCompliantCount: nonCompliantCount ?? this.nonCompliantCount,
      startTime: startTime,
    );
  }

  /// Total detected items count.
  int get totalCount => results.length;

  /// Formatted score string.
  String get scoreFormatted => '${score.toStringAsFixed(0)}%';
}
