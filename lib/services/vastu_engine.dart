import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:vastuscan_ar/models/vastu_rule.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/models/scan_session.dart';
import 'package:vastuscan_ar/utils/direction_utils.dart';

/// The Vastu Logic Engine.
///
/// Loads rules from JSON, evaluates detected objects against compass heading,
/// and produces compliance results with scores.
class VastuEngine extends ChangeNotifier {
  List<VastuRule> _rules = [];
  List<VastuRule> get rules => _rules;

  Map<String, List<String>> _cocoToVastuMapping = {};
  Map<String, DirectionRange> _directionRanges = {};

  ScanSession _session = ScanSession.empty();
  ScanSession get session => _session;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Load Vastu rules from the bundled JSON file.
  Future<void> loadRules() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/vastu_rules.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Parse rules
      final rulesList = data['rules'] as List;
      _rules = rulesList.map((r) => VastuRule.fromJson(r)).toList();

      // Parse COCO-to-Vastu mapping
      final mappingData =
          data['coco_to_vastu_mapping'] as Map<String, dynamic>;
      _cocoToVastuMapping = mappingData.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );

      // Parse direction ranges
      final rangeData =
          data['direction_ranges'] as Map<String, dynamic>;
      _directionRanges = rangeData.map(
        (key, value) => MapEntry(
          key,
          DirectionRange.fromJson(key, value as Map<String, dynamic>),
        ),
      );

      _isLoaded = true;
      notifyListeners();

      print(
          'VastuEngine: Loaded ${_rules.length} rules, ${_cocoToVastuMapping.length} COCO mappings');
    } catch (e) {
      print('VastuEngine: Failed to load rules: $e');
    }
  }

  /// Evaluate a single detected object against the current compass heading.
  List<VastuResult> evaluateObject(
      DetectedObject object, double heading) {
    if (!_isLoaded) return [];

    final results = <VastuResult>[];
    final currentCardinal = DirectionUtils.headingToCardinal(heading);
    final currentLabel = DirectionUtils.headingToLabel(heading);

    List<String> ruleIds = _cocoToVastuMapping[object.label] ?? [];
    List<VastuRule> activeRules = [];

    if (ruleIds.isNotEmpty) {
      for (final ruleId in ruleIds) {
        try {
          final rule = _rules.firstWhere((r) => r.id == ruleId);
          activeRules.add(rule);
        } catch (_) {}
      }
    } else {
      // Dynamic semantic rule fallback
      activeRules.add(_generateSemanticRule(object.label));
    }

    if (activeRules.isEmpty) return [];

    for (final rule in activeRules) {

      // Check compliance: is the current direction in the "applicable_to" list?
      final isCompliant = rule.applicableTo.contains(currentCardinal);

      // Calculate partial score based on how close the direction is
      double score;
      if (isCompliant) {
        score = 1.0;
      } else {
        // Calculate distance to nearest compliant direction
        final distance = _calculateDirectionDistance(
            currentCardinal, rule.applicableTo);
        // Score decreases with distance (max distance = 4 steps = 180°)
        score = (1.0 - (distance / 4.0)).clamp(0.0, 0.8);
      }

      final summary = isCompliant
          ? '${rule.element} is correctly placed in the $currentLabel direction.'
          : '${rule.element} should ideally face ${rule.idealDirection}. Currently facing $currentLabel.';

      results.add(VastuResult.create(
        detectedObject: object,
        rule: rule,
        isCompliant: isCompliant,
        currentDirection: currentCardinal,
        currentDirectionLabel: currentLabel,
        score: score,
        summary: summary,
      ));
    }

    return results;
  }

  /// Evaluate all detected objects and update the session.
  void evaluateAll(List<DetectedObject> objects, double heading) {
    if (!_isLoaded) return;

    final allResults = <VastuResult>[];
    // Use a set to avoid duplicate rule evaluations
    final evaluatedRules = <String>{};

    for (final object in objects) {
      final results = evaluateObject(object, heading);
      for (final result in results) {
        final key = '${result.rule.id}_${result.detectedObject.label}';
        if (!evaluatedRules.contains(key)) {
          evaluatedRules.add(key);
          allResults.add(result);
        }
      }
    }

    // Calculate overall score
    double overallScore = 0;
    if (allResults.isNotEmpty) {
      overallScore = allResults.map((r) => r.score).reduce((a, b) => a + b) /
          allResults.length *
          100;
    }

    final compliant = allResults.where((r) => r.isCompliant).length;
    final nonCompliant = allResults.where((r) => !r.isCompliant).length;

    _session = _session.copyWith(
      results: allResults,
      score: overallScore,
      compliantCount: compliant,
      nonCompliantCount: nonCompliant,
    );

    notifyListeners();
  }

  /// Calculate the "step distance" between current direction and nearest
  /// compliant direction (1 step = 45°).
  int _calculateDirectionDistance(
      String current, List<String> targets) {
    const order = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final currentIdx = order.indexOf(current);
    if (currentIdx == -1) return 4;

    int minDistance = 8;
    for (final target in targets) {
      final targetIdx = order.indexOf(target);
      if (targetIdx == -1) continue;

      int distance = (currentIdx - targetIdx).abs();
      if (distance > 4) distance = 8 - distance;
      if (distance < minDistance) minDistance = distance;
    }

    return minDistance;
  }

  /// Get the VastuRule for a specific COCO label or semantic fallback.
  VastuRule getRuleForLabel(String cocoLabel) {
    final ruleIds = _cocoToVastuMapping[cocoLabel];
    if (ruleIds == null || ruleIds.isEmpty) return _generateSemanticRule(cocoLabel);
    try {
      return _rules.firstWhere((r) => r.id == ruleIds.first);
    } catch (_) {
      return _generateSemanticRule(cocoLabel);
    }
  }

  /// Generates a logical VastuRule based on keywords when an object isn't listed in the master JSON.
  VastuRule _generateSemanticRule(String label) {
    final lower = label.toLowerCase();
    
    // Fire / Agni (Southeast)
    if (lower.contains(RegExp(r'electronic|wire|engine|motor|computer|phone|laptop|switch|oven|microwave|stove|machine|car|vehicle|light'))) {
      return VastuRule(
        id: 'dyn_fire',
        category: 'Dynamic (Fire)',
        element: 'Fire / Active Component',
        idealDirection: 'SouthEast',
        applicableTo: ['SE', 'S', 'E'],
        purpose: 'Provides energy and warmth without disturbing peaceful zones.',
        practicalTips: 'Ground active or electronic items using earth-colored mats. Keep them out of the serene NorthEast.',
        cocoLabels: [lower],
      );
    }
    // Water / Jal (Northeast)
    else if (lower.contains(RegExp(r'cool|liquid|sink|wash|pool|pipe|glass|drink|bottle|water|tap|fluid|ice'))) {
      return VastuRule(
        id: 'dyn_water',
        category: 'Dynamic (Water)',
        element: 'Water Component',
        idealDirection: 'NorthEast',
        applicableTo: ['N', 'NE', 'E'],
        purpose: 'Flowing elements signify incoming wealth and serenity.',
        practicalTips: 'If placed in the South, it causes financial instability. Move towards North/NorthEast.',
        cocoLabels: [lower],
      );
    }
    // Earth / Bhumi (South/Southwest)
    else if (lower.contains(RegExp(r'storage|garage|luggage|tire|heavy|solid|furniture|couch|sofa|bed|cabinet|box|wardrobe|brick|stone|shelf|armchair|good'))) {
      return VastuRule(
        id: 'dyn_earth',
        category: 'Dynamic (Earth)',
        element: 'Earth / Heavy Component',
        idealDirection: 'SouthWest',
        applicableTo: ['SW', 'S', 'W'],
        purpose: 'Imparts stability and strength to the environment.',
        practicalTips: 'Make sure heavy, unmoving objects are kept away from the NorthEast to prevent blocking subtle energies.',
        cocoLabels: [lower],
      );
    }
    // Air/Space / Movables (Northwest)
    else if (lower.contains(RegExp(r'needle|sharp|metal|iron|scissors|knife|blade|tool|air|fan|wind'))) {
      return VastuRule(
        id: 'dyn_air',
        category: 'Dynamic (Air/Metal)',
        element: 'Air / Sharp Component',
        idealDirection: 'NorthWest',
        applicableTo: ['NW', 'W', 'N'],
        purpose: 'Facilitates movement, communication, and swift execution.',
        practicalTips: 'Sharp objects misaligned disrupt harmony. NorthWest is ideal for tools and shifting things.',
        cocoLabels: [lower],
      );
    }
    // Neutral (Space) - Default
    else {
      return VastuRule(
        id: 'dyn_neutral',
        category: 'Generic/Neutral',
        element: 'Space Element',
        idealDirection: 'Any Direction',
        applicableTo: ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'],
        purpose: 'Has a relatively neutral impact on the primary Vastu matrix.',
        practicalTips: 'Simply keep the area surrounding this clean and clutter-free.',
        cocoLabels: [lower],
      );
    }
  }

  /// Reset the session.
  void resetSession() {
    _session = ScanSession.empty();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
