import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;

  SettingsService._internal();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String get geminiApiKey => _prefs.getString('geminiApiKey') ?? '';
  bool get isConfigured => geminiApiKey.isNotEmpty;

  Future<void> setGeminiApiKey(String key) async {
    await _prefs.setString('geminiApiKey', key);
  }
}
