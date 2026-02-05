import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({super.key, this.size = 100, this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.6),
      painter: LogoPainter(color: color ?? const Color(0xFF1E3A8A)),
    );
  }
}

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

    // Left Mountain (darker)
    final leftMountain = Path();
    leftMountain.moveTo(width * 0.05, height);
    leftMountain.lineTo(width * 0.25, height * 0.2);
    leftMountain.lineTo(width * 0.38, height);
    leftMountain.close();

    paint.color = color.withOpacity(0.7);
    canvas.drawPath(leftMountain, paint);

    // Middle Mountain (main)
    final middleMountain = Path();
    middleMountain.moveTo(width * 0.28, height);
    middleMountain.lineTo(width * 0.5, height * 0.05);
    middleMountain.lineTo(width * 0.72, height);
    middleMountain.close();

    paint.color = color;
    canvas.drawPath(middleMountain, paint);

    // Right Mountain (darker)
    final rightMountain = Path();
    rightMountain.moveTo(width * 0.62, height);
    rightMountain.lineTo(width * 0.75, height * 0.2);
    rightMountain.lineTo(width * 0.95, height);
    rightMountain.close();

    paint.color = color.withOpacity(0.7);
    canvas.drawPath(rightMountain, paint);

    // House windows (2x2 grid)
    paint.color = Colors.white;
    final windowSize = width * 0.06;
    final windowSpacing = width * 0.03;

    // Top left window
    canvas.drawRect(
      Rect.fromLTWH(width * 0.42, height * 0.45, windowSize, windowSize),
      paint,
    );

    // Top right window
    canvas.drawRect(
      Rect.fromLTWH(
        width * 0.42 + windowSize + windowSpacing,
        height * 0.45,
        windowSize,
        windowSize,
      ),
      paint,
    );

    // Bottom left window
    canvas.drawRect(
      Rect.fromLTWH(
        width * 0.42,
        height * 0.45 + windowSize + windowSpacing,
        windowSize,
        windowSize,
      ),
      paint,
    );

    // Bottom right window
    canvas.drawRect(
      Rect.fromLTWH(
        width * 0.42 + windowSize + windowSpacing,
        height * 0.45 + windowSize + windowSpacing,
        windowSize,
        windowSize,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
