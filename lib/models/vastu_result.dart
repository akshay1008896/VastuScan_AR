import 'package:vastuscan_ar/models/vastu_rule.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// The result of evaluating a detected object against Vastu rules.
class VastuResult {
  /// Unique ID for this specific result. Useful for lists.
  final String id;

  /// The detected object being evaluated.
  final DetectedObject detectedObject;

  /// The matching Vastu rule.
  final VastuRule rule;

  /// Whether the object placement is compliant.
  final bool isCompliant;

  /// Current cardinal direction where the object was detected.
  final String currentDirection;

  /// Current direction label (full name).
  final String currentDirectionLabel;

  /// Score contribution (0.0 - 1.0).
  final double score;

  /// Human-readable summary of the result.
  final String summary;

  const VastuResult({
    required this.id,
    required this.detectedObject,
    required this.rule,
    required this.isCompliant,
    required this.currentDirection,
    required this.currentDirectionLabel,
    required this.score,
    required this.summary,
  });

  factory VastuResult.create({
    required DetectedObject detectedObject,
    required VastuRule rule,
    required bool isCompliant,
    required String currentDirection,
    required String currentDirectionLabel,
    required double score,
    required String summary,
  }) {
    return VastuResult(
      id: _uuid.v4(),
      detectedObject: detectedObject,
      rule: rule,
      isCompliant: isCompliant,
      currentDirection: currentDirection,
      currentDirectionLabel: currentDirectionLabel,
      score: score,
      summary: summary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'detectedObject': detectedObject.toJson(),
      'rule': rule.toJson(),
      'isCompliant': isCompliant,
      'currentDirection': currentDirection,
      'currentDirectionLabel': currentDirectionLabel,
      'score': score,
      'summary': summary,
    };
  }

  factory VastuResult.fromJson(Map<String, dynamic> json) {
    return VastuResult(
      id: json['id'] as String? ?? _uuid.v4(),
      detectedObject: DetectedObject.fromJson(json['detectedObject'] as Map<String, dynamic>),
      rule: VastuRule.fromJson(json['rule'] as Map<String, dynamic>),
      isCompliant: json['isCompliant'] as bool,
      currentDirection: json['currentDirection'] as String,
      currentDirectionLabel: json['currentDirectionLabel'] as String,
      score: (json['score'] as num).toDouble(),
      summary: json['summary'] as String,
    );
  }

  @override
  String toString() =>
      'VastuResult(${rule.element}: ${isCompliant ? "✅" : "❌"} @ $currentDirectionLabel)';
}
