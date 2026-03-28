import 'dart:ui';

/// Represents a detected object from the ML model.
class DetectedObject {
  /// Unique tracking ID for this detection.
  final int trackingId;

  /// COCO label (e.g., "bed", "chair", "oven").
  final String label;

  /// Confidence score (0.0 - 1.0).
  final double confidence;

  /// Bounding box in normalized coordinates (0.0 - 1.0).
  final Rect boundingBox;

  /// Timestamp of detection.
  final DateTime timestamp;

  const DetectedObject({
    required this.trackingId,
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.timestamp,
  });

  /// Creates a demo object for testing without a real camera.
  factory DetectedObject.demo({
    required String label,
    required Rect boundingBox,
    double confidence = 0.85,
    int trackingId = 0,
  }) {
    return DetectedObject(
      trackingId: trackingId,
      label: label,
      confidence: confidence,
      boundingBox: boundingBox,
      timestamp: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'DetectedObject($label, ${(confidence * 100).toStringAsFixed(0)}%, box: $boundingBox)';
}
