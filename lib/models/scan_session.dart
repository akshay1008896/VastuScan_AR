import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Represents a scanning session with aggregate statistics.
class ScanSession {
  final String id;
  final String name;
  final String? roomLabel;
  final String? locationDescription;
  final List<VastuResult> results;
  final double score;
  final int compliantCount;
  final int nonCompliantCount;
  final DateTime startTime;
  final DateTime? endTime;

  const ScanSession({
    required this.id,
    required this.name,
    this.roomLabel,
    this.locationDescription,
    required this.results,
    required this.score,
    required this.compliantCount,
    required this.nonCompliantCount,
    required this.startTime,
    this.endTime,
  });

  factory ScanSession.empty() {
    return ScanSession(
      id: _uuid.v4(),
      name: 'New Scan',
      results: const [],
      score: 0,
      compliantCount: 0,
      nonCompliantCount: 0,
      startTime: DateTime.now(),
    );
  }

  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  String get durationFormatted {
    final d = duration;
    if (d == null) return '--';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? "${d.inHours}h " : ""}${m}m ${s}s';
  }

  ScanSession copyWith({
    String? id,
    String? name,
    String? roomLabel,
    String? locationDescription,
    List<VastuResult>? results,
    double? score,
    int? compliantCount,
    int? nonCompliantCount,
    DateTime? endTime,
  }) {
    return ScanSession(
      id: id ?? this.id,
      name: name ?? this.name,
      roomLabel: roomLabel ?? this.roomLabel,
      locationDescription: locationDescription ?? this.locationDescription,
      results: results ?? this.results,
      score: score ?? this.score,
      compliantCount: compliantCount ?? this.compliantCount,
      nonCompliantCount: nonCompliantCount ?? this.nonCompliantCount,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roomLabel': roomLabel,
      'locationDescription': locationDescription,
      'results': results.map((r) => r.toJson()).toList(),
      'score': score,
      'compliantCount': compliantCount,
      'nonCompliantCount': nonCompliantCount,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory ScanSession.fromJson(Map<String, dynamic> json) {
    return ScanSession(
      id: json['id'] as String? ?? _uuid.v4(),
      name: json['name'] as String? ?? 'Imported Scan',
      roomLabel: json['roomLabel'] as String?,
      locationDescription: json['locationDescription'] as String?,
      results: (json['results'] as List?)
              ?.map((r) => VastuResult.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      score: (json['score'] as num).toDouble(),
      compliantCount: json['compliantCount'] as int,
      nonCompliantCount: json['nonCompliantCount'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  int get totalCount => results.length;
  String get scoreFormatted => '${score.toStringAsFixed(0)}%';
}
