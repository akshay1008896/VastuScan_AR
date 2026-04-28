import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vastuscan_ar/theme/app_colors.dart';

class GlassButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double blurRadius;
  final bool isOutlined;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 60,
    this.width = double.infinity,
    this.borderRadius,
    this.backgroundColor = const Color(0x33FFFFFF), // Transparent white
    this.borderColor = const Color(0x66FFFFFF),
    this.blurRadius = 10.0,
    this.isOutlined = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(20);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: widget.height,
        width: widget.width,
        transform: Matrix4.translationValues(0, _isPressed ? 2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: _isPressed || widget.isOutlined
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: widget.blurRadius, sigmaY: widget.blurRadius),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isOutlined ? Colors.transparent : widget.backgroundColor,
                borderRadius: borderRadius,
                border: Border.all(
                  color: widget.isOutlined ? widget.borderColor.withOpacity(0.8) : widget.borderColor,
                  width: widget.isOutlined ? 2.0 : 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
