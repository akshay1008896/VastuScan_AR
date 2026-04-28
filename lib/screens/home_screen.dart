import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';
import 'package:vastuscan_ar/screens/scan_screen.dart';
import 'package:vastuscan_ar/screens/floor_plan_screen.dart';
import 'package:vastuscan_ar/screens/polycam_scanner_screen.dart';
import 'package:vastuscan_ar/widgets/glass_button.dart';

/// VastuScan AR Home Screen — Dreamy Pastel Design.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

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
      backgroundColor: AppColors.cream,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.dreamyGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                // ── Dreamy background blobs ─────────────────
                _buildBackgroundBlobs(),
                // ── Main content ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      _buildLogoSection(),
                      const SizedBox(height: 28),
                      _buildFeatureChips(),
                      const Spacer(flex: 2),
                      _buildButtons(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Soft gradient blobs for dreamy background
  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.pastelPeach.withValues(alpha: 0.5),
                  AppColors.pastelPeach.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.pastelLavender.withValues(alpha: 0.35),
                  AppColors.pastelLavender.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 200,
          left: 100,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.pastelPink.withValues(alpha: 0.3),
                  AppColors.pastelPink.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
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
          // ── Circular logo with soft glow ──────────────
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.saffron.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: AppColors.pastelPeach.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                width: 130,
                height: 130,
              ),
            ),
          ),
          const SizedBox(height: 28),
          // App name
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [AppColors.saffronDark, AppColors.saffron, AppColors.gold],
            ).createShader(rect),
            child: const Text(
              'VastuScan AR',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Align Your Space with Ancient Wisdom',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChips() {
    final features = [
      ('🔍', 'AI Detection'),
      ('🧭', 'Compass'),
      ('🚪', 'Entrance'),
      ('📜', 'Vastu Rules'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: features.map((f) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.pastelPeach.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(f.$1, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              f.$2,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // ── Primary CTA ─────────────────────────────────
        _buildPrimaryButton(
          onPressed: () => _handleScanPress(context),
          icon: Icons.qr_code_scanner_rounded,
          label: 'SCAN AREA',
        ),
        // ── Scan House Button (Polycam Mode) ────────
        const SizedBox(height: 12),
        _buildSecondaryButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PolycamScannerScreen())),
          icon: Icons.view_in_ar_rounded,
          label: 'AR HOUSE SCANNER',
          fullWidth: true,
          borderColor: AppColors.compliant,
        ),
        const SizedBox(height: 12),
        // ── Secondary buttons ───────────────────────────────
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                onPressed: () => _handleFloorPlanPress(context),
                icon: Icons.grid_view_rounded,
                label: 'FLOOR PLAN',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSecondaryButton(
                onPressed: () => Navigator.pushNamed(context, '/info'),
                icon: Icons.menu_book_rounded,
                label: 'VASTU INFO',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── History button ──────────────────────────────
        _buildSecondaryButton(
          onPressed: () => Navigator.pushNamed(context, '/history'),
          icon: Icons.history_rounded,
          label: 'HISTORY',
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.pillGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.saffron.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool fullWidth = false,
    Color? borderColor,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor ?? AppColors.pastelPeach.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor ?? AppColors.saffron),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleScanPress(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final cameraStatus = await Permission.camera.request();
    final locationStatus = await Permission.location.request();

    if (!context.mounted) return;

    if (cameraStatus.isGranted) {
      if (!locationStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location denied — compass will use demo mode'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.saffronDark,
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'VastuScan AR needs camera access to detect objects and analyze Vastu compliance. Please enable it in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan objects'),
          duration: Duration(seconds: 3),
          backgroundColor: AppColors.nonCompliant,
        ),
      );
    }
  }

  void _handleFloorPlanPress(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FloorPlanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
