import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vastuscan_ar/app.dart';
import 'package:vastuscan_ar/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.init();

  // Lock to portrait mode for best AR experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E27),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const VastuScanApp());
}
