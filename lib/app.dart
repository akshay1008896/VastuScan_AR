import 'package:flutter/material.dart';
import 'package:vastuscan_ar/theme/app_theme.dart';
import 'package:vastuscan_ar/screens/home_screen.dart';
import 'package:vastuscan_ar/screens/vastu_info_screen.dart';
import 'package:vastuscan_ar/screens/history_screen.dart';

/// Root application widget for VastuScan AR.
class VastuScanApp extends StatelessWidget {
  const VastuScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VastuScan AR',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/info': (context) => const VastuInfoScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
