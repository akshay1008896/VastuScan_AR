import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart' as ml;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart' as lbl;

/// Tracked object state for temporal label smoothing.
class _TrackedState {
  final Map<String, int> labelVotes = {};
  String bestLabel = 'unknown';
  double bestConfidence = 0.0;
  DateTime lastSeen = DateTime.now();

  void vote(String label, double confidence) {
    // Don't let 'unknown' votes overpower real labels
    if (label == 'unknown' && labelVotes.isNotEmpty) {
      final hasReal = labelVotes.keys.any((k) => k != 'unknown');
      if (hasReal) return; // Skip unknown vote if we already have a real label
    }
    labelVotes[label] = (labelVotes[label] ?? 0) + 1;
    lastSeen = DateTime.now();
    int maxVotes = 0;
    for (final entry in labelVotes.entries) {
      if (entry.value > maxVotes) {
        maxVotes = entry.value;
        bestLabel = entry.key;
      }
    }
    if (confidence > bestConfidence) bestConfidence = confidence;
  }
}

/// Service that handles object detection.
///
/// IMPORTANT DESIGN PRINCIPLE: Never guess. If we don't know what an object is,
/// label it "unknown" — never randomly assign "sofa" or "chair" based on shape.
///
/// ML Kit's base model only returns 5 coarse categories:
///   Fashion good, Food, Home goods, Place, Plant
/// Everything else comes back as "object" with no label.
///
/// For precise identification, Gemini Vision is required (applyGeminiResults).
class DetectionService extends ChangeNotifier {
  List<DetectedObject> _detectedObjects = [];
  List<DetectedObject> get detectedObjects => _detectedObjects;

  List<DetectedObject> _manualObjects = [];
  List<DetectedObject> get manualObjects => _manualObjects;

  void addManualObject(DetectedObject obj) {
    _manualObjects.add(obj);
    _detectedObjects = [..._detectedObjects, obj];
    notifyListeners();
  }

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  int _framesProcessed = 0;
  int get framesProcessed => _framesProcessed;

  String _lastError = '';
  String get lastError => _lastError;

  bool _isGeminiActive = false;
  bool get isGeminiActive => _isGeminiActive;
  void setGeminiActive(bool v) { _isGeminiActive = v; notifyListeners(); }

  List<DetectedObject> _geminiObjects = [];

  void applyGeminiResults(List<DetectedObject> objects) {
    _geminiObjects = objects;
    _detectedObjects = [..._geminiObjects, ..._manualObjects];
    debugPrint('AR_GEMINI: Applied ${objects.length} precise objects');
    notifyListeners();
  }

  void clearGeminiResults() {
    _geminiObjects = [];
  }

  late ml.ObjectDetector _detector;
  late lbl.ImageLabeler _labeler;

  final Map<int, _TrackedState> _trackingState = {};

  // ─────────────────────────────────────────────────────────────────────────
  // SYNONYM MAP: ONLY specific-to-specific mappings. No generic guessing.
  //
  // RULE: A synonym entry should only exist if the key UNAMBIGUOUSLY means
  //       the value. "electronics" does NOT unambiguously mean "laptop".
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _synonymMap = {
    // Seating (specific terms only)
    'couch': 'sofa',
    'settee': 'sofa',
    'loveseat': 'sofa',
    'sofa set': 'sofa',
    'recliner': 'armchair',
    'ottoman': 'ottoman',

    // Bed
    'mattress': 'bed',
    'bedding': 'bed',

    // Storage (specific terms only)
    'cupboard': 'wardrobe',
    'closet': 'wardrobe',
    'armoire': 'wardrobe',
    'almirah': 'wardrobe',
    'bookcase': 'bookshelf',

    // Kitchen (specific terms only)
    'cooktop': 'gas stove',
    'burner': 'gas stove',
    'cooker': 'gas stove',
    'induction': 'induction cooktop',

    // TV/Monitor
    'television': 'tv',
    'flat screen': 'tv',

    // Phone
    'cellular phone': 'mobile phone',

    // Plants (specific terms only)
    'houseplant': 'potted plant',
    'succulent': 'potted plant',
    'bonsai': 'potted plant',

    // Lighting
    'chandelier': 'chandelier',
    'diya': 'diya',
    'lantern': 'lantern',

    // AC / Fan
    'ceiling fan': 'ceiling fan',
    'air conditioner': 'air conditioner',

    // Doors
    'doorway': 'door',
    'entrance': 'door',
    'gateway': 'gate',

    // Bathroom
    'bathtub': 'bathtub',
    'washbasin': 'sink',
    'commode': 'toilet',

    // Art
    'artwork': 'painting',
    'wall art': 'painting',
    'canvas': 'painting',

    // Waste
    'garbage': 'dustbin',
    'trash can': 'dustbin',
    'waste bin': 'dustbin',

    // Washing
    'washer': 'washing machine',
    'dryer': 'dryer',

    // Misc
    'timepiece': 'clock',
    'looking glass': 'mirror',
    'water filter': 'water purifier',
    'water dispenser': 'water dispenser',
  };

  // Precise labels we trust directly — no need to remap
  static const Set<String> _preciseLabels = {
    'sofa', 'bed', 'chair', 'table', 'wardrobe', 'tv', 'television',
    'refrigerator', 'oven', 'sink', 'toilet', 'laptop', 'clock',
    'potted plant', 'mirror', 'painting', 'door', 'window', 'fan',
    'washing machine', 'air conditioner', 'dustbin', 'lamp', 'bookshelf',
    'shoe rack', 'safe', 'gate', 'motorcycle', 'bicycle', 'car', 'truck',
    'phone', 'mobile phone', 'remote', 'keyboard', 'mouse', 'cup', 'mug',
    'water purifier', 'gas stove', 'stove', 'microwave', 'bottle',
    'dining table', 'armchair', 'curtain', 'carpet', 'rug', 'pillow',
    'room door', 'main entrance door', 'kitchen door', 'bathroom door',
    'camera', 'bag', 'backpack', 'umbrella', 'vase', 'scissors',
    'teddy bear', 'book', 'ball', 'toothbrush', 'hair dryer',
    'skateboard', 'surfboard', 'tennis racket', 'baseball bat',
    'wine glass', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple',
    'sandwich', 'orange', 'pizza', 'donut', 'cake', 'hot dog',
    'couch', 'desk', 'monitor', 'printer',
    'chandelier', 'diya', 'lantern', 'ottoman', 'bathtub',
    'ceiling fan', 'induction cooktop', 'dryer', 'water dispenser',
  };

  Future<void> initialize({bool forceDemoMode = false}) async {
    final options = ml.ObjectDetectorOptions(
      mode: ml.DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _detector = ml.ObjectDetector(options: options);

    // Lower threshold to catch more labels
    final labelOptions = lbl.ImageLabelerOptions(confidenceThreshold: 0.25);
    _labeler = lbl.ImageLabeler(options: labelOptions);

    _isDemoMode = false;
    _isModelLoaded = true;
    debugPrint('AR_DETECT: Detector Initialized (honest labeling — no guessing)');
    notifyListeners();
  }

  /// Process an input image from Flutter camera stream.
  Future<void> processInputImage(ml.InputImage inputImage) async {
    if (_isProcessing) return;
    if (_geminiObjects.isNotEmpty) return; // Gemini has priority

    _isProcessing = true;
    try {
      final objects = await _detector.processImage(inputImage);
      _framesProcessed++;
      _lastError = '';

      // Layer 2: Image Labeler — get ALL scene labels
      final labels = await _labeler.processImage(inputImage);
      final sceneLabels = labels
          .where((l) => l.confidence > 0.25)
          .map((l) => MapEntry(l.label.toLowerCase(), l.confidence))
          .toList();

      if (_framesProcessed % 60 == 0) {
        debugPrint('AR_DETECT: Frame #$_framesProcessed — ${objects.length} objects, ${sceneLabels.length} labels');
        if (sceneLabels.isNotEmpty) {
          debugPrint('AR_LABELS: ${sceneLabels.take(10).map((e) => "${e.key}(${(e.value * 100).toInt()}%)").join(", ")}');
        }
      }

      // Prune stale tracking
      final now = DateTime.now();
      _trackingState.removeWhere((_, s) => now.difference(s.lastSeen).inSeconds > 3);

      if (objects.isNotEmpty) {
        final List<DetectedObject> allObjects = [];
        double imgWidth = inputImage.metadata?.size.width ?? 720;
        double imgHeight = inputImage.metadata?.size.height ?? 1280;

        final rotation = inputImage.metadata?.rotation ?? ml.InputImageRotation.rotation0deg;
        if (rotation == ml.InputImageRotation.rotation90deg ||
            rotation == ml.InputImageRotation.rotation270deg) {
          final temp = imgWidth;
          imgWidth = imgHeight;
          imgHeight = temp;
        }

        for (int i = 0; i < objects.length; i++) {
          final obj = objects[i];
          final rect = obj.boundingBox;

          // Get raw label from ML Kit Object Detector
          String rawLabel = '';
          double confidence = 0.5;
          if (obj.labels.isNotEmpty) {
            rawLabel = obj.labels.first.text.toLowerCase();
            confidence = obj.labels.first.confidence;
          }

          // Resolve label HONESTLY — no guessing
          final resolvedLabel = _resolveLabelHonestly(rawLabel, sceneLabels);

          final trackingId = obj.trackingId ?? i;
          // Temporal smoothing
          final state = _trackingState.putIfAbsent(trackingId, () => _TrackedState());
          state.vote(resolvedLabel, confidence);
          final finalLabel = state.bestLabel;
          final finalConf = state.bestConfidence;

          allObjects.add(DetectedObject.fromML(
            label: finalLabel,
            confidence: finalConf,
            boundingBox: Rect.fromLTWH(
              rect.left / imgWidth, rect.top / imgHeight,
              rect.width / imgWidth, rect.height / imgHeight,
            ),
            trackingId: trackingId,
          ));
        }
        _detectedObjects = [...allObjects, ..._manualObjects];
      } else if (sceneLabels.isNotEmpty) {
        // No bounding boxes but we have labels — create a scene-level detection
        final best = _findBestSceneLabel(sceneLabels);
        if (best != null) {
          _detectedObjects = [
            DetectedObject.fromML(label: best, confidence: 0.7,
              boundingBox: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8), trackingId: -99),
            ..._manualObjects,
          ];
        } else {
          _detectedObjects = [..._manualObjects];
        }
      } else {
        _detectedObjects = [..._manualObjects];
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('AR_ERR: $e');
      _detectedObjects = [..._manualObjects];
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HONEST LABEL RESOLUTION — Never guess, never fabricate
  // ─────────────────────────────────────────────────────────────────────────

  /// Resolves a label HONESTLY. If we can't determine what it is, returns "unknown".
  /// Never maps "object" to random furniture based on shape.
  String _resolveLabelHonestly(String rawLabel, List<MapEntry<String, double>> sceneLabels) {
    final lower = rawLabel.toLowerCase().trim();

    // 1. If ML Kit gave us something precise, trust it
    if (_preciseLabels.contains(lower)) return lower;

    // 2. If it's a known synonym, map it
    final syn = _synonymMap[lower];
    if (syn != null) return syn;

    // 3. Check if any scene label is a precise/known item
    //    Only trust scene labels that are SPECIFIC (not generic categories)
    for (final entry in sceneLabels) {
      final label = entry.key;
      final conf = entry.value;

      // Direct precise match from scene labels
      if (_preciseLabels.contains(label) && conf > 0.4) {
        return label;
      }

      // Known synonym from scene labels
      final sceneSyn = _synonymMap[label];
      if (sceneSyn != null && conf > 0.4) {
        return sceneSyn;
      }
    }

    // 4. ML Kit's coarse categories — map conservatively
    //    These are the ONLY categories ML Kit base model returns:
    //    "Fashion good", "Food", "Home goods", "Place", "Plant"
    if (lower == 'plant') return 'plant';
    if (lower == 'food') return 'food item';
    if (lower == 'fashion good' || lower == 'fashion goods') return 'clothing/accessory';
    if (lower == 'home good' || lower == 'home goods') return 'household item';
    if (lower == 'place') return 'structure';

    // 5. If it's empty or "object" — we genuinely don't know
    //    DO NOT GUESS. Return "unknown".
    if (lower.isEmpty || lower == 'object') {
      return 'unknown';
    }

    // 6. For anything else ML Kit returns, pass through as-is
    return lower;
  }

  /// Find the best specific label from scene labels
  String? _findBestSceneLabel(List<MapEntry<String, double>> sceneLabels) {
    // First pass: look for precise labels
    for (final entry in sceneLabels) {
      if (_preciseLabels.contains(entry.key) && entry.value > 0.5) {
        return entry.key;
      }
    }
    // Second pass: look for synonyms
    for (final entry in sceneLabels) {
      final syn = _synonymMap[entry.key];
      if (syn != null && entry.value > 0.5) {
        return syn;
      }
    }
    return null;
  }

  void stopDetection() {
    _detectedObjects = [..._manualObjects];
    notifyListeners();
  }

  void clear() {
    _detectedObjects = [];
    _manualObjects = [];
    _geminiObjects = [];
    _trackingState.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _detector.close();
    _labeler.close();
    stopDetection();
    super.dispose();
  }
}
