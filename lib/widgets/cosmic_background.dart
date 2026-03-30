import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  CosmicBackground – shared dark theme wrapper
// ─────────────────────────────────────────────

class CosmicBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;

  const CosmicBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF080F1E),
            Color(0xFF0A1628),
            Color(0xFF0D1F4C),
            Color(0xFF0A1628),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          if (widget.showParticles)
            ...List.generate(18, (i) => _buildParticle(i, size)),
          widget.child,
        ],
      ),
    );
  }

  Widget _buildParticle(int index, Size size) {
    final random = math.Random(index * 53 + 7);
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final sz = random.nextDouble() * 2.5 + 0.8;
    final delay = random.nextDouble();

    return AnimatedBuilder(
      animation: _particleController,
      builder: (_, __) {
        final t = ((_particleController.value + delay) % 1.0);
        final opacity = (math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.55;
        final yOffset = -30.0 * t;
        return Positioned(
          left: x,
          top: y + yOffset,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: sz,
              height: sz,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index % 3 == 0
                    ? AppTheme.accentYellow
                    : index % 3 == 1
                        ? Colors.white
                        : AppTheme.primaryLight,
                boxShadow: [
                  BoxShadow(
                    color: (index % 3 == 0 ? AppTheme.accentYellow : Colors.white)
                        .withOpacity(0.7),
                    blurRadius: 3,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────

/// Dark glass card
class CosmicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final double opacity;

  const CosmicCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.borderColor,
    this.opacity = 0.07,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.13),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Cosmic AppBar — returns a PreferredSizeWidget-compatible style config
PreferredSizeWidget cosmicAppBar({
  required String title,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
  Color? leadingIconColor,
  BuildContext? context,
  Widget? bottom,
  double bottomHeight = 0,
  VoidCallback? onLeadingPressed,
}) {
  return AppBar(
    elevation: 0,
    backgroundColor: const Color(0xFF080F1E),
    automaticallyImplyLeading: automaticallyImplyLeading,
    leading: automaticallyImplyLeading && onLeadingPressed != null
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onLeadingPressed,
          )
        : null,
    iconTheme: const IconThemeData(color: Colors.white),
    centerTitle: true,
    title: ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFFCD116)],
      ).createShader(bounds),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    ),
    actions: actions,
    bottom: bottom as PreferredSizeWidget?,
  );
}

/// Dark text field style
InputDecoration cosmicInputDecoration({
  required String hint,
  IconData? prefixIcon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
    filled: true,
    fillColor: Colors.white.withOpacity(0.07),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: Colors.white.withOpacity(0.5))
        : null,
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.accentYellow, width: 1.5),
    ),
  );
}
