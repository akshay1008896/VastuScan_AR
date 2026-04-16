import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart' as ml;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart' as lbl;

/// Service that handles object detection using Google ML Kit.
///
/// Detects ALL visible objects in every frame and reports them simultaneously.
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

  /// Initialize the ML Kit Object Detector for real-time streaming
  Future<void> initialize({bool forceDemoMode = false}) async {
    // Configure for multiple object detection in stream mode
    final options = ml.ObjectDetectorOptions(
      mode: ml.DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    
    _detector = ml.ObjectDetector(options: options);

    // Initialize Image Labeler with a secondary confidence threshold
    final labelOptions = lbl.ImageLabelerOptions(confidenceThreshold: 0.5);
    _labeler = lbl.ImageLabeler(options: labelOptions);

    _isDemoMode = false;
    _isModelLoaded = true;
    debugPrint('AR_DETECT: Dual Detectors Initialized (Object + Labeling)');
    notifyListeners();
  }

  /// Process an input image directly from the camera stream.
  Future<void> processInputImage(ml.InputImage inputImage) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final objects = await _detector.processImage(inputImage);
      _framesProcessed++;
      _lastError = ''; // Clear previous error

      if (_framesProcessed % 30 == 0) {
        debugPrint('AR_DETECT: Frame #$_framesProcessed — ${objects.length} objects detected');
      }

      if (objects.isNotEmpty) {
        final List<DetectedObject> allObjects = [];
        
        // Image dimensions needed for coordinate normalization
        // We must swap dimensions if the image is rotated 90 or 270 degrees
        // because ML Kit's result Rect is in the rotated image coordinate space
        double imgWidth = inputImage.metadata?.size.width ?? 720;
        double imgHeight = inputImage.metadata?.size.height ?? 1280;
        
        final rotation = inputImage.metadata?.rotation ?? ml.InputImageRotation.rotation0deg;
        if (rotation == ml.InputImageRotation.rotation90deg || 
            rotation == ml.InputImageRotation.rotation270deg) {
          final temp = imgWidth;
          imgWidth = imgHeight;
          imgHeight = temp;
        }

        // 2. RUN IMAGE LABELER (to get high-precision scene labels)
        final labels = await _labeler.processImage(inputImage);
        final topLabels = labels
            .where((l) => l.confidence > 0.6)
            .map((l) => l.label.toLowerCase())
            .toList();

        for (int i = 0; i < objects.length; i++) {
          final obj = objects[i];
          final rect = obj.boundingBox;
          
          // Use the best label available from Object Detector
          String labelText = 'object';
          double confidence = 0.5;

          if (obj.labels.isNotEmpty) {
            labelText = obj.labels.first.text.toLowerCase();
            confidence = obj.labels.first.confidence;
          }

          // HYBRID LOGIC: If ML Kit says "object" or "home good", check if Labeler 
          // found a specific high-confidence item like "sofa" or "painting".
          if (labelText == 'object' || labelText.contains('good')) {
             for (final lblText in topLabels) {
                // If we find a known Vastu-relevant label, prioritize it over "object"
                if (lblText.contains(RegExp(r'sofa|couch|painting|bed|chair|tv|television|table|refrigerator'))) {
                   labelText = lblText;
                   confidence = 0.95; // Boost confidence for manual hybrid match
                   break;
                }
             }
          }

          // Normalize coordinates (0.0 to 1.0)
          allObjects.add(DetectedObject.fromML(
            label: labelText,
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
