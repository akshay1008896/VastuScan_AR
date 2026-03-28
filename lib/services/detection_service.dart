import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Service that handles object detection using Google ML Kit.
///
/// Automatically recognizes hundreds of generic objects and passes labels to VastuEngine.
class DetectionService extends ChangeNotifier {
  List<DetectedObject> _detectedObjects = [];
  List<DetectedObject> get detectedObjects => _detectedObjects;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  late ImageLabeler _labeler;

  /// COCO labels that map to Vastu-relevant items.
  static const List<String> vastuRelevantLabels = [
    'person', 'bicycle', 'car', 'motorcycle', 'bus', 'truck',
    'bird', 'cat', 'dog',
    'chair', 'couch', 'bed', 'dining table', 'toilet',
    'tv', 'laptop', 'mouse', 'remote', 'keyboard', 'cell phone',
    'microwave', 'oven', 'toaster', 'sink', 'refrigerator',
    'book', 'clock', 'vase', 'potted plant',
    'door', 'window',
  ];

  /// Initialize the ML Kit Image Labeler
  Future<void> initialize({bool forceDemoMode = false}) async {
    final options = ImageLabelerOptions(confidenceThreshold: 0.25); // Maximum sensitivity
    _labeler = ImageLabeler(options: options);
    _isDemoMode = false;
    _isModelLoaded = true;
    debugPrint('AR_V_SCAN: ML Engine Initialized at 0.25 threshold');
    notifyListeners();
  }

  /// Process an input image directly from the camera stream
  Future<void> processInputImage(InputImage inputImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final labels = await _labeler.processImage(inputImage);
      debugPrint('ML Service: Found ${labels.length} labels');

      if (labels.isNotEmpty) {
        // Log top labels with more detail
        for (var label in labels.take(3)) {
          debugPrint('AR_V_SCAN: [Raw AI Data] Label: ${label.label} (${label.confidence.toStringAsFixed(2)})');
        }
        
        // Get the top confident label
        final topLabel = labels.reduce((a, b) => a.confidence > b.confidence ? a : b);
        
        // Emulate bounding box firmly locked in center screen
        final boxSize = 0.4;
        final rect = Rect.fromCenter(
          center: const Offset(0.5, 0.5),
          width: boxSize,
          height: boxSize,
        );
        
        _detectedObjects = [
          DetectedObject(
            label: topLabel.label.toLowerCase(),
            confidence: topLabel.confidence,
            boundingBox: rect,
            trackingId: DateTime.now().millisecondsSinceEpoch,
            timestamp: DateTime.now(),
          )
        ];
      } else {
        // Clear if not scanning, to avoid stale data
        _detectedObjects = [];
      }
    } catch (e) {
      debugPrint('AR_V_SCAN: ML Labeling Error: $e');
      _detectedObjects = [];
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Stop detection.
  void stopDetection() {
    _detectedObjects = [];
    notifyListeners();
  }

  /// Clear all detections.
  void clear() {
    _detectedObjects = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _labeler.close();
    stopDetection();
    super.dispose();
  }
}
