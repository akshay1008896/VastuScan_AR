import 'dart:ui';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Represents a detected object from the ML model or manually entered.
class DetectedObject {
  /// Unique tracking ID for this detection (using String for universal compatibility).
  final String id;

  /// Unique tracking ID for backwards compatibility with tracking logic.
  final int trackingId;

  /// COCO label (e.g., "bed", "chair", "oven").
  final String label;

  /// Confidence score (0.0 - 1.0).
  final double confidence;

  /// Bounding box in normalized coordinates (0.0 - 1.0).
  final Rect boundingBox;

  /// Timestamp of detection.
  final DateTime timestamp;

  /// Whether this object was manually entered by the user.
  final bool isManual;

  /// Optional notes for manually entered objects.
  final String? notes;

  const DetectedObject({
    required this.id,
    required this.trackingId,
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.timestamp,
    this.isManual = false,
    this.notes,
  });

  /// Creates a demo object for testing without a real camera.
  factory DetectedObject.demo({
    required String label,
    required Rect boundingBox,
    double confidence = 0.85,
    int trackingId = 0,
    bool isManual = false,
    String? notes,
  }) {
    return DetectedObject(
      id: _uuid.v4(),
      trackingId: trackingId,
      label: label,
      confidence: confidence,
      boundingBox: boundingBox,
      timestamp: DateTime.now(),
      isManual: isManual,
      notes: notes,
    );
  }

  /// Creates a new object with an auto-generated ID from ML tracking data.
  factory DetectedObject.fromML({
    required int trackingId,
    required String label,
    required Rect boundingBox,
    required double confidence,
  }) {
    return DetectedObject(
      id: _uuid.v4(),
      trackingId: trackingId,
      label: label,
      confidence: confidence,
      boundingBox: boundingBox,
      timestamp: DateTime.now(),
      isManual: false,
    );
  }

  /// Creates a manual entry object.
  factory DetectedObject.manual({
    required String label,
    required String? notes,
  }) {
    return DetectedObject(
      id: _uuid.v4(),
      trackingId: -1, // -1 means it's not tracked by the camera
      label: label,
      confidence: 1.0,
      boundingBox: Rect.fromLTWH(0.5, 0.5, 0, 0), // Centered tiny box as it's not visually tied yet
      timestamp: DateTime.now(),
      isManual: true,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingId': trackingId,
      'label': label,
      'confidence': confidence,
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'width': boundingBox.width,
        'height': boundingBox.height,
      },
      'timestamp': timestamp.toIso8601String(),
      'isManual': isManual,
      'notes': notes,
    };
  }

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    final boxData = json['boundingBox'] as Map<String, dynamic>;
    return DetectedObject(
      id: json['id'] as String,
      trackingId: json['trackingId'] as int,
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: Rect.fromLTWH(
        (boxData['left'] as num).toDouble(),
        (boxData['top'] as num).toDouble(),
        (boxData['width'] as num).toDouble(),
        (boxData['height'] as num).toDouble(),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isManual: json['isManual'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  @override
  String toString() =>
      'DetectedObject($label, ${(confidence * 100).toStringAsFixed(0)}%, isMan: $isManual)';
}
