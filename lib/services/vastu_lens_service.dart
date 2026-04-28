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
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    debugPrint('GEMINI_LENS: Model initialized (gemini-2.5-flash)');
  }

  /// Sends the image to Gemini and identifies EVERY object with maximum precision.
  Future<List<DetectedObject>> analyzeImage(Uint8List imageBytes) async {
    if (_model == null) {
      initializeModel();
      if (_model == null) {
        throw Exception("API Key not configured");
      }
    }

    final prompt = '''
You are an expert object identifier. Look at this image carefully and identify EVERY distinct real-world object you can see.

STRICT RULES — READ CAREFULLY:
1. ONLY identify what you can ACTUALLY SEE in the image. Do NOT guess or hallucinate objects.
2. Be SPECIFIC with names:
   - NOT "object" → use exact name like "ceiling fan", "table lamp", "coffee mug"
   - NOT "food" → use "banana", "apple", "bread loaf"  
   - NOT "furniture" → use "wooden desk", "office chair", "bookshelf"
   - NOT "electronics" → use "laptop", "smartphone", "LED TV"
3. Common household items to look for: ceiling fan, table fan, pedestal fan, wall clock, photo frame, mirror, curtain, sofa, dining table, chair, bed, pillow, wardrobe, almirah, TV, AC, refrigerator, washing machine, microwave, gas stove, water purifier, shoe rack, doormat, plant pot, lamp, bulb, tube light
4. For Indian/cultural items: brass diya, pooja thali, Ganesha idol, tulsi plant, kalash, agarbatti holder, rangoli, toran, swastik, rudraksha
5. For crystals/stones: pyrite, amethyst, rose quartz, citrine, black tourmaline, tiger eye
6. A ceiling fan is a FAN not a cake. A ball is a BALL not a mobile. Be precise about shape vs function.
7. Doors, windows, and structural elements should also be identified: "wooden door", "glass window", "main entrance door"

For each object, estimate its bounding box in the image as normalized coordinates (0.0 to 1.0).
Return ONLY a valid JSON array:
[
  {"label": "exact name", "ymin": 0.0, "xmin": 0.0, "ymax": 1.0, "xmax": 1.0}
]
If no objects found, return: []
''';

    // Always send as image/jpeg for best compatibility
    // If it's BMP, note that Gemini should still handle it
    String mimeType = 'image/jpeg';
    if (imageBytes.length > 2 && imageBytes[0] == 0x42 && imageBytes[1] == 0x4D) {
      mimeType = 'image/bmp';
    } else if (imageBytes.length > 4 && imageBytes[0] == 0x89 && imageBytes[1] == 0x50) {
      mimeType = 'image/png';
    }

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
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
      
      int idCounter = 1000;
      
      for (var item in jsonList) {
        final double ymin = (item['ymin'] as num).toDouble().clamp(0.0, 1.0);
        final double xmin = (item['xmin'] as num).toDouble().clamp(0.0, 1.0);
        final double ymax = (item['ymax'] as num).toDouble().clamp(0.0, 1.0);
        final double xmax = (item['xmax'] as num).toDouble().clamp(0.0, 1.0);
        
        String label = item['label'].toString().toLowerCase().trim();
        // Skip generic/useless labels
        if (label == 'object' || label == 'unknown' || label.isEmpty) continue;
        
        // Convert object_code to Title Case (e.g. dining_table -> Dining Table)
        label = label.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

        objects.add(DetectedObject.fromML(
          label: label,
          confidence: 0.95,
          boundingBox: Rect.fromLTRB(xmin, ymin, xmax, ymax),
          trackingId: idCounter++,
        ));
      }
      
      debugPrint('GEMINI_LENS: Identified ${objects.length} objects: ${objects.map((o) => o.label).join(", ")}');
      return objects;
    } catch (e) {
      debugPrint("Gemini Lens Error: $e");
      rethrow;
    }
  }
}
