import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Bentuk dan grafik buatan sendiri memakai CustomClipper dan CustomPainter:
/// header bergelombang, donat statistik, grafik batang deadline, dan cincin progres.

// ------------------------------------------------------------------- Gelombang

/// Memotong bagian bawah widget menjadi garis gelombang (sinus). [phase] menggeser gelombang.
class WaveClipper extends CustomClipper<Path> {
  final double phase;
  final double amplitude;

  const WaveClipper({this.phase = 0, this.amplitude = 10});

  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - amplitude * 2);
    for (double x = 0; x <= size.width; x += 4) {
      final y = size.height - amplitude - amplitude * math.sin((x / size.width) * 2 * math.pi + phase);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaveClipper old) => old.phase != phase || old.amplitude != amplitude;
}

/// Header gradasi mocca dengan dua lapis gelombang yang bergerak pelan. [child] diletakkan di atasnya.
class WaveHeader extends StatefulWidget {
  final double height;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const WaveHeader({super.key, this.height = 200, required this.child, this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 36)});

  @override
  State<WaveHeader> createState() => _WaveHeaderState();
}

class _WaveHeaderState extends State<WaveHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final phase = _controller.value * 2 * math.pi;
          return Stack(
            children: [
              Positioned.fill(
                child: ClipPath(
                  clipper: WaveClipper(phase: phase, amplitude: 11),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.mocca, AppColors.moccaDark],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipPath(
                  clipper: WaveClipper(phase: -phase * 0.8 + 1.4, amplitude: 15),
                  child: DecoratedBox(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10))),
                ),
              ),
              Positioned.fill(child: Padding(padding: widget.padding, child: child)),
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ----------------------------------------------------------------------- Donat

class DonutSlice {
  final double value;
  final Color color;

  const DonutSlice(this.value, this.color);
}

/// Grafik donat dengan animasi menyapu. [center] ditampilkan di tengah lingkaran.
class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final double size;
  final double strokeWidth;
  final Widget? center;
  final Color track;

  const DonutChart({
    super.key,
    required this.slices,
    this.size = 120,
    this.strokeWidth = 14,
    this.center,
    this.track = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size(size, size), painter: _DonutPainter(slices, t, strokeWidth, track)),
            if (center != null) center!,
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;
  final double progress;
  final double stroke;
  final Color track;

  _DonutPainter(this.slices, this.progress, this.stroke, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base);

    final total = slices.fold<double>(0, (a, s) => a + s.value);
    if (total <= 0) return;
    const gap = 0.10;
    var start = -math.pi / 2;
    for (final s in slices) {
      if (s.value <= 0) continue;
      final sweep = (2 * math.pi * s.value / total) * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = s.color;
      final draw = math.max(0.0, sweep - gap);
      if (draw > 0) canvas.drawArc(rect, start + gap / 2, draw, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.progress != progress || old.slices != slices;
}

// ------------------------------------------------------------- Batang mingguan

/// Grafik batang kecil: jumlah deadline pada 7 hari ke depan. Batang hari ini disorot.
class WeekBars extends StatelessWidget {
  final List<int> counts;
  final List<String> labels;
  final int highlight;
  final double height;

  const WeekBars({super.key, required this.counts, required this.labels, this.highlight = 0, this.height = 120});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _WeekBarsPainter(counts, labels, highlight, t.clamp(0.0, 1.2)),
      ),
    );
  }
}

class _WeekBarsPainter extends CustomPainter {
  final List<int> counts;
  final List<String> labels;
  final int highlight;
  final double t;

  _WeekBarsPainter(this.counts, this.labels, this.highlight, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (counts.isEmpty) return;
    const labelHeight = 20.0;
    final chartHeight = size.height - labelHeight;
    final maxCount = math.max(1, counts.reduce(math.max));
    final slot = size.width / counts.length;
    final barWidth = math.min(26.0, slot * 0.52);

    final guide = Paint()
      ..color = AppColors.beige.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartHeight), Offset(size.width, chartHeight), guide);

    for (var i = 0; i < counts.length; i++) {
      final cx = slot * i + slot / 2;
      final h = counts[i] == 0 ? 6.0 : (chartHeight - 14) * (counts[i] / maxCount) * t + 6;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - barWidth / 2, chartHeight - h, barWidth, h),
        const Radius.circular(9),
      );
      final isToday = i == highlight;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: counts[i] == 0
              ? [AppColors.chip, AppColors.chip]
              : (isToday ? [AppColors.brown, AppColors.mocca] : [AppColors.mocca, AppColors.beige]),
        ).createShader(rect.outerRect);
      canvas.drawRRect(rect, paint);

      if (counts[i] > 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${counts[i]}', style: const TextStyle(color: AppColors.brown, fontSize: 11, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, chartHeight - h - tp.height - 2));
      }
      final label = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: isToday ? AppColors.brown : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(cx - label.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _WeekBarsPainter old) => old.t != t || old.counts != counts;
}

// ---------------------------------------------------------------- Cincin progres

/// Cincin progres bergradasi (menggantikan indikator lingkaran standar).
class ProgressRing extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final double strokeWidth;
  final Widget? center;

  const ProgressRing({super.key, required this.value, this.size = 150, this.strokeWidth = 14, this.center});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(size: Size(size, size), painter: _RingPainter(v, strokeWidth)),
            if (center != null) center!,
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;

  _RingPainter(this.value, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.chip;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);
    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [AppColors.beige, AppColors.mocca, AppColors.brown],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.value != value;
}
