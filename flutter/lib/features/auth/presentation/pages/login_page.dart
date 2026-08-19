import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/left_branding_panel.dart';
import '../widgets/login_card.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return isWide
              ? const _WideLayout()
              : const _CompactLayout();
        },
      ),
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Wide layout — two panels like the website (>= 900px)
   ──────────────────────────────────────────────────────────────── */

class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 11, child: LeftBrandingPanel()),
        Expanded(flex: 9, child: _RightPanel()),
      ],
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Compact layout — single-column mobile (website `lg:hidden` brand)
   ──────────────────────────────────────────────────────────────── */

class _CompactLayout extends StatelessWidget {
  const _CompactLayout();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pageTop, Colors.white, AppColors.pageBottom],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -240,
            right: -140,
            child: _BlurBlob(
              size: 500,
              color: Color(0x6665A30D),
            ),
          ),
          Positioned(
            bottom: -220,
            left: -160,
            child: _BlurBlob(
              size: 400,
              color: AppColors.tealAccent.withValues(alpha: 0.06),
            ),
          ),
          CustomPaint(
            painter: const _FaintGridPainter(),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      const AnimatedEntrance(child: _MobileBrandHeader()),
                      const SizedBox(height: 28),
                      AnimatedEntrance(
                        type: EntranceType.scaleIn,
                        delay: const Duration(milliseconds: 150),
                        child: const LoginCard(),
                      ),
                      const SizedBox(height: 20),
                      const AnimatedEntrance(
                        delay: Duration(milliseconds: 400),
                        child: _SecurityNote(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Right panel (shared by wide layout + the form column)
   ──────────────────────────────────────────────────────────────── */

class _RightPanel extends StatelessWidget {
  const _RightPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pageTop, Colors.white, AppColors.pageBottom],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -240,
            right: -140,
            child: _BlurBlob(size: 500, color: Color(0x6665A30D)),
          ),
          Positioned(
            bottom: -220,
            left: -160,
            child: _BlurBlob(
              size: 400,
              color: AppColors.tealAccent.withValues(alpha: 0.06),
            ),
          ),
          const CustomPaint(
            painter: _FaintGridPainter(),
            child: SizedBox.expand(),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedEntrance(
                      type: EntranceType.scaleIn,
                      delay: const Duration(milliseconds: 150),
                      child: const LoginCard(),
                    ),
                    const SizedBox(height: 20),
                    const AnimatedEntrance(
                      delay: Duration(milliseconds: 400),
                      child: _SecurityNote(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Mobile-only brand header
   ──────────────────────────────────────────────────────────────── */

class _MobileBrandHeader extends StatelessWidget {
  const _MobileBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                color: AppColors.emerald.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.monitor_heart,
            size: 28,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'AURA Medical',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
        const Text(
          'Hospital Management System',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Security note
   ──────────────────────────────────────────────────────────────── */

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.emerald.withValues(alpha: 0.5 + 0.5 * _c.value),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _PulsingDot(),
        const SizedBox(width: 6),
        Text(
          'Protected by end-to-end encryption · HIPAA Compliant',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/* ────────────────────────────────────────────────────────────────
   Background decoration helpers
   ──────────────────────────────────────────────────────────────── */

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _FaintGridPainter extends CustomPainter {
  const _FaintGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_FaintGridPainter oldDelegate) => false;
}