import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';
import 'package:vastuscan_ar/screens/scan_screen.dart';

/// VastuScan AR Home Screen.
///
/// Premium landing page with branding, feature highlights,
/// and the "Start Scan" CTA.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildLogoSection(),
                const SizedBox(height: 48),
                _buildFeatureCards(),
                const SizedBox(height: 40),
                _buildStartButton(context),
                const SizedBox(height: 20),
                _buildInfoText(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Column(
        children: [
          // Animated compass logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.saffron,
                  AppColors.saffronDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.saffron.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.explore,
              size: 52,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          // App name with gradient text
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [AppColors.saffron, AppColors.gold],
            ).createShader(rect),
            child: const Text(
              'VastuScan AR',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Align Your Space with Ancient Wisdom',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards() {
    final features = [
      {
        'icon': Icons.camera_alt_rounded,
        'title': 'Smart Detection',
        'desc': 'AI-powered object detection identifies furniture & elements',
        'color': AppColors.saffron,
      },
      {
        'icon': Icons.explore_rounded,
        'title': 'Live Compass',
        'desc': 'Real-time compass with filtered heading for accuracy',
        'color': AppColors.gold,
      },
      {
        'icon': Icons.assessment_rounded,
        'title': 'Vastu Analysis',
        'desc': '40+ Vastu rules with instant compliance scoring',
        'color': AppColors.compliant,
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Remediation Tips',
        'desc': 'Practical advice to fix non-compliant placements',
        'color': AppColors.elementWater,
      },
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final i = entry.key;
        final f = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + i * 150),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppColors.cardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.glassBorder, width: 1),
              ),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exploring ${f['title']}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.elevatedSurface,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (f['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          f['icon'] as IconData,
                          color: f['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f['title'] as String,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f['desc'] as String,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          HapticFeedback.mediumImpact();

          // Request camera and location permissions
          final cameraStatus = await Permission.camera.request();
          final locationStatus = await Permission.location.request();

          if (!context.mounted) return;

          if (cameraStatus.isGranted) {
            // Camera granted — navigate even if location is denied (compass will use demo mode)
            if (!locationStatus.isGranted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location denied — compass will use demo mode'),
                  duration: Duration(seconds: 2),
                  backgroundColor: AppColors.saffronDark,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ScanScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          } else if (cameraStatus.isPermanentlyDenied) {
            // Show dialog to open settings
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Camera Permission Required',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: const Text(
                  'VastuScan AR needs camera access to detect objects and analyze Vastu compliance. Please enable it in Settings.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.saffron,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Open Settings',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          } else {
            // Denied but not permanently — show snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera permission is required to scan objects'),
                duration: Duration(seconds: 3),
                backgroundColor: AppColors.nonCompliant,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.saffron,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 22),
            SizedBox(width: 10),
            Text(
              'START SCANNING',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.textMuted,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Point your camera at any room. The app will detect objects and evaluate Vastu compliance based on compass direction.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
