import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import 'animated_entrance.dart';
import 'heartbeat_line.dart';

/* ────────────────────────────────────────────────────────────────
   Floating medical icon particles (website: FloatingParticles)
   ──────────────────────────────────────────────────────────────── */

class _ParticleSpec {
  const _ParticleSpec(this.icon, this.x, this.y, this.size, this.opacity);

  final IconData icon;
  final double x; // fraction of width
  final double y; // fraction of height
  final double size;
  final double opacity;
}

class _GlowingParticleField extends StatefulWidget {
  const _GlowingParticleField();

  @override
  State<_GlowingParticleField> createState() => _GlowingParticleFieldState();
}

class _GlowingParticleFieldState extends State<_GlowingParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<_ParticleSpec> _particles = [
    _ParticleSpec(Icons.monitor_heart, 0.12, 0.18, 20, 0.15),
    _ParticleSpec(Icons.medical_services, 0.75, 0.12, 24, 0.12),
    _ParticleSpec(Icons.medication, 0.25, 0.72, 16, 0.18),
    _ParticleSpec(Icons.vaccines, 0.80, 0.65, 20, 0.10),
    _ParticleSpec(Icons.health_and_safety, 0.55, 0.85, 24, 0.12),
    _ParticleSpec(Icons.device_thermostat, 0.40, 0.25, 16, 0.15),
    _ParticleSpec(Icons.circle, 0.65, 0.42, 12, 0.20),
    _ParticleSpec(Icons.monitor_heart, 0.88, 0.35, 16, 0.14),
    _ParticleSpec(Icons.health_and_safety, 0.18, 0.50, 12, 0.16),
    _ParticleSpec(Icons.medication, 0.50, 0.55, 20, 0.10),
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
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
      builder: (context, _) {
        final t = _controller.value;
        return Stack(
          children: [
            for (var i = 0; i < _particles.length; i++)
              _buildParticle(_particles[i], i, t),
          ],
        );
      },
    );
  }

  Widget _buildParticle(_ParticleSpec p, int i, double t) {
    // Staggered phase so particles don't move in lockstep.
    final phase = (t + i * 0.13) * 2 * math.pi;
    final drift = math.sin(phase) * 18.0;
    final rotate = math.sin(phase * 1.3) * 0.08;

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: FractionalOffset(p.x, p.y),
          child: Transform.translate(
            offset: Offset(0, -drift),
            child: Transform.rotate(
              angle: rotate,
              child: Opacity(
                opacity: p.opacity,
                child: Icon(p.icon, size: p.size, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Glowing gradient orbs (blurred circles)
   ──────────────────────────────────────────────────────────────── */

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
    return Align(alignment: alignment, child: orb);
  }
}

/* ────────────────────────────────────────────────────────────────
   Dot-grid pattern (website: radial-gradient 1px dots every 32px)
   ──────────────────────────────────────────────────────────────── */

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      for (double y = 0; y < size.height; y += 32) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}

/* ────────────────────────────────────────────────────────────────
   StatPill
   ──────────────────────────────────────────────────────────────── */

class _StatPill extends StatefulWidget {
  const _StatPill({required this.label, required this.value, this.pulse = false});

  final String label;
  final String value;
  final bool pulse;

  @override
  State<_StatPill> createState() => _StatPillState();
}

class _StatPillState extends State<_StatPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.pulse) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.pulse
                    ? AppColors.emerald.withValues(alpha: 0.6 + 0.4 * (1 - _pulse.value))
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Live clock (website: LiveClock)
   ──────────────────────────────────────────────────────────────── */

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  static const List<String> _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _timeStr {
    final h = _now.hour;
    final hh = h % 12 == 0 ? 12 : h % 12;
    final ampm = h < 12 ? 'AM' : 'PM';
    return '$hh:${_two(_now.minute)}:${_two(_now.second)} $ampm';
  }

  String get _dateStr {
    return '${_weekdays[_now.weekday - 1]}, ${_now.day} '
        '${_months[_now.month - 1]} ${_now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _timeStr,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _dateStr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Left branding panel (website: LEFT PANEL — Branding)
   ──────────────────────────────────────────────────────────────── */

class LeftBrandingPanel extends StatelessWidget {
  const LeftBrandingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDeep, AppColors.brandMid, AppColors.brandDeep],
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            const Positioned.fill(child: _GlowingParticleField()),

            // Layered gradient orbs
            const Positioned(
              top: -160,
              left: -160,
              child: _GlowOrb(
                alignment: Alignment.topLeft,
                size: 700,
                color: Color(0x1410B981), // emerald-600 / 8%
              ),
            ),
            const Positioned(
              bottom: -240,
              right: -160,
              child: _GlowOrb(
                alignment: Alignment.bottomRight,
                size: 600,
                color: Color(0x0F0D9488), // teal-500 / 6%
              ),
            ),
            Positioned(
              top: 280,
              right: -60,
              child: _PulsingOrb(),
            ),

            // Dot grid overlay
            Positioned.fill(
              child: CustomPaint(painter: const _DotGridPainter()),
            ),

            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AnimatedEntrance(
                      type: EntranceType.slideRight,
                      child: _BrandHeader(),
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AnimatedEntrance(
                                child: _TrustBadge(),
                              ),
                              const SizedBox(height: 24),
                              const AnimatedEntrance(
                                delay: Duration(milliseconds: 100),
                                child: _HeroHeadline(),
                              ),
                              const SizedBox(height: 18),
                              const AnimatedEntrance(
                                delay: Duration(milliseconds: 200),
                                child: Text(
                                  'Streamline patient care, manage clinical workflows, '
                                  'and monitor real-time hospital operations — all from '
                                  'one intelligent dashboard.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.6,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 300),
                                child: const HeartbeatLine(height: 40),
                              ),
                              const SizedBox(height: 24),
                              AnimatedEntrance(
                                delay: const Duration(milliseconds: 400),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      child: _StatPill(
                                        label: 'Uptime',
                                        value: '99.97%',
                                        pulse: true,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: _StatPill(
                                        label: 'Response',
                                        value: '< 200ms',
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: _StatPill(
                                        label: 'Data',
                                        value: 'AES-256',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const AnimatedEntrance(
                      delay: Duration(milliseconds: 500),
                      child: Center(child: _LiveClock()),
                    ),
                  ],
                ),
              ),
            ),

            // Right vertical emerald accent strip
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 2,
              child: const _GradientBorderStrip(),
            ),
          ],
        ),
      ),
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Small supporting widgets
   ──────────────────────────────────────────────────────────────── */

class _PulsingOrb extends StatefulWidget {
  @override
  State<_PulsingOrb> createState() => _PulsingOrbState();
}

class _PulsingOrbState extends State<_PulsingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.emeraldLight.withValues(alpha: 0.03 + 0.02 * _c.value),
              AppColors.emeraldLight.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final logo = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald, AppColors.emeraldDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.25),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.monitor_heart,
        color: Colors.white,
        size: 28,
      ),
    );

    return Row(
      children: [
        const _GlowRing(),
        const SizedBox(width: 4),
        logo,
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.brandName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppConstants.brandTagline.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: Color(0x6634D399), // emerald-400 / 40%
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlowRing extends StatelessWidget {
  const _GlowRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.emerald.withValues(alpha: 0.20),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.20)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 14, color: AppColors.emeraldLight),
          SizedBox(width: 8),
          Text(
            'TRUSTED BY 200+ HOSPITALS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.emeraldLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Smart Healthcare,\n',
            style: TextStyle(
              fontSize: 44,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.2,
            ),
          ),
          TextSpan(
            text: 'Simplified.',
            style: TextStyle(
              fontSize: 44,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [
                    AppColors.emeraldLight,
                    AppColors.tealAccent,
                    AppColors.emeraldLight,
                  ],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 50)),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBorderStrip extends StatefulWidget {
  const _GradientBorderStrip();

  @override
  State<_GradientBorderStrip> createState() => _GradientBorderStripState();
}

class _GradientBorderStripState extends State<_GradientBorderStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.emerald.withValues(alpha: 0.30),
                AppColors.emeraldLight.withValues(alpha: 0.10),
                AppColors.emerald.withValues(alpha: 0.30),
              ],
              stops: [
                0.5 - 0.4 * _c.value,
                0.5,
                0.5 + 0.4 * _c.value,
              ],
            ),
          ),
        );
      },
    );
  }
}