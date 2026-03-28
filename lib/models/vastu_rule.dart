/// A Vastu rule defining the ideal placement/direction for an element.
class VastuRule {
  final String id;
  final String category;
  final String element;
  final String idealDirection;
  final List<String> applicableTo;
  final String purpose;
  final String practicalTips;
  final List<String> cocoLabels;

  const VastuRule({
    required this.id,
    required this.category,
    required this.element,
    required this.idealDirection,
    required this.applicableTo,
    required this.purpose,
    required this.practicalTips,
    required this.cocoLabels,
  });

  factory VastuRule.fromJson(Map<String, dynamic> json) {
    return VastuRule(
      id: json['id'] as String,
      category: json['category'] as String,
      element: json['element'] as String,
      idealDirection: json['ideal_direction'] as String,
      applicableTo: List<String>.from(json['applicable_to'] as List),
      purpose: json['purpose'] as String,
      practicalTips: json['practical_tips'] as String,
      cocoLabels: List<String>.from(json['coco_labels'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'element': element,
      'ideal_direction': idealDirection,
      'applicable_to': applicableTo,
      'purpose': purpose,
      'practical_tips': practicalTips,
      'coco_labels': cocoLabels,
    };
  }

  @override
  String toString() => 'VastuRule($element → $idealDirection)';
}

/// Direction range definition for compass heading mapping.
class DirectionRange {
  final String code;
  final double min;
  final double max;
  final String label;
  final String element;
  final String deity;

  const DirectionRange({
    required this.code,
    required this.min,
    required this.max,
    required this.label,
    required this.element,
    required this.deity,
  });

  factory DirectionRange.fromJson(String code, Map<String, dynamic> json) {
    return DirectionRange(
      code: code,
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
      label: json['label'] as String,
      element: json['element'] as String,
      deity: json['deity'] as String,
    );
  }

  /// Check if a given heading falls within this direction range.
  bool containsHeading(double heading) {
    if (min > max) {
      // Wraps around 0° (e.g., North: 337.5 – 22.5)
      return heading >= min || heading < max;
    }
    return heading >= min && heading < max;
  }
}
