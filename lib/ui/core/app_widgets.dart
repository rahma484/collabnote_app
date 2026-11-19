import 'package:flutter/material.dart';

import '../../domain/models/assignment_model.dart';
import 'app_colors.dart';

// ---------------------------------------------------------------- Transisi

/// Transisi halaman: slide-up 300 ms.
Route<T> slideUpRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

Future<T?> pushSlideUp<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(slideUpRoute<T>(page));

/// Efek tekan: elemen mengecil menjadi 0.98 saat ditekan.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PressableScale({super.key, required this.child, this.onTap, this.onLongPress});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Kartu yang melebar dengan animasi pegas lembut saat ditekan.
class ExpandableCard extends StatefulWidget {
  final Widget header;
  final Widget body;
  final Color color;

  const ExpandableCard({super.key, required this.header, required this.body, this.color = AppColors.card});

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(16)),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.header,
              if (_open) ...[const SizedBox(height: 8), widget.body],
            ],
          ),
        ),
      ),
    );
  }
}


/// Placeholder shimmer ringan untuk menggantikan indikator loading yang berputar.
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  const ShimmerLoading({super.key, this.width = 230, this.height = 92});
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1250))..repeat();
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment(-1.5 + 3 * _controller.value, 0),
          end: Alignment(-0.5 + 3 * _controller.value, 0),
          colors: [AppColors.beige, Colors.white, AppColors.beige],
        ).createShader(rect),
        child: Container(
          width: widget.width, height: widget.height,
          decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 13, width: widget.width * .58, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            Container(height: 10, width: widget.width * .82, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(height: 10, width: widget.width * .42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
          ]),
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------ Komponen dasar

/// Tombol bulat di pojok kanan atas (logo CollabNote), membuka informasi aplikasi.
class LogoCircleButton extends StatelessWidget {
  const LogoCircleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => showAboutCollabNote(context),
      child: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(7),
        decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
        child: Image.asset('assets/images/logo_collabnote.png', fit: BoxFit.contain),
      ),
    );
  }
}

void showAboutCollabNote(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo_collabnote.png', height: 96),
          const SizedBox(height: 10),
          const Text('CollabNote', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Plan  •  Create  •  Collaborate', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          const Text(
            'Aplikasi manajemen penugasan dan arsip akademik.\nVersi 1.0.0 (data dummy + Local Storage)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
    ),
  );
}

/// Tombol utama lebar penuh.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.moccaDark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return PressableScale(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color : color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Kolom input dengan label di atasnya (sesuai mockup).
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
    this.suffix,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            minLines: maxLines > 1 ? maxLines : 1,
            validator: validator,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
          ),
        ],
      ),
    );
  }
}

class ProgressBarSoft extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;

  const ProgressBarSoft({
    super.key,
    required this.value,
    this.color = AppColors.mocca,
    this.track = AppColors.beige,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor: track,
      ),
    );
  }
}

/// Lencana pil kecil (mode, status, format).
class Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;

  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: foreground, fontSize: fontSize, fontWeight: FontWeight.w600)),
    );
  }
}

/// Lencana status penugasan. [overdue] menampilkan "Terlambat" (dihitung otomatis).
class StatusPill extends StatelessWidget {
  final AssignmentStatus status;
  final bool overdue;
  final bool onMint;

  const StatusPill({super.key, required this.status, this.overdue = false, this.onMint = false});

  @override
  Widget build(BuildContext context) {
    if (overdue) {
      return const Pill(label: 'Terlambat', background: AppColors.dangerSoft, foreground: AppColors.danger);
    }
    switch (status) {
      case AssignmentStatus.sedangDikerjakan:
        return const Pill(label: 'Sedang Dikerjakan', background: AppColors.mint, foreground: AppColors.mintText);
      case AssignmentStatus.menungguPemeriksaan:
        return const Pill(label: 'Menunggu Pemeriksaan', background: AppColors.yellow, foreground: AppColors.brown);
      case AssignmentStatus.selesai:
      case AssignmentStatus.diarsipkan:
        return Pill(
          label: status.label,
          background: onMint ? AppColors.doneGreen : AppColors.mint,
          foreground: onMint ? Colors.white : AppColors.mintText,
        );
      case AssignmentStatus.belumDimulai:
        return const Pill(label: 'Belum Dimulai', background: AppColors.chip, foreground: AppColors.brown);
    }
  }
}

/// Avatar bulat berisi inisial dengan warna tanah yang konsisten per nama.
class MemberAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool ring;

  const MemberAvatar({super.key, required this.name, this.size = 36, this.ring = false});

  static const List<Color> _palette = [
    Color(0xFF98765B), Color(0xFFB98B6B), Color(0xFF7A8F7B), Color(0xFFB07A6E), Color(0xFF8A7BA0), Color(0xFFC09A55),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length];
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: ring ? AppColors.cream : color, width: 2),
      ),
      child: Text(initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.42)),
    );
  }
}

/// Kondisi kosong: ilustrasi + pesan + tombol opsional.
class EmptyState extends StatelessWidget {
  final String? image;
  final IconData? icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, this.image, this.icon, required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null) Image.asset(image!, height: 170),
            if (icon != null) Icon(icon, size: 64, color: AppColors.beige),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              PrimaryButton(label: actionLabel!, onPressed: onAction, color: AppColors.brown),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Kolom pencarian berbentuk kapsul.
class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final Widget? trailing;

  const SearchField({super.key, required this.hint, required this.onChanged, this.trailing});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
      ),
    );
  }
}

/// Deretan pilihan berbentuk pil yang dapat digeser (filter chip).
class PillFilterRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const PillFilterRow({super.key, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = options[i] == selected;
          return PressableScale(
            onTap: () => onSelected(options[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? AppColors.mocca : AppColors.chip,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                options[i],
                style: TextStyle(color: on ? Colors.white : AppColors.brown, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------------- Dialog

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Dialog konfirmasi bergaya mockup: judul, penjelasan, tombol Batal dan aksi.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
  String cancelLabel = 'Batal',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brown,
                      side: const BorderSide(color: AppColors.mocca),
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.moccaDark,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Dialog satu kolom teks (tambah/ubah tahapan, nama anggota, dsb).
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  String confirmLabel = 'Simpan',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: TextField(controller: controller, autofocus: true, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.moccaDark),
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(ctx, text);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Kartu menu berwarna (Ruang Kerja).
class MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;

  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = AppColors.card,
    this.textColor = AppColors.brown,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor.withValues(alpha: 0.75), size: 26),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 15)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
