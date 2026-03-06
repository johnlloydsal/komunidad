import 'package:flutter/material.dart';

/// Enhanced App Logo Widget - Uses actual barangay logo with animations
class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showLabel;
  final bool animated;

  const AppLogo({
    super.key,
    this.size = 100,
    this.color,
    this.showLabel = false,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoWidget = _buildLogo();
    
    if (!showLabel) {
      return animated ? _AnimatedLogo(child: logoWidget) : logoWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        animated ? _AnimatedLogo(child: logoWidget) : logoWidget,
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF0038A8), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'KOMUNIDAD',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
        Text(
          'Barangay Services',
          style: TextStyle(
            fontSize: size * 0.12,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0038A8),
            Color(0xFF2563EB),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0038A8).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to custom painted logo if image not found
            return CustomPaint(
              size: Size(size, size),
              painter: LogoPainter(color: color ?? Colors.white),
            );
          },
        ),
      ),
    );
  }
}

/// Animated logo with pulse and glow effect
class _AnimatedLogo extends StatefulWidget {
  final Widget child;

  const _AnimatedLogo({required this.child});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0038A8).withOpacity(0.3 * _glowAnimation.value),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Fallback custom painted logo
class LogoPainter extends CustomPainter {
  final Color color;

  LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    // Draw barangay hall icon
    // Roof
    final roofPath = Path();
    roofPath.moveTo(centerX, centerY * 0.4);
    roofPath.lineTo(centerX - width * 0.3, centerY * 0.7);
    roofPath.lineTo(centerX + width * 0.3, centerY * 0.7);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Building body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY * 1.2),
        width: width * 0.5,
        height: height * 0.5,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(bodyRect, paint);

    // Door
    paint.color = color.withOpacity(0.6);
    final doorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY * 1.4),
        width: width * 0.15,
        height: height * 0.25,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(doorRect, paint);

    // Windows
    paint.color = color.withOpacity(0.7);
    final leftWindow = Offset(centerX - width * 0.15, centerY * 1.0);
    final rightWindow = Offset(centerX + width * 0.15, centerY * 1.0);
    
    canvas.drawCircle(leftWindow, width * 0.05, paint);
    canvas.drawCircle(rightWindow, width * 0.05, paint);

    // Flag pole
    paint.color = color;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX, centerY * 0.4),
      Offset(centerX, centerY * 0.15),
      paint,
    );

    // Flag
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFFCD116); // Yellow
    final flagPath = Path();
    flagPath.moveTo(centerX, centerY * 0.15);
    flagPath.lineTo(centerX + width * 0.15, centerY * 0.2);
    flagPath.lineTo(centerX, centerY * 0.25);
    flagPath.close();
    canvas.drawPath(flagPath, paint);
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) => color != oldDelegate.color;
}
