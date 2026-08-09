import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Animated ECG / heartbeat line identical to the website's SVG design.
///
/// Draws the same polyline sampled from the frontend SVG
/// (`<polyline points="0,30 80,30 ... 400,30">` in a 400x60 viewBox) with a
/// flowing emerald comet that continuously travels left to right.
class HeartbeatLine extends StatefulWidget {
  const HeartbeatLine({
    super.key,
    this.height = 40,
    this.speed = const Duration(seconds: 3),
    this.color = AppColors.emerald,
    this.lightColor = AppColors.emeraldLight,
  });

  final double height;
  final Duration speed;
  final Color color;
  final Color lightColor;

  @override
  State<HeartbeatLine> createState() => _HeartbeatLineState();
}

class _HeartbeatLineState extends State<HeartbeatLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.speed)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _HeartbeatPainter(
            progress: _controller.value,
            color: widget.color,
            lightColor: widget.lightColor,
          ),
        ),
      ),
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  _HeartbeatPainter({
    required this.progress,
    required this.color,
    required this.lightColor,
  });

  final double progress;
  final Color color;
  final Color lightColor;

  static const List<Offset> _nativePts = <Offset>[
    Offset(0, 30),
    Offset(80, 30),
    Offset(100, 30),
    Offset(115, 30),
    Offset(125, 8),
    Offset(135, 52),
    Offset(145, 30),
    Offset(160, 30),
    Offset(180, 30),
    Offset(195, 30),
    Offset(205, 12),
    Offset(215, 48),
    Offset(225, 30),
    Offset(240, 30),
    Offset(400, 30),
  ];

  Path _buildPath(Size size) {
    final path = Path();
    for (var i = 0; i < _nativePts.length; i++) {
      final p = _nativePts[i];
      final x = p.dx / 400 * size.width;
      final y = p.dy / 60 * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  List<Path> _extractSegment(
      PathMetric metric, double start, double length) {
    final paths = <Path>[];
    final limit = metric.length - 0.5;
    final end = start + length;
    if (end > limit) {
      if (start < limit) {
        paths.add(metric.extractPath(start, limit));
      }
      paths.add(metric.extractPath(0, end - limit));
    } else {
      paths.add(metric.extractPath(start, end));
    }
    return paths;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    final metric = path.computeMetrics().first;
    final total = metric.length;

    // Underlying soft line (the SVG 6px @ 0.15 opacity shadow).
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.height * 0.10
      ..color = color.withValues(alpha: 0.15);
    canvas.drawPath(path, shadowPaint);

    // Flowing comet head.
    final segLen = total * 0.5;
    final start = (progress * total * 1.25) % total;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.height * 0.042
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color,
          lightColor,
          color.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    for (final seg in _extractSegment(metric, start, segLen)) {
      canvas.drawPath(seg, paint);
    }

    // Bright dot at the comet tip.
    final tipPos = (start + segLen) % total;
    final tipPoint = metric.getTangentForOffset(tipPos)?.position;
    if (tipPoint != null) {
      final glow = Paint()..color = lightColor.withValues(alpha: 0.35);
      canvas.drawCircle(tipPoint, size.height * 0.09, glow);
      final core = Paint()..color = lightColor;
      canvas.drawCircle(tipPoint, size.height * 0.045, core);
    }
  }

  @override
  bool shouldRepaint(_HeartbeatPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Two-stroke HeartbeatLine for the small card divider (wc-height ~24px),
/// kept as a lightweight wrapper so call sites read like the web version.
class HeartbeatDivider extends StatelessWidget {
  const HeartbeatDivider({super.key, this.height = 24});

  final double height;

  @override
  Widget build(BuildContext context) {
    return HeartbeatLine(height: height);
  }
}