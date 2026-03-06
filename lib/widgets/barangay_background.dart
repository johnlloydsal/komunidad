import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

/// Professional transparent background with barangay-themed elements
class BarangayBackground extends StatelessWidget {
  final Widget child;
  final bool showPattern;
  final bool showGradient;
  
  const BarangayBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        if (showGradient)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.05),
                  Colors.white,
                  AppTheme.accentYellow.withOpacity(0.03),
                ],
              ),
            ),
          )
        else
          Container(color: AppTheme.backgroundColor),
        
        // Philippine Flag-inspired stripes (very subtle)
        if (showPattern) ...[
          Positioned(
            top: -100,
            right: -50,
            child: Transform.rotate(
              angle: math.pi / 6,
              child: Container(
                width: 300,
                height: 800,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Container(
                width: 300,
                height: 800,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentRed.withOpacity(0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Subtle geometric patterns
          Positioned.fill(
            child: CustomPaint(
              painter: BarangayPatternPainter(),
            ),
          ),
        ],
        
        // Content
        child,
      ],
    );
  }
}

/// Animated background with floating elements
class AnimatedBarangayBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedBarangayBackground({
    super.key,
    required this.child,
  });

  @override
  State<AnimatedBarangayBackground> createState() => _AnimatedBarangayBackgroundState();
}

class _AnimatedBarangayBackgroundState extends State<AnimatedBarangayBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.08 + _controller.value * 0.02),
                    Colors.white,
                    AppTheme.accentYellow.withOpacity(0.05 + _controller.value * 0.02),
                    AppTheme.primaryLight.withOpacity(0.03),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            );
          },
        ),
        
        // Floating circles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: FloatingElementsPainter(
                animation: _controller.value,
              ),
              child: Container(),
            );
          },
        ),
        
        // Content
        widget.child,
      ],
    );
  }
}

/// Glassmorphism container for modern UI
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Barangay-themed pattern painter
class BarangayPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primaryColor.withOpacity(0.02);

    // Draw subtle circles representing community unity
    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.2 + i * 0.15);
      final y = size.height * (0.3 + (i % 2) * 0.4);
      canvas.drawCircle(
        Offset(x, y),
        40.0 + i * 10.0,
        paint,
      );
    }

    // Draw connecting lines (community network)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    paint.color = AppTheme.accentYellow.withOpacity(0.05);
    
    for (int i = 0; i < 4; i++) {
      final x1 = size.width * (0.2 + i * 0.15);
      final y1 = size.height * (0.3 + (i % 2) * 0.4);
      final x2 = size.width * (0.2 + (i + 1) * 0.15);
      final y2 = size.height * (0.3 + ((i + 1) % 2) * 0.4);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating elements painter for animated background
class FloatingElementsPainter extends CustomPainter {
  final double animation;
  
  FloatingElementsPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw floating circles with Philippine flag colors
    final colors = [
      AppTheme.primaryColor.withOpacity(0.08),
      AppTheme.accentRed.withOpacity(0.06),
      AppTheme.accentYellow.withOpacity(0.07),
    ];

    for (int i = 0; i < 8; i++) {
      final offset = (animation + i * 0.125) % 1.0;
      final x = size.width * (0.1 + (i * 0.12) % 0.8);
      final y = size.height * offset;
      final radius = 30.0 + (i % 3) * 20.0;
      
      paint.color = colors[i % 3];
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Draw subtle stars representing community excellence
    paint.color = AppTheme.accentYellow.withOpacity(0.1);
    for (int i = 0; i < 5; i++) {
      final offset = (animation * 0.5 + i * 0.2) % 1.0;
      final x = size.width * (0.2 + i * 0.15);
      final y = size.height * (1 - offset);
      
      _drawStar(canvas, Offset(x, y), 5, 15, 7, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, int points, double outerRadius, double innerRadius, Paint paint) {
    final path = Path();
    final angle = math.pi / points;
    
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      final y = center.dy + radius * math.sin(i * angle - math.pi / 2);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FloatingElementsPainter oldDelegate) =>
      animation != oldDelegate.animation;
}

/// Gradient overlay for images
class BarangayGradientOverlay extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;
  
  const BarangayGradientOverlay({
    super.key,
    required this.child,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors ?? [
                Colors.transparent,
                AppTheme.primaryColor.withOpacity(0.3),
                AppTheme.primaryColor.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
