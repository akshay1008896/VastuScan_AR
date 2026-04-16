import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:vastuscan_ar/models/detected_object.dart';
import 'package:vastuscan_ar/services/settings_service.dart';

class VastuLensService {
  static final VastuLensService _instance = VastuLensService._internal();
  static VastuLensService get instance => _instance;
  VastuLensService._internal();

  GenerativeModel? _model;
  
  bool get isConfigured => SettingsService.instance.geminiApiKey.isNotEmpty;

  void initializeModel() {
    final apiKey = SettingsService.instance.geminiApiKey;
    if (apiKey.isEmpty) return;
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  /// Sends the image to Gemini 1.5 and retrieves specific items based on a master list
  Future<List<DetectedObject>> analyzeImage(Uint8List imageBytes) async {
    if (_model == null) {
      initializeModel();
      if (_model == null) {
        throw Exception("API Key not configured");
      }
    }

    final prompt = '''
Analyze this image and act as a "Google Lens" specifically tuned for a Vastu Shastra analysis app. 
Identify ALL items in the frame meticulously. Use highly specific names.
Particularly, look for items from this exhaustive master list classification:
- **Kitchen / Cooking:** matka, pooja thali, belan, chakla, gas stove, oven, refrigerator, spices, microwave, idli stand, earthen pot, dining table.
- **Living:** sofa, television, center table, armchair, rug, diwan, urli, shoe rack, clock.
- **Bedroom:** bed, wardrobe, mirror, dressing table, study table, safe locker.
- **Puja / Religion:** diya, idol, kalash, tulsi vrindavan, bell, agarbatti, havan kund, altar.
- **Bathroom/Utilities:** washing machine, toilet, sink, bathtub, dustbin.
- **Structural:** main entrance door, room door, kitchen door, window, staircase, balcony.

For each item found, estimate a 2D bounding box showing its relaitive position.
Return a valid JSON array exactly matching this format. The coordinates MUST be normalized float numbers between 0.0 and 1.0.
[
  {
    "label": "string (the specific item name)",
    "ymin": float (0.0 to 1.0),
    "xmin": float (0.0 to 1.0),
    "ymax": float (0.0 to 1.0),
    "xmax": float (0.0 to 1.0)
  }
]
''';

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    try {
      final response = await _model!.generateContent(content);
      final responseText = response.text;
      
      if (responseText == null || responseText.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(responseText);
      final List<DetectedObject> objects = [];
      
      int idCounter = 1000; // Unique IDs for Gemini objects
      
      for (var item in jsonList) {
        final double ymin = (item['ymin'] as num).toDouble();
        final double xmin = (item['xmin'] as num).toDouble();
        final double ymax = (item['ymax'] as num).toDouble();
        final double xmax = (item['xmax'] as num).toDouble();
        
        objects.add(DetectedObject.fromML(
          label: item['label'].toString().toLowerCase(),
          confidence: 0.95, // High confidence for Cloud AI
          boundingBox: Rect.fromLTRB(xmin, ymin, xmax, ymax),
          trackingId: idCounter++,
        ));
      }
      return objects;
    } catch (e) {
      debugPrint("Vastu Lens Error: \$e");
      rethrow;
    }
  }
}
