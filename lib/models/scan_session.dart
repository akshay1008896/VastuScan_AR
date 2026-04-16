import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Represents a scanning session with aggregate statistics.
class ScanSession {
  /// Unique ID for this session.
  final String id;

  /// User-defined name or friendly name.
  final String name;

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
    required this.id,
    required this.name,
    required this.results,
    required this.score,
    required this.compliantCount,
    required this.nonCompliantCount,
    required this.startTime,
  });

  factory ScanSession.empty() {
    return ScanSession(
      id: _uuid.v4(),
      name: 'Unsaved Scan',
      results: const [],
      score: 0,
      compliantCount: 0,
      nonCompliantCount: 0,
      startTime: DateTime.now(),
    );
  }

  ScanSession copyWith({
    String? id,
    String? name,
    List<VastuResult>? results,
    double? score,
    int? compliantCount,
    int? nonCompliantCount,
  }) {
    return ScanSession(
      id: id ?? this.id,
      name: name ?? this.name,
      results: results ?? this.results,
      score: score ?? this.score,
      compliantCount: compliantCount ?? this.compliantCount,
      nonCompliantCount: nonCompliantCount ?? this.nonCompliantCount,
      startTime: startTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'results': results.map((r) => r.toJson()).toList(),
      'score': score,
      'compliantCount': compliantCount,
      'nonCompliantCount': nonCompliantCount,
      'startTime': startTime.toIso8601String(),
    };
  }

  factory ScanSession.fromJson(Map<String, dynamic> json) {
    return ScanSession(
      id: json['id'] as String? ?? _uuid.v4(),
      name: json['name'] as String? ?? 'Imported Scan',
      results: (json['results'] as List?)
              ?.map((r) => VastuResult.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      score: (json['score'] as num).toDouble(),
      compliantCount: json['compliantCount'] as int,
      nonCompliantCount: json['nonCompliantCount'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
    );
  }

  /// Total detected items count.
  int get totalCount => results.length;

  /// Formatted score string.
  String get scoreFormatted => '${score.toStringAsFixed(0)}%';
}
