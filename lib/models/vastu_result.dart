import 'package:vastuscan_ar/models/vastu_rule.dart';
import 'package:vastuscan_ar/models/detected_object.dart';

/// The result of evaluating a detected object against Vastu rules.
class VastuResult {
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
    required this.detectedObject,
    required this.rule,
    required this.isCompliant,
    required this.currentDirection,
    required this.currentDirectionLabel,
    required this.score,
    required this.summary,
  });

  @override
  String toString() =>
      'VastuResult(${rule.element}: ${isCompliant ? "✅" : "❌"} @ $currentDirectionLabel)';
}
