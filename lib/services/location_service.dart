import 'package:flutter/foundation.dart';

/// Service for GPS location data.
/// Provides hemisphere context for advanced Vastu calculations.
class LocationService extends ChangeNotifier {
  double? _latitude;
  double? _longitude;
  bool _isAvailable = false;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isAvailable => _isAvailable;

  /// Whether the user is in the Northern hemisphere.
  bool get isNorthernHemisphere => (_latitude ?? 0) >= 0;

  /// Initialize location service.
  Future<void> initialize() async {
    // Location is supplementary — not critical for core Vastu analysis.
    // Would use geolocator package on real devices.
    _isAvailable = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
