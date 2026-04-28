import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:vastuscan_ar/models/vastu_rule.dart';
import 'package:vastuscan_ar/models/vastu_result.dart';
import 'package:vastuscan_ar/models/scan_session.dart';
import 'package:vastuscan_ar/utils/direction_utils.dart';

/// The Vastu Logic Engine.
class VastuEngine extends ChangeNotifier {
  List<VastuRule> _rules = [];
  List<VastuRule> get rules => _rules;

  Map<String, List<String>> _cocoToVastuMapping = {};
  Map<String, DirectionRange> _directionRanges = {};

  ScanSession _session = ScanSession.empty();
  ScanSession get session => _session;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  bool _isSessionActive = false;
  bool get isSessionActive => _isSessionActive;

  Future<void> loadRules() async {
    try {
      final jsonString = await rootBundle.loadString('assets/vastu_rules.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final rulesList = data['rules'] as List;
      _rules = rulesList.map((r) => VastuRule.fromJson(r)).toList();

      final mappingData = data['coco_to_vastu_mapping'] as Map<String, dynamic>;
      _cocoToVastuMapping = mappingData.map(
        (key, value) => MapEntry(key, List<String>.from(value as List)),
      );

      final rangeData = data['direction_ranges'] as Map<String, dynamic>;
      _directionRanges = rangeData.map(
        (key, value) => MapEntry(
          key,
          DirectionRange.fromJson(key, value as Map<String, dynamic>),
        ),
      );

      _isLoaded = true;
      notifyListeners();
      debugPrint('VastuEngine: Loaded ${_rules.length} rules');
    } catch (e) {
      debugPrint('VastuEngine: Failed to load rules: $e');
    }
  }

  /// Begin a new scan session (resets state).
  void startSession({String? roomLabel}) {
    _session = ScanSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: roomLabel != null ? '$roomLabel Scan' : 'Vastu Scan',
      roomLabel: roomLabel,
      results: const [],
      score: 0,
      compliantCount: 0,
      nonCompliantCount: 0,
      startTime: DateTime.now(),
    );
    _isSessionActive = true;
    notifyListeners();
  }

  /// Stop the active session and return it with end time stamped.
  ScanSession stopSession() {
    final completed = _session.copyWith(endTime: DateTime.now());
    _session = completed;
    _isSessionActive = false;
    notifyListeners();
    return completed;
  }

  List<VastuResult> evaluateObject(DetectedObject object, double heading) {
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
      activeRules.add(_generateSemanticRule(object.label));
    }

    if (activeRules.isEmpty) return [];

    for (final rule in activeRules) {
      final isCompliant = rule.applicableTo.contains(currentCardinal);
      double score;
      if (isCompliant) {
        score = 1.0;
      } else {
        final distance =
            _calculateDirectionDistance(currentCardinal, rule.applicableTo);
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

  void evaluateAll(List<DetectedObject> objects, double heading) {
    if (!_isLoaded) return;

    final allResults = <VastuResult>[];
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

  int _calculateDirectionDistance(String current, List<String> targets) {
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

  VastuRule getRuleForLabel(String cocoLabel) {
    final ruleIds = _cocoToVastuMapping[cocoLabel];
    if (ruleIds == null || ruleIds.isEmpty) return _generateSemanticRule(cocoLabel);
    try {
      return _rules.firstWhere((r) => r.id == ruleIds.first);
    } catch (_) {
      return _generateSemanticRule(cocoLabel);
    }
  }

  VastuRule _generateSemanticRule(String label) {
    final lower = label.toLowerCase();
    // Door / Entrance / Exit — critical Vastu element
    if (lower.contains(RegExp(r'door|entrance|entry|exit|gate|main door|front door'))) {
      return VastuRule(id: 'dyn_door', category: 'Entrance (Critical)', element: 'Main Door / Entrance', idealDirection: 'North or East', applicableTo: ['N', 'NE', 'E'], purpose: 'The main entrance is the most important Vastu element. North/East/NE facing doors bring prosperity.', practicalTips: 'Main door should face N, NE, or E. Avoid S and SW entrances. Keep entrance well-lit and clutter-free. Place auspicious symbols like toran or swastik.', cocoLabels: [lower]);
    }
    // Windows
    if (lower.contains(RegExp(r'window|ventilat|opening|skylight'))) {
      return VastuRule(id: 'dyn_window', category: 'Ventilation', element: 'Window / Opening', idealDirection: 'North or East', applicableTo: ['N', 'NE', 'E', 'NW'], purpose: 'Windows in N/E allow positive energy and sunlight.', practicalTips: 'More windows on N and E walls. Fewer on S and W. Keep windows clean.', cocoLabels: [lower]);
    }
    if (lower.contains(RegExp(r'electronic|wire|engine|motor|computer|phone|laptop|switch|oven|microwave|stove|machine|car|vehicle|light|tv|television|monitor|speaker|charger|router|ac|air.?condition'))) {
      return VastuRule(id: 'dyn_fire', category: 'Dynamic (Fire)', element: 'Fire / Active Component', idealDirection: 'SouthEast', applicableTo: ['SE', 'S', 'E'], purpose: 'Provides energy and warmth.', practicalTips: 'Keep electronics in SE zone.', cocoLabels: [lower]);
    } else if (lower.contains(RegExp(r'cool|liquid|sink|wash|pool|pipe|glass|drink|bottle|water|tap|fluid|ice|pooja|puja|idol|sacred|temple|god|prayer|tulsi|diya|kalash|bell|agarbatti|havan'))) {
      return VastuRule(id: 'dyn_water_spiritual', category: 'Water / Spiritual', element: 'Water / Divine Component', idealDirection: 'NorthEast', applicableTo: ['N', 'NE', 'E'], purpose: 'Flowing elements and spiritual items.', practicalTips: 'Keep clean and in NE/N zone.', cocoLabels: [lower]);
    } else if (lower.contains(RegExp(r'storage|luggage|tire|heavy|solid|furniture|couch|sofa|bed|cabinet|box|wardrobe|brick|stone|shelf|armchair|almirah'))) {
      return VastuRule(id: 'dyn_earth', category: 'Dynamic (Earth)', element: 'Earth / Heavy Component', idealDirection: 'SouthWest', applicableTo: ['SW', 'S', 'W'], purpose: 'Imparts stability.', practicalTips: 'Keep heavy items in SW zone.', cocoLabels: [lower]);
    } else if (lower.contains(RegExp(r'needle|sharp|metal|iron|scissors|knife|blade|tool|air|fan|wind|ceiling fan|exhaust'))) {
      return VastuRule(id: 'dyn_air', category: 'Dynamic (Air/Metal)', element: 'Air / Sharp Component', idealDirection: 'NorthWest', applicableTo: ['NW', 'W', 'N'], purpose: 'Facilitates movement.', practicalTips: 'Keep sharp/air items in NW zone.', cocoLabels: [lower]);
    } else {
      return VastuRule(id: 'dyn_neutral', category: 'Generic/Neutral', element: 'Space Element', idealDirection: 'Any Direction', applicableTo: ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'], purpose: 'Neutral impact.', practicalTips: 'Keep area clean and clutter-free.', cocoLabels: [lower]);
    }
  }

  void resetSession() {
    _session = ScanSession.empty();
    _isSessionActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
