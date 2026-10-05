import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chapter_scene.dart';

/// A single ticker repaints a few particles without rebuilding the Home UI.
class ChapterAmbientEffects extends StatefulWidget {
  const ChapterAmbientEffects({super.key, required this.scene});

  final ChapterScene scene;

  @override
  State<ChapterAmbientEffects> createState() => _ChapterAmbientEffectsState();
}

class _ChapterAmbientEffectsState extends State<ChapterAmbientEffects>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.stop();
      motion.value = 0;
    } else if (!motion.isAnimating) {
      motion.repeat();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _AmbientPainter(widget.scene.ambientKind, motion),
        size: Size.infinite,
      ),
    ),
  );
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.kind, this.motion) : super(repaint: motion);

  final ChapterAmbientKind kind;
  final Animation<double> motion;

  @override
  void paint(Canvas canvas, Size size) {
    final t = motion.value;
    switch (kind) {
      case ChapterAmbientKind.goldenDust:
        _dust(canvas, size, t);
      case ChapterAmbientKind.fireflies:
        _mist(canvas, size, t);
        _fireflies(canvas, size, t);
      case ChapterAmbientKind.driftingLeaf:
        _leaf(canvas, size, t);
        _faintLights(canvas, size, t);
      case ChapterAmbientKind.lakeSparkles:
        _lakeSparkles(canvas, size, t);
      case ChapterAmbientKind.lakeBirds:
        _distantBirds(canvas, size, t);
        _windParticles(canvas, size, t, mountain: false);
      case ChapterAmbientKind.lakesideLights:
        _lakesideLights(canvas, size, t);
        _softHaze(
          canvas,
          center: Offset(
            size.width * (.5 + .09 * math.sin(t * math.pi * 2)),
            size.height * .61,
          ),
          width: size.width * .94,
          height: size.height * .18,
          centerAlpha: .22,
        );
      case ChapterAmbientKind.mountainWind:
        _windParticles(canvas, size, t, mountain: true);
        _softHaze(
          canvas,
          center: Offset(
            size.width * (.5 + .12 * math.sin(t * math.pi * 2)),
            size.height * .39,
          ),
          width: size.width * 1.05,
          height: size.height * .2,
          centerAlpha: .22,
        );
      case ChapterAmbientKind.mountainAscent:
        _mountainAir(canvas, size, t, count: 24, opacity: .56);
      case ChapterAmbientKind.highAltitude:
        _softHaze(
          canvas,
          center: Offset(
            size.width * (.5 + .11 * math.sin(t * math.pi * 2)),
            size.height * .48,
          ),
          width: size.width * 1.02,
          height: size.height * .2,
          centerAlpha: .23,
        );
        _rareSnow(canvas, size, t, count: 8, opacity: .65);
      case ChapterAmbientKind.mountainPass:
        _mountainAir(canvas, size, t, count: 26, opacity: .58);
        _softHaze(
          canvas,
          center: Offset(
            size.width * (.5 + .13 * math.sin(t * math.pi * 2)),
            size.height * .44,
          ),
          width: size.width * 1.08,
          height: size.height * .21,
          centerAlpha: .23,
        );
      case ChapterAmbientKind.castleRoad:
        _mountainAir(canvas, size, t, count: 15, opacity: .48);
        _softHaze(
          canvas,
          center: Offset(
            size.width * (.48 + .11 * math.sin(t * math.pi * 2)),
            size.height * .63,
          ),
          width: size.width * .94,
          height: size.height * .19,
          centerAlpha: .19,
        );
      case ChapterAmbientKind.castleGate:
        _mountainAir(canvas, size, t, count: 16, opacity: .48);
        _softHaze(
          canvas,
          center: Offset(
            size.width * (.48 + .11 * math.sin(t * math.pi * 2)),
            size.height * .58,
          ),
          width: size.width * 1.05,
          height: size.height * .2,
          centerAlpha: .21,
        );
      case ChapterAmbientKind.castleCourtyard:
        _warmLanterns(canvas, size, t, shelter: false);
        _lightMotes(canvas, size, t);
      case ChapterAmbientKind.castleTower:
        _coldHaze(canvas, size, t, y: .51, alpha: .21);
        _mountainAir(canvas, size, t, count: 15, opacity: .48);
        _rareSnow(canvas, size, t, count: 7, opacity: .65);
      case ChapterAmbientKind.castleNorthGate:
        _rareSnow(canvas, size, t, count: 21, opacity: .78);
        _coldHaze(canvas, size, t, y: .55, alpha: .22);
      case ChapterAmbientKind.northernValley:
        _rareSnow(canvas, size, t, count: 23, opacity: .8);
        _coldHaze(canvas, size, t, y: .52, alpha: .22);
      case ChapterAmbientKind.icyExpanse:
        _rareSnow(canvas, size, t, count: 16, opacity: .76);
        _groundDrift(canvas, size, t);
      case ChapterAmbientKind.northernLights:
        _rareSnow(canvas, size, t, count: 12, opacity: .7);
        _coldLights(canvas, size, t, count: 12);
      case ChapterAmbientKind.lastShelter:
        _rareSnow(canvas, size, t, count: 22, opacity: .78);
        _warmLanterns(canvas, size, t, shelter: true);
      case ChapterAmbientKind.worldsEdge:
        _rareSnow(canvas, size, t, count: 8, opacity: .65);
        _coldLights(canvas, size, t, count: 8);
    }
  }

  void _dust(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 40; i++) {
      final phase = (t + i * .137) % 1;
      final x =
          (.04 + (i * .317) % .92 + math.sin(phase * math.pi * 2 + i) * .06) *
          size.width;
      final y =
          (.08 + (i * .193) % .82 - math.sin(phase * math.pi * 2) * .06) *
          size.height;
      final shimmer = .5 + .5 * math.sin(t * math.pi * 6 + i * 1.7);
      _glow(
        canvas,
        Offset(x, y),
        const Color(0xFFFFD98A),
        1.8 + (i % 5) * .48,
        .46 + shimmer * .46,
      );
    }
  }

  void _fireflies(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 18; i++) {
      final phase = (t + i * .127) % 1;
      final x =
          (.06 + (i * .271) % .86 + math.sin(phase * math.pi * 2 + i) * .065) *
          size.width;
      final y =
          (.22 + (i * .173) % .58 + math.cos(phase * math.pi * 2 + i) * .055) *
          size.height;
      final pulse = (.5 + .5 * math.sin(t * math.pi * 8 + i * 2)).clamp(
        0.0,
        1.0,
      );
      _glow(
        canvas,
        Offset(x, y),
        const Color(0xFFFFE5A1),
        2.1 + (i % 4) * .48,
        .3 + pulse * .67,
      );
    }
  }

  void _mist(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 3; i++) {
      final drift =
          math.sin(t * math.pi * (2 + i * .4) + i * 2.1) * size.width * .12;
      final center = Offset(
        size.width * (.17 + i * .33) + drift,
        size.height * (.58 + i * .105),
      );
      final area = Rect.fromCenter(
        center: center,
        width: size.width * .82,
        height: size.height * .21,
      );
      canvas.drawOval(
        area,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x70FFFFF0), Color(0x32FFFFF0), Colors.transparent],
            stops: [0, .48, 1],
          ).createShader(area),
      );
    }
  }

  void _leaf(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 5; i++) {
      final arrival = (t + i / 5) % 1;
      if (arrival > .6) continue;
      final phase = arrival / .6;
      final x = size.width * (.92 - phase * .82);
      final y = size.height * (.13 + i * .13 + phase * .45);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * 3.2 + math.sin(phase * math.pi * 3) * .4);
      final path = Path()
        ..moveTo(0, -11)
        ..quadraticBezierTo(12, -2, 0, 11)
        ..quadraticBezierTo(-12, 2, 0, -11);
      canvas.drawPath(
        path,
        Paint()..color = const Color(0xFFD89542).withValues(alpha: .85),
      );
      canvas.drawLine(
        const Offset(0, -8),
        const Offset(0, 8),
        Paint()
          ..color = const Color(0xFF70451C).withValues(alpha: .80)
          ..strokeWidth = 1,
      );
      canvas.restore();
    }
  }

  void _faintLights(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 12; i++) {
      final phase = (t + i * .169) % 1;
      _glow(
        canvas,
        Offset(
          size.width * (.16 + (i * .237) % .72),
          size.height *
              (.24 + (i * .143) % .45 + .025 * math.sin(phase * math.pi * 2)),
        ),
        const Color(0xFFFFDE9D),
        1.8 + (i % 3) * .3,
        .28 + .55 * (.5 + .5 * math.sin(t * math.pi * 6 + i * 1.7)),
      );
    }
  }

  void _lakeSparkles(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 32; i++) {
      final pulse = .5 + .5 * math.sin(t * math.pi * 8 + i * 2.1);
      final point = Offset(
        size.width * (.1 + (i * .217) % .8),
        size.height * (.46 + (i * .137) % .34),
      );
      _glow(
        canvas,
        point,
        const Color(0xFFFFE4A9),
        1.5 + (i % 4) * .35,
        .3 + pulse * .62,
      );
      canvas.drawLine(
        point.translate(-2.5, 0),
        point.translate(2.5, 0),
        Paint()
          ..color = const Color(0xFFFFF1CB)
              .withValues(alpha: (.12 + pulse * .38))
          ..strokeWidth = .8,
      );
    }
  }

  void _distantBirds(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 5; i++) {
      final phase = (t + i * .37) % 1;
      if (phase > .43) continue;
      final center = Offset(
        size.width * (.12 + phase * 1.5),
        size.height * (.21 + i * .065 + math.sin(phase * math.pi * 2) * .018),
      );
      final wing = 5.5 + (i % 2) * 1.5;
      final lift = 1.2 + math.sin(t * math.pi * 10 + i) * 1.3;
      final paint = Paint()
        ..color = const Color(0xFF33435D).withValues(alpha: .82)
        ..strokeWidth = 1.15
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center.translate(-wing, -lift), center, paint);
      canvas.drawLine(center, center.translate(wing, -lift), paint);
    }
  }

  void _lakesideLights(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 18; i++) {
      final pulse = .5 + .5 * math.sin(t * math.pi * 6 + i * 1.8);
      _glow(
        canvas,
        Offset(
          size.width * (.065 + (i * .139) % .42),
          size.height * (.35 + (i * .071) % .18),
        ),
        const Color(0xFFFFC873),
        1.9 + (i % 3) * .4,
        .4 + pulse * .57,
      );
    }
  }

  void _windParticles(
    Canvas canvas,
    Size size,
    double t, {
    required bool mountain,
  }) {
    final count = mountain ? 28 : 22;
    for (var i = 0; i < count; i++) {
      final phase = (t * (mountain ? .8 : .55) + i * .173) % 1;
      final start = Offset(
        size.width * phase,
        size.height * (.2 + (i * .127) % (mountain ? .47 : .51)),
      );
      canvas.drawLine(
        start,
        start.translate(mountain ? 9 : 7, mountain ? -2.8 : -1.2),
        Paint()
          ..color = const Color(0xFFEAF3FA)
              .withValues(alpha: mountain ? .55 : .43)
          ..strokeWidth = mountain ? 1.4 : 1.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _mountainAir(
    Canvas canvas,
    Size size,
    double t, {
    required int count,
    required double opacity,
  }) {
    final paint = Paint()
      ..color = const Color(0xFFEAF3FA).withValues(alpha: opacity)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final phase = (t * .68 + i * .173) % 1;
      final point = Offset(
        size.width * phase,
        size.height * (.18 + (i * .127) % .55),
      );
      canvas.drawLine(point, point.translate(9, -2.6), paint);
    }
  }

  void _rareSnow(
    Canvas canvas,
    Size size,
    double t, {
    int count = 5,
    double opacity = .46,
  }) {
    for (var i = 0; i < count; i++) {
      final phase = (t * (.65 + (i % 3) * .18) + i * .173) % 1;
      final radius = i % 9 == 0 ? 3.1 : 1.4 + (i % 3) * .35;
      final center = Offset(
        size.width * (.04 + (i * .271 + phase * .1) % .92) +
            math.sin(t * math.pi * 2 + i) * size.width * .025,
        size.height * (.04 + phase * .92),
      );
      canvas.drawCircle(
        center,
        radius * 1.7,
        Paint()
          ..color = const Color(0xFF527795).withValues(alpha: opacity * .36),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = const Color(0xFFF6FBFF).withValues(alpha: opacity),
      );
    }
  }

  void _coldHaze(
    Canvas canvas,
    Size size,
    double t, {
    required double y,
    required double alpha,
  }) {
    _softHaze(
      canvas,
      center: Offset(
        size.width * (.5 + .11 * math.sin(t * math.pi * 2)),
        size.height * y,
      ),
      width: size.width * 1.04,
      height: size.height * .2,
      centerAlpha: alpha,
      color: const Color(0xFFD7EEFF),
    );
    _softHaze(
      canvas,
      center: Offset(
        size.width * (.46 + .13 * math.sin(t * math.pi * 1.4 + 1.7)),
        size.height * (y + .11),
      ),
      width: size.width * .86,
      height: size.height * .16,
      centerAlpha: alpha * .72,
      color: const Color(0xFFD7EEFF),
    );
  }

  void _warmLanterns(
    Canvas canvas,
    Size size,
    double t, {
    required bool shelter,
  }) {
    final count = shelter ? 16 : 14;
    for (var i = 0; i < count; i++) {
      final pulse = .5 + .5 * math.sin(t * math.pi * 6 + i * 1.9);
      _glow(
        canvas,
        Offset(
          size.width *
              (shelter ? .14 + (i * .113) % .65 : .12 + (i * .173) % .76),
          size.height *
              (shelter ? .37 + (i * .071) % .19 : .3 + (i * .107) % .31),
        ),
        const Color(0xFFFFCD79),
        2 + (i % 4) * .4,
        .36 + pulse * .6,
      );
    }
  }

  void _lightMotes(Canvas canvas, Size size, double t) {
    for (var i = 0; i < 15; i++) {
      final phase = (t * .45 + i * .173) % 1;
      _glow(
        canvas,
        Offset(
          size.width * (.1 + (i * .237) % .8),
          size.height * (.23 + (i * .113) % .52 - phase * .025),
        ),
        const Color(0xFFFFE5A7),
        1.7 + (i % 3) * .3,
        .3 + .5 * (.5 + .5 * math.sin(t * math.pi * 6 + i)),
      );
    }
  }

  void _groundDrift(Canvas canvas, Size size, double t) {
    final paint = Paint()
      ..color = const Color(0xFFD7EEFF).withValues(alpha: .6)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final phase = (t * .52 + i * .177) % 1;
      final point = Offset(
        size.width * phase,
        size.height * (.69 + (i * .071) % .16),
      );
      canvas.drawLine(point, point.translate(10 + (i % 3) * 3, -1.2), paint);
    }
  }

  void _coldLights(Canvas canvas, Size size, double t, {required int count}) {
    for (var i = 0; i < count; i++) {
      final pulse = .5 + .5 * math.sin(t * math.pi * 2 + i * 2.2);
      _glow(
        canvas,
        Offset(
          size.width * (.11 + (i * .193) % .78),
          size.height * (.13 + (i * .109) % .33),
        ),
        const Color(0xFFB9F5ED),
        1.8 + (i % 3) * .35,
        .26 + pulse * .52,
      );
    }
  }

  void _softHaze(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double centerAlpha,
    Color color = Colors.white,
  }) {
    final area = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawOval(
      area,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: centerAlpha),
            color.withValues(alpha: centerAlpha * .42),
            Colors.transparent,
          ],
          stops: const [0, .55, 1],
        ).createShader(area),
    );
  }

  void _glow(
    Canvas canvas,
    Offset center,
    Color color,
    double radius,
    double opacity,
  ) {
    canvas.drawCircle(
      center,
      radius * 4,
      Paint()..color = color.withValues(alpha: opacity * .12),
    );
    canvas.drawCircle(
      center,
      radius * 2,
      Paint()..color = color.withValues(alpha: opacity * .22),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) =>
      kind != oldDelegate.kind || motion != oldDelegate.motion;
}
