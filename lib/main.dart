import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'home_screen.dart';

void main() => runApp(const NagarShieldApp());

class NagarShieldApp extends StatelessWidget {
  const NagarShieldApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nagar Shield 360',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB9E992),
        brightness: Brightness.dark,
      ),
    ),
    home: const LoadingScreen(),
  );
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  Timer? _openingTimer;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _openingTimer = Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    });
  }

  @override
  void dispose() {
    _openingTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143E36), Color(0xFF0B2C29), Color(0xFF082622)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _BackdropPainter()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 34,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _TopLabel(),
                        const SizedBox(height: 48),
                        _LoaderContent(motion: _motion),
                        const SizedBox(height: 52),
                        const _BottomLabel(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _TopLabel extends StatelessWidget {
  const _TopLabel();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFFBCE98E),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x8099D67C), blurRadius: 12)],
        ),
      ),
      const SizedBox(width: 10),
      const Flexible(
        child: Text(
          'বাংলাদেশের নগরের জন্য',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFB7D5C4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _LoaderContent extends StatelessWidget {
  const _LoaderContent({required this.motion});

  final Animation<double> motion;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedBuilder(
        animation: motion,
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFB9E992), size: 89),
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: Icon(Icons.check_rounded, color: Colors.white, size: 39),
            ),
          ],
        ),
        builder: (context, child) => SizedBox(
          width: 236,
          height: 236,
          child: CustomPaint(
            painter: _OrbitPainter(progress: motion.value),
            child: Center(
              child: Transform.scale(
                scale: 1 + math.sin(motion.value * math.pi * 2) * 0.025,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF275D4C), Color(0xFF17463B)],
                    ),
                    border: Border.all(color: const Color(0x8078AE84)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80448565),
                        blurRadius: 48,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),
      const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Nagar Shield '),
            TextSpan(
              text: '360',
              style: TextStyle(color: Color(0xFFB9E992)),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 31,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'নগরের চিত্র, সিদ্ধান্তের শক্তি',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFB9D4C4), fontSize: 16, height: 1.6),
      ),
      const SizedBox(height: 48),
      Semantics(
        label: 'অ্যাপ লোড হচ্ছে',
        child: Column(
          children: [
            SizedBox(
              width: 218,
              height: 5,
              child: AnimatedBuilder(
                animation: motion,
                builder: (context, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const width = 76.0;
                      final left =
                          (constraints.maxWidth + width) * motion.value - width;
                      return Stack(
                        children: [
                          Container(color: const Color(0xFF477364)),
                          Positioned(
                            left: left,
                            top: 0,
                            bottom: 0,
                            width: width,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0x00B9E992),
                                    Color(0xFFB9E992),
                                    Color(0x00B9E992),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'অ্যাপ প্রস্তুত হচ্ছে...',
              style: TextStyle(
                color: Color(0xFFA9C6B5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BottomLabel extends StatelessWidget {
  const _BottomLabel();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(width: 28, height: 1, color: const Color(0xFF5F8D73)),
      const SizedBox(height: 16),
      const Text(
        'নিরাপদ ও সুস্থ নগরের পথে',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF83AB95), fontSize: 12),
      ),
    ],
  );
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2 - 9;
    final inner = size.width / 2 - 25;
    for (final radius in [outer, inner]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0x336FA889)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outer),
      progress * math.pi * 2 - math.pi / 2,
      math.pi / 2.7,
      false,
      Paint()
        ..color = const Color(0xFFB9E992)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: inner),
      -progress * math.pi * 2 + math.pi / 2,
      math.pi / 3.7,
      false,
      Paint()
        ..color = const Color(0xB379BBA2)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3,
    );
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final dot = center + Offset(math.cos(angle), math.sin(angle)) * outer;
      canvas.drawCircle(
        dot,
        i.isEven ? 2 : 1.3,
        Paint()..color = const Color(0x889BCBA1),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x0C8FC79C)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final route = Path()
      ..moveTo(-20, size.height * 0.31)
      ..cubicTo(
        size.width * 0.33,
        size.height * 0.20,
        size.width * 0.58,
        size.height * 0.38,
        size.width + 20,
        size.height * 0.24,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0x1879BBA2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => false;
}
