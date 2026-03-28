import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Service that handles object detection using Google ML Kit.
///
/// Detects ALL visible objects in every frame and reports them simultaneously.
class DetectionService extends ChangeNotifier {
  List<DetectedObject> _detectedObjects = [];
  List<DetectedObject> get detectedObjects => _detectedObjects;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  /// Diagnostic: last raw label count from ML Kit
  int _lastRawLabelCount = 0;
  int get lastRawLabelCount => _lastRawLabelCount;

  /// Diagnostic: total frames processed
  int _framesProcessed = 0;
  int get framesProcessed => _framesProcessed;

  /// Diagnostic: last error message
  String _lastError = '';
  String get lastError => _lastError;

  late ImageLabeler _labeler;

  /// Initialize the ML Kit Image Labeler with lowest possible threshold
  Future<void> initialize({bool forceDemoMode = false}) async {
    final options = ImageLabelerOptions(confidenceThreshold: 0.15); // Ultra-low threshold
    _labeler = ImageLabeler(options: options);
    _isDemoMode = false;
    _isModelLoaded = true;
    debugPrint('AR_DETECT: ML Engine Initialized — threshold: 0.15');
    notifyListeners();
  }

  /// Process an input image directly from the camera stream.
  /// Reports ALL detected labels, not just the top one.
  Future<void> processInputImage(InputImage inputImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final labels = await _labeler.processImage(inputImage);
      _framesProcessed++;
      _lastRawLabelCount = labels.length;

      if (_framesProcessed % 30 == 0) {
        debugPrint('AR_DETECT: Frame #$_framesProcessed — ${labels.length} labels detected');
      }

      if (labels.isNotEmpty) {
        // Log ALL labels for diagnostics
        for (var label in labels.take(5)) {
          debugPrint('AR_DETECT: Label: "${label.label}" confidence: ${label.confidence.toStringAsFixed(3)}');
        }

        // Build a DetectedObject for EVERY label above threshold
        // Distribute bounding boxes across the screen so they don't all stack
        final List<DetectedObject> allObjects = [];
        final count = labels.length;

        for (int i = 0; i < count && i < 8; i++) {
          final label = labels[i];

          // Spread bounding boxes in a grid pattern across the screen
          final col = i % 2;
          final row = i ~/ 2;
          final boxW = 0.42;
          final boxH = 0.18;
          final left = 0.05 + col * 0.48;
          final top = 0.15 + row * 0.20;

          allObjects.add(DetectedObject(
            label: label.label.toLowerCase(),
            confidence: label.confidence,
            boundingBox: Rect.fromLTWH(
              left.clamp(0.0, 0.95 - boxW),
              top.clamp(0.0, 0.95 - boxH),
              boxW,
              boxH,
            ),
            trackingId: i,
            timestamp: DateTime.now(),
          ));
        }

        _detectedObjects = allObjects;
        _lastError = '';
      } else {
        _detectedObjects = [];
      }
    } catch (e) {
      debugPrint('AR_DETECT: ML Error: $e');
      _lastError = e.toString();
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
