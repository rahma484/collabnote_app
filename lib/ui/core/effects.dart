import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Kumpulan efek visual CollabNote: glassmorphism, shimmer, animasi muncul, ikon salin interaktif,
/// dan latar ambient. Dipisahkan dari app_widgets.dart agar mudah dijelaskan satu per satu.

// ------------------------------------------------------------ Glassmorphism

/// Tinggi ruang yang dipakai bottom navigation (agar isi halaman tidak tertutup).
const double kNavBarSpace = 96;

/// Tinggi header kaca pada halaman tab (di luar status bar).
const double kGlassHeaderHeight = 64;

/// Wadah kaca: latar buram (blur) + gradasi putih transparan + garis tepi tipis.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Color tint;
  final double opacity;
  final bool shadow;
  final bool border;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.blur = 18,
    this.padding,
    this.tint = AppColors.cream,
    this.opacity = 0.55,
    this.shadow = true,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [BoxShadow(color: AppColors.brown.withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 8))]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: opacity),
                  tint.withValues(alpha: opacity * 0.6),
                ],
              ),
              border: border ? Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1) : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Kartu mengambang bergaya kaca (dipakai untuk banner, kode undangan, dan bilah aksi).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color tint;

  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.tint = AppColors.beige});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      tint: tint,
      opacity: 0.62,
      borderRadius: BorderRadius.circular(20),
      child: child,
    );
  }
}

/// AppBar kaca: transparan dengan latar buram. Pengganti AppBar biasa di halaman detail.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double toolbarHeight;

  const GlassAppBar({super.key, this.title, this.actions, this.leading, this.toolbarHeight = 56});

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.72),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.7))),
            ),
          ),
        ),
      ),
    );
  }
}

/// Halaman tab dengan header kaca yang melayang di atas isi (isi bergulir di bawah header).
/// [builder] menerima jarak atas yang harus dipakai sebagai padding atas daftar.
class GlassTabPage extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget Function(BuildContext context, EdgeInsets padding) builder;

  const GlassTabPage({super.key, required this.title, this.trailing, required this.builder});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + kGlassHeaderHeight;
    final padding = EdgeInsets.fromLTRB(20, top + 4, 20, kNavBarSpace + MediaQuery.paddingOf(context).bottom);
    return Stack(
      children: [
        Positioned.fill(child: builder(context, padding)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 20, 8),
                height: top,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.70),
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.7))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.brown)),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Latar ambient: bulatan lembut berwarna mocca/beige di belakang konten, supaya efek kaca terlihat.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  Widget _blob(double size, Color color, {double? top, double? left, double? right, double? bottom}) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.38)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppColors.cream)),
        _blob(260, AppColors.beige, top: -70, right: -80),
        _blob(200, const Color(0xFFCBE5DC), top: 280, left: -90),
        _blob(240, const Color(0xFFF2D6D0), bottom: 40, right: -100),
        Positioned.fill(child: child),
      ],
    );
  }
}

// ------------------------------------------------------------------ Shimmer

/// Efek kilau yang bergerak di atas [child] (dipakai bersama kerangka loading).
class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.5 + 3 * t, -0.3),
              end: Alignment(-0.5 + 3 * t, 0.3),
              colors: const [Color(0xFFE9D8C6), Color(0xFFFBF4EA), Color(0xFFE9D8C6)],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Kotak kerangka (placeholder) yang akan berkilau saat data dimuat.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: const Color(0xFFE9D8C6), borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Kerangka daftar kartu. Pengganti indikator lingkaran saat memuat data.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final EdgeInsets padding;

  const SkeletonList({super.key, this.count = 4, this.itemHeight = 104, this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 8)});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: itemHeight,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFE9D8C6), borderRadius: BorderRadius.circular(18)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 170, height: 16, radius: 8),
                SizedBox(height: 10),
                SkeletonBox(width: 120, height: 12, radius: 6),
                Spacer(),
                SkeletonBox(height: 10, radius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tampilan memuat satu halaman penuh (judul + beberapa kartu kerangka).
class LoadingView extends StatelessWidget {
  final int count;

  const LoadingView({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => SkeletonList(count: count);
}

/// Garis kilau tipis untuk indikator memuat kecil (mis. di tombol atau splash).
class ShimmerBar extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerBar({super.key, this.width = 140, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer(child: SkeletonBox(width: width, height: height, radius: height));
  }
}

// ------------------------------------------------------- Animasi muncul

/// Muncul dengan fade + geser naik, bertahap berdasarkan [index] (efek stagger pada daftar).
class AnimatedAppear extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedAppear({super.key, required this.child, this.index = 0});

  @override
  State<AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<AnimatedAppear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index.clamp(0, 8)) * 60);
    _timer = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(curved),
        child: widget.child,
      ),
    );
  }
}

// ------------------------------------------------------ Ikon salin interaktif

/// Ikon salin yang berubah menjadi centang saat berhasil menyalin [text], lalu kembali semula.
class CopyIconButton extends StatefulWidget {
  final String text;
  final String tooltip;
  final Color color;

  const CopyIconButton({super.key, required this.text, this.tooltip = 'Salin', this.color = AppColors.brown});

  @override
  State<CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<CopyIconButton> {
  bool _copied = false;
  Timer? _timer;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _copied ? 'Tersalin' : widget.tooltip,
      child: InkResponse(
        onTap: _copy,
        radius: 24,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _copied ? AppColors.mint : Colors.transparent,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
            child: _copied
                ? const Icon(Icons.check_rounded, key: ValueKey('done'), size: 22, color: AppColors.doneGreen)
                : Icon(Icons.copy_rounded, key: const ValueKey('copy'), size: 21, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------- Empty state interaktif

/// Empty state berwarna: lingkaran gradasi, ilustrasi yang melayang pelan, bisa diketuk
/// (memantul), dan tombol aksi yang berdenyut halus.
class AnimatedEmptyState extends StatefulWidget {
  final String? image;
  final IconData? icon;
  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accent;

  const AnimatedEmptyState({
    super.key,
    this.image,
    this.icon,
    this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.accent = const Color(0xFFF2D6D0),
  });

  @override
  State<AnimatedEmptyState> createState() => _AnimatedEmptyStateState();
}

class _AnimatedEmptyStateState extends State<AnimatedEmptyState> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);
  late final AnimationController _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void dispose() {
    _float.dispose();
    _bounce.dispose();
    super.dispose();
  }

  void _poke() {
    HapticFeedback.selectionClick();
    _bounce.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final art = widget.image != null
        ? Image.asset(widget.image!, height: 150)
        : Icon(widget.icon ?? Icons.inbox_outlined, size: 64, color: AppColors.brown);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AnimatedAppear(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _poke,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_float, _bounce]),
                  builder: (context, child) {
                    final dy = -8 * Curves.easeInOut.transform(_float.value);
                    final b = _bounce.value;
                    final scale = 1 + 0.12 * (b == 0 ? 0 : (1 - (2 * b - 1).abs()));
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.scale(scale: scale, child: child),
                    );
                  },
                  child: Container(
                    width: 190,
                    height: 190,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [widget.accent, widget.accent.withValues(alpha: 0.25)],
                      ),
                    ),
                    child: art,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(widget.title!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              Text(widget.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, height: 1.4)),
              if (widget.actionLabel != null) ...[
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _float,
                  builder: (context, child) => Transform.scale(scale: 1 + 0.02 * _float.value, child: child),
                  child: SizedBox(
                    width: 240,
                    child: _EmptyActionButton(label: widget.actionLabel!, onTap: widget.onAction),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyActionButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _EmptyActionButton({required this.label, this.onTap});

  @override
  State<_EmptyActionButton> createState() => _EmptyActionButtonState();
}

class _EmptyActionButtonState extends State<_EmptyActionButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brown,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.brown.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Text(widget.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
