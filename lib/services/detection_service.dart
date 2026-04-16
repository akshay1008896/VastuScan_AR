import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart' as ml;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart' as lbl;

/// Service that handles object detection using Google ML Kit.
///
/// Uses a 3-layer resolution pipeline:
///   Layer 1: ML Kit Object Detector — bounding boxes + coarse category
///   Layer 2: ML Kit Image Labeler — 450+ scene-level labels
///   Layer 3: Vastu synonym mapper — maps generic labels to precise named items
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

  /// Diagnostic: total frames processed
  int _framesProcessed = 0;
  int get framesProcessed => _framesProcessed;

  /// Diagnostic: last error message
  String _lastError = '';
  String get lastError => _lastError;

  late ml.ObjectDetector _detector;
  late lbl.ImageLabeler _labeler;

  // ─────────────────────────────────────────────────────────────────────────
  // LAYER 3: Synonym / Semantic Mapper
  // Maps generic ML Kit labels → precise Vastu-relevant item names
  // ─────────────────────────────────────────────────────────────────────────
  static const Map<String, String> _synonymMap = {
    // Furniture generics
    'furniture': 'sofa',
    'home good': 'sofa',
    'home goods': 'sofa',
    'household goods': 'wardrobe',
    'indoor furniture': 'chair',
    'wood': 'furniture',
    'wooden furniture': 'wardrobe',

    // Seating
    'seat': 'chair',
    'seating': 'chair',
    'couch': 'sofa',
    'settee': 'sofa',
    'loveseat': 'sofa',
    'sofa set': 'sofa',
    'armchair': 'armchair',
    'recliner': 'armchair',
    'ottoman': 'sofa',
    'bean bag': 'sofa',

    // Bed/Sleep
    'mattress': 'bed',
    'bedding': 'bed',
    'pillow': 'bed',
    'blanket': 'bed',
    'duvet': 'bed',
    'bedsheet': 'bed',

    // Storage
    'cabinet': 'wardrobe',
    'cupboard': 'wardrobe',
    'closet': 'wardrobe',
    'dresser': 'wardrobe',
    'chest': 'wardrobe',
    'drawers': 'wardrobe',
    'chest of drawers': 'wardrobe',
    'armoire': 'wardrobe',
    'almirah': 'wardrobe',
    'shelf': 'bookshelf',
    'shelving': 'bookshelf',
    'bookcase': 'bookshelf',
    'book': 'bookshelf',
    'bookstand': 'bookshelf',

    // Kitchen
    'appliance': 'oven',
    'home appliance': 'oven',
    'kitchen appliance': 'oven',
    'household appliance': 'washing machine',
    'cooking': 'stove',
    'cooktop': 'gas stove',
    'burner': 'gas stove',
    'cooker': 'gas stove',
    'pressure cooker': 'gas stove',
    'induction': 'induction cooktop',
    'toaster oven': 'oven',
    'countertop': 'kitchen',
    'kitchen counter': 'kitchen',

    // Electronics / Tech
    'technology': 'laptop',
    'electronic device': 'laptop',
    'gadget': 'laptop',
    'electronics': 'laptop',
    'device': 'smartphone',
    'screen': 'tv',
    'display': 'tv',
    'flat screen': 'tv',
    'monitor': 'tv',
    'computer monitor': 'tv',
    'personal computer': 'computer',
    'desktop': 'computer',
    'tablet': 'laptop',
    'ipad': 'laptop',
    'smartphone': 'mobile phone',
    'mobile': 'mobile phone',
    'cellular phone': 'mobile phone',
    'charger': 'mobile phone',
    'router': 'computer',
    'wifi router': 'computer',
    'remote control': 'remote',

    // Plants
    'plant': 'potted plant',
    'indoor plant': 'potted plant',
    'houseplant': 'potted plant',
    'succulent': 'potted plant',
    'cactus': 'potted plant',
    'flower': 'potted plant',
    'flower pot': 'potted plant',
    'bonsai': 'potted plant',
    'flower arrangement': 'potted plant',

    // Lighting / Electric
    'light': 'lamp',
    'lighting': 'lamp',
    'light fixture': 'lamp',
    'ceiling light': 'lamp',
    'bulb': 'lamp',
    'chandelier': 'lamp',
    'wall light': 'lamp',
    'diya': 'lamp',
    'candle': 'lamp',
    'lantern': 'lamp',
    'tube light': 'lamp',

    // AC / Fan
    'fan': 'fan',
    'ceiling fan': 'fan',
    'table fan': 'fan',
    'pedestal fan': 'fan',
    'air conditioner': 'air conditioner',
    'ac': 'air conditioner',
    'air cooler': 'air conditioner',
    'cooler': 'air conditioner',
    'exhaust fan': 'fan',

    // Vehicles
    'vehicle': 'car',
    'auto': 'motorcycle',
    'automobile': 'car',
    'transport': 'car',
    'scooter': 'motorcycle',
    'bike': 'bicycle',
    'two-wheeler': 'motorcycle',
    'van': 'car',
    'suv': 'car',

    // Doors & Entrances
    'doorway': 'door',
    'entrance': 'door',
    'archway': 'door',
    'arch': 'door',
    'gate': 'gate',
    'gateway': 'gate',
    'exit': 'door',
    'portal': 'door',

    // Bathroom
    'bathroom fixture': 'toilet',
    'sanitary ware': 'toilet',
    'bathtub': 'toilet',
    'shower': 'toilet',
    'washbasin': 'sink',
    'hand wash': 'sink',

    // Art & Decor
    'picture': 'painting',
    'artwork': 'painting',
    'wall art': 'painting',
    'photo frame': 'painting',
    'picture frame': 'painting',
    'canvas': 'painting',
    'poster': 'painting',
    'print': 'painting',
    'wall decor': 'painting',
    'decoration': 'painting',
    'decorative item': 'potted plant',
    'figurine': 'potted plant',

    // Window
    'glass': 'window',
    'window pane': 'window',
    'skylight': 'window',

    // Waste
    'garbage': 'dustbin',
    'trash': 'dustbin',
    'waste': 'dustbin',
    'bin': 'dustbin',
    'recycle bin': 'dustbin',
    'rubbish': 'dustbin',

    // Washing
    'laundry': 'washing machine',
    'washer': 'washing machine',
    'dryer': 'washing machine',
    'clothes washer': 'washing machine',

    // Misc household
    'rug': 'rug',
    'carpet': 'carpet',
    'curtain': 'curtain',
    'blind': 'curtain',
    'drape': 'curtain',
    'mat': 'rug',
    'place mat': 'rug',
    'clock': 'clock',
    'timepiece': 'clock',
    'wristwatch': 'clock',
    'mirror': 'mirror',
    'looking glass': 'mirror',
    'alarm': 'clock',
    'wall clock': 'clock',
    'safe': 'safe',
    'locker': 'safe',
    'vault': 'safe',
    'shoes': 'shoe rack',
    'footwear': 'shoe rack',
    'sandals': 'shoe rack',
    'slippers': 'shoe rack',
    'shoe rack': 'shoe rack',
    'shoe cabinet': 'shoe rack',
    'water purifier': 'water purifier',
    'water filter': 'water purifier',
    'ro system': 'water purifier',
    'water dispenser': 'water purifier',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Door classification keywords
  // ─────────────────────────────────────────────────────────────────────────
  static const List<String> _doorKeywords = [
    'door', 'doorway', 'entrance', 'entrance door', 'exit', 'gate',
    'gateway', 'archway', 'arch', 'portal', 'opening', 'hatchway',
  ];

  /// Initialize the ML Kit Object Detector for real-time streaming
  Future<void> initialize({bool forceDemoMode = false}) async {
    // Configure for multiple object detection in stream mode
    final options = ml.ObjectDetectorOptions(
      mode: ml.DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );

    _detector = ml.ObjectDetector(options: options);

    // Layer 2: Image Labeler with lower threshold to catch more specific items
    final labelOptions = lbl.ImageLabelerOptions(confidenceThreshold: 0.35);
    _labeler = lbl.ImageLabeler(options: labelOptions);

    _isDemoMode = false;
    _isModelLoaded = true;
    debugPrint('AR_DETECT: 3-Layer Detector Initialized (Object + Labeling + Synonym Map)');
    notifyListeners();
  }

  /// Process an input image directly from the camera stream.
  Future<void> processInputImage(ml.InputImage inputImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Layer 1: Object Detector — gives bounding boxes
      final objects = await _detector.processImage(inputImage);
      _framesProcessed++;
      _lastError = '';

      if (_framesProcessed % 30 == 0) {
        debugPrint('AR_DETECT: Frame #$_framesProcessed — ${objects.length} objects detected');
      }

      // Layer 2: Image Labeler — rich scene-level labels
      final labels = await _labeler.processImage(inputImage);
      final sceneLabels = labels
          .where((l) => l.confidence > 0.35)
          .map((l) => l.label.toLowerCase())
          .toList();

      if (_framesProcessed % 60 == 0 && sceneLabels.isNotEmpty) {
        debugPrint('AR_DETECT: Scene labels: ${sceneLabels.take(8).join(", ")}');
      }

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

        final imageSize = Size(imgWidth, imgHeight);

        for (int i = 0; i < objects.length; i++) {
          final obj = objects[i];
          final rect = obj.boundingBox;

          // Layer 1 result
          String rawLabel = 'object';
          double confidence = 0.5;

          if (obj.labels.isNotEmpty) {
            rawLabel = obj.labels.first.text.toLowerCase();
            confidence = obj.labels.first.confidence;
          }

          // Layer 3: Resolve to a specific Vastu-relevant label
          final resolvedLabel = _resolveLabel(
            rawLabel,
            sceneLabels,
            Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height),
            imageSize,
          );

          if (resolvedLabel != rawLabel) {
            confidence = (confidence * 1.15).clamp(0.0, 1.0);
            debugPrint('AR_RESOLVE: "$rawLabel" → "$resolvedLabel" (scene: ${sceneLabels.take(3).join(", ")})');
          }

          // Normalize coordinates
          allObjects.add(DetectedObject.fromML(
            label: resolvedLabel,
            confidence: confidence,
            boundingBox: Rect.fromLTWH(
              rect.left / imgWidth,
              rect.top / imgHeight,
              rect.width / imgWidth,
              rect.height / imgHeight,
            ),
            trackingId: obj.trackingId ?? i,
          ));
        }

        _detectedObjects = [...allObjects, ..._manualObjects];
      } else if (sceneLabels.isNotEmpty) {
        // Even without bounding boxes, create a scene-level detection if we
        // see a high-confidence specific item label (helps for close-up scans)
        final scenePrecise = _findBestSceneLabel(sceneLabels);
        if (scenePrecise != null) {
          final sceneObj = DetectedObject.fromML(
            label: scenePrecise,
            confidence: 0.75,
            boundingBox: const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
            trackingId: -99,
          );
          _detectedObjects = [sceneObj, ..._manualObjects];
        } else {
          _detectedObjects = [..._manualObjects];
        }
      } else {
        _detectedObjects = [..._manualObjects];
      }
    } catch (e) {
      _lastError = e.toString();
      debugPrint('AR_CRITICAL_ERR: ML processing failed: $_lastError');
      _detectedObjects = [..._manualObjects];
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LAYER 3 IMPLEMENTATION: Multi-step label resolver
  // ─────────────────────────────────────────────────────────────────────────

  /// Resolves a raw ML label to the best possible Vastu-specific label using
  /// the synonym map, scene context, and spatial/aspect-ratio heuristics.
  String _resolveLabel(
    String rawLabel,
    List<String> sceneLabels,
    Rect boundingBox,
    Size imageSize,
  ) {
    final lower = rawLabel.toLowerCase().trim();

    // Step 1: Check if it's already a precise label (in synonym map values or vastu_rules labels)
    if (_isPreciseLabel(lower)) return lower;

    // Step 2: Check synonym map for direct match
    final synMatch = _synonymMap[lower];
    if (synMatch != null) return synMatch;

    // Step 3: Check partial match in synonym keys
    for (final entry in _synonymMap.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    // Step 4: Check scene labels for more precise information
    for (final sceneLabel in sceneLabels) {
      // Direct synonym hit from scene labels
      final sceneSyn = _synonymMap[sceneLabel];
      if (sceneSyn != null && sceneSyn != 'sofa') return sceneSyn; // avoid generic default

      // Check specific vastu-relevant keywords in scene labels
      final vastu = _extractVastuLabelFromScene(sceneLabel, sceneLabels, boundingBox, imageSize);
      if (vastu != null) return vastu;
    }

    // Step 5: Door-specific spatial context
    if (_isDoorLike(lower, sceneLabels)) {
      return _classifyDoorContext(boundingBox, imageSize);
    }

    // Step 6: Aspect-ratio heuristics for ambiguous furniture labels
    if (lower.contains('furniture') || lower.contains('home good') || lower == 'object') {
      return _resolveFurnitureByAspectRatio(boundingBox, sceneLabels);
    }

    // Step 7: Appliance heuristics
    if (lower.contains('appliance') || lower.contains('machine')) {
      return _resolveApplianceFromScene(sceneLabels);
    }

    return lower == 'object' ? _resolveFurnitureByAspectRatio(boundingBox, sceneLabels) : lower;
  }

  /// Returns true if [label] is already a specific, recognizable Vastu item.
  bool _isPreciseLabel(String label) {
    const preciseLabels = {
      'sofa', 'bed', 'chair', 'table', 'wardrobe', 'tv', 'television',
      'refrigerator', 'oven', 'sink', 'toilet', 'laptop', 'clock',
      'potted plant', 'mirror', 'painting', 'door', 'window', 'fan',
      'washing machine', 'air conditioner', 'dustbin',
      'lamp', 'bookshelf', 'shoe rack', 'safe', 'gate', 'motorcycle',
      'bicycle', 'car', 'phone', 'mobile phone', 'remote', 'keyboard',
      'mouse', 'water purifier', 'gas stove', 'stove', 'microwave',
      'dining table', 'armchair', 'curtain', 'carpet', 'rug',
      'room door', 'main entrance door', 'kitchen door', 'bathroom door',
    };
    return preciseLabels.contains(label);
  }

  /// Extracts a Vastu-relevant label from a scene-level label string.
  String? _extractVastuLabelFromScene(
      String sceneLabel, List<String> allSceneLabels, Rect boundingBox, Size imageSize) {
    final s = sceneLabel.toLowerCase();

    if (s.contains('sofa') || s.contains('couch') || s.contains('settee')) return 'sofa';
    if (s.contains('arm chair') || s.contains('armchair') || s.contains('recliner')) return 'armchair';
    if (s.contains('bed') && !s.contains('bedroom')) return 'bed';
    if (s.contains('wardrobe') || s.contains('almirah') || s.contains('cupboard') || s.contains('closet')) return 'wardrobe';
    if (s.contains('bookshelf') || s.contains('bookcase')) return 'bookshelf';
    if (s.contains('table') && s.contains('dining')) return 'dining table';
    if (s.contains('coffee table')) return 'coffee table';
    if (s.contains('refrigerator') || s.contains('fridge')) return 'refrigerator';
    if (s.contains('microwave') || s.contains('oven')) return 'oven';
    if (s.contains('washing machine') || s.contains('washer')) return 'washing machine';
    if (s.contains('fan') && !s.contains('fanatic')) return 'fan';
    if (s.contains('air conditioner') || s.contains(' ac ') || s == 'ac') return 'air conditioner';
    if (s.contains('television') || s.contains(' tv ') || s == 'tv') return 'tv';
    if (s.contains('laptop') || s.contains('notebook computer')) return 'laptop';
    if (s.contains('smartphone') || s.contains('mobile') || s.contains('cell phone')) return 'mobile phone';
    if (s.contains('computer')) return 'computer';
    if (s.contains('toilet') || s.contains('commode') || s.contains('w.c')) return 'toilet';
    if (s.contains('sink') || s.contains('washbasin')) return 'sink';
    if (s.contains('bathtub') || s.contains('bath tub')) return 'toilet';
    if (s.contains('mirror')) return 'mirror';
    if (s.contains('clock') || s.contains('timepiece')) return 'clock';
    if (s.contains('plant') || s.contains('flower pot') || s.contains('succulent')) return 'potted plant';
    if (s.contains('painting') || s.contains('artwork') || s.contains('wall art')) return 'painting';
    if (s.contains('window')) return 'window';
    if (s.contains('lamp') || s.contains('chandelier') || s.contains('light fixture')) return 'lamp';
    if (s.contains('shoe') || s.contains('footwear')) return 'shoe rack';
    if (s.contains('dustbin') || s.contains('trash') || s.contains('garbage bin')) return 'dustbin';
    if (s.contains('safe') || s.contains('vault')) return 'safe';
    if (s.contains('door') || s.contains('doorway') || s.contains('entrance')) {
      return _classifyDoorContext(boundingBox, imageSize);
    }
    if (s.contains('stair') || s.contains('steps')) return 'staircase';
    if (s.contains('water purifier') || s.contains('ro system')) return 'water purifier';
    if (s.contains('gas stove') || s.contains('cooking range') || s.contains('induction')) return 'gas stove';
    if (s.contains('curtain') || s.contains('drape') || s.contains('blind')) return 'curtain';
    if (s.contains('carpet') || s.contains('rug') || s.contains('mat')) return 'carpet';
    if (s.contains('pillow') || s.contains('cushion')) return 'pillow';

    return null;
  }

  /// Checks if the raw label + scene context indicates a door.
  bool _isDoorLike(String label, List<String> sceneLabels) {
    if (_doorKeywords.any((kw) => label.contains(kw))) return true;
    return sceneLabels.any((sl) => _doorKeywords.any((kw) => sl.contains(kw)));
  }

  /// Classifies a detected door as main entrance, room door, kitchen door, or bathroom door
  /// based on its spatial position and size relative to the frame.
  String _classifyDoorContext(Rect boundingBox, Size imageSize) {
    final boxWidthFraction = boundingBox.width / imageSize.width;
    final boxHeightFraction = boundingBox.height / imageSize.height;
    final centerX = (boundingBox.left + boundingBox.width / 2) / imageSize.width;
    final centerY = (boundingBox.top + boundingBox.height / 2) / imageSize.height;

    // Very large door occupying most of the frame → main entrance
    if (boxWidthFraction > 0.55 && boxHeightFraction > 0.65) {
      return 'main entrance door';
    }

    // Large door, centered → front door / main door
    if (boxWidthFraction > 0.35 && boxHeightFraction > 0.50 &&
        centerX > 0.25 && centerX < 0.75) {
      return 'main entrance door';
    }

    // Smaller door in upper-center area → interior room door
    if (boxHeightFraction > 0.30 && centerY < 0.60) {
      return 'room door';
    }

    // Default
    return 'door';
  }

  /// Resolves ambiguous furniture labels using bounding box aspect ratio.
  /// Tall narrow boxes = wardrobe; wide short boxes = sofa/bed; roughly square = chair/table
  String _resolveFurnitureByAspectRatio(Rect boundingBox, List<String> sceneLabels) {
    // First check scene labels for clues
    for (final sl in sceneLabels) {
      final vastu = _extractVastuLabelFromScene(sl, sceneLabels, boundingBox, const Size(1, 1));
      if (vastu != null) return vastu;
    }

    final aspect = boundingBox.width / (boundingBox.height == 0 ? 1 : boundingBox.height);

    if (aspect < 0.6) {
      // Tall narrow: wardrobe, bookshelf, door, fridge
      return 'wardrobe';
    } else if (aspect > 2.5) {
      // Very wide: bed, sofa, dining table
      return 'sofa';
    } else if (aspect > 1.5) {
      // Wide: sofa, dining table
      return 'sofa';
    } else {
      // Square-ish: chair, TV, appliance
      return 'chair';
    }
  }

  /// Resolves appliance label from scene context.
  String _resolveApplianceFromScene(List<String> sceneLabels) {
    for (final sl in sceneLabels) {
      if (sl.contains('wash') || sl.contains('laundry')) return 'washing machine';
      if (sl.contains('cook') || sl.contains('oven') || sl.contains('stove')) return 'oven';
      if (sl.contains('fridge') || sl.contains('refrigerator')) return 'refrigerator';
      if (sl.contains('fan')) return 'fan';
      if (sl.contains('ac') || sl.contains('condition')) return 'air conditioner';
    }
    return 'washing machine'; // default appliance
  }

  /// Finds the best single scene label that represents a known Vastu item.
  String? _findBestSceneLabel(List<String> sceneLabels) {
    for (final sl in sceneLabels) {
      final vastu = _extractVastuLabelFromScene(sl, sceneLabels, const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8), const Size(720, 1280));
      if (vastu != null) return vastu;
      final syn = _synonymMap[sl];
      if (syn != null) return syn;
    }
    return null;
  }

  /// Stop detection.
  void stopDetection() {
    _detectedObjects = [..._manualObjects];
    notifyListeners();
  }

  /// Clear all detections.
  void clear() {
    _detectedObjects = [];
    _manualObjects = [];
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
