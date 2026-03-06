import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'auth_wrapper.dart';
import 'theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _progressController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<double> _textSlide;
  late Animation<double> _ring1Scale;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring1Opacity;
  late Animation<double> _ring2Opacity;
  late Animation<double> _shimmer;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _rotateController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    // Logo entrance
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );

    // Text entrance
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.5, 0.85, curve: Curves.easeIn)),
    );
    _textSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic)),
    );

    // Pulse rings
    _ring1Scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _ring1Opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _ring2Scale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _ring2Opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    // Shimmer
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Progress bar
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _progressController.forward();
    });

    Timer(const Duration(milliseconds: 3600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AuthWrapper(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D1F4C),
              Color(0xFF0038A8),
              Color(0xFF1A0A3C),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated star particles
            ...List.generate(25, (i) => _buildParticle(i, size)),

            // Rotating outer ring dashes
            Center(child: _buildRotatingRing(size)),

            // Pulsing glow rings
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ring 2 (inner)
                    Transform.scale(
                      scale: _ring2Scale.value,
                      child: Opacity(
                        opacity: _ring2Opacity.value * _logoFade.value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accentYellow,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Ring 1 (outer)
                    Transform.scale(
                      scale: _ring1Scale.value,
                      child: Opacity(
                        opacity: _ring1Opacity.value * _logoFade.value,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryLight.withOpacity(0.8),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (_, __) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container with glow
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: _buildGlowingLogo(),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // KOMUNIDAD shimmer text
                    Opacity(
                      opacity: _textFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: _buildShimmerTitle(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Tagline
                    Opacity(
                      opacity: _textFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Text(
                          "Connecting Citizens, Empowering Communities",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.6,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Progress bar
                    Opacity(
                      opacity: _textFade.value,
                      child: _buildProgressBar(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom badge
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textFade,
                builder: (_, __) => Opacity(
                  opacity: _textFade.value,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Text(
                          "Barangay Services Platform  •  v1.0",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 1.0,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowingLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: 175,
          height: 175,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withOpacity(0.5),
                blurRadius: 60,
                spreadRadius: 15,
              ),
              BoxShadow(
                color: AppTheme.accentYellow.withOpacity(0.3),
                blurRadius: 80,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Logo ring border
        Container(
          width: 158,
          height: 158,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Color(0xFFFCD116),
                Color(0xFF0038A8),
                Color(0xFFCE1126),
                Color(0xFFFCD116),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0D1F4C),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerTitle() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Colors.white,
              Color(0xFFFCD116),
              Colors.white,
              Colors.white,
            ],
            stops: [
              (_shimmer.value - 0.5).clamp(0.0, 1.0),
              _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.5).clamp(0.0, 1.0),
              1.0,
            ],
          ).createShader(bounds),
          child: const Text(
            "KOMUNIDAD",
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 6,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _progressController,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 3.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withOpacity(0.12),
                ),
                child: FractionallySizedBox(
                  widthFactor: _progress.value,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0038A8),
                          Color(0xFFFCD116),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentYellow.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Loading...",
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.45),
              letterSpacing: 2,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingRing(Size size) {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (_, __) => Transform.rotate(
        angle: _rotateController.value * 2 * math.pi,
        child: Opacity(
          opacity: 0.18,
          child: CustomPaint(
            size: const Size(230, 230),
            painter: _DashedRingPainter(
              color: AppTheme.accentYellow,
              dashCount: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(int index, Size size) {
    final random = math.Random(index * 37 + 13);
    final x = random.nextDouble() * size.width;
    final y = random.nextDouble() * size.height;
    final particleSize = random.nextDouble() * 3 + 1;
    final delay = random.nextDouble();

    return AnimatedBuilder(
      animation: _particleController,
      builder: (_, __) {
        final t = ((_particleController.value + delay) % 1.0);
        final opacity = (math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.7;
        final yOffset = -40.0 * t;

        return Positioned(
          left: x,
          top: y + yOffset,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: particleSize,
              height: particleSize,
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
                        .withOpacity(0.8),
                    blurRadius: 4,
                    spreadRadius: 1,
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

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final int dashCount;

  const _DashedRingPainter({required this.color, required this.dashCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashAngle = 0.12;
    final gapAngle = (2 * math.pi / dashCount) - dashAngle;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (dashAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

