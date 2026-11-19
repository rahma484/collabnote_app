import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilihan tema: Terang atau Gelap.
enum AppThemeMode { terang, gelap }

extension AppThemeModeX on AppThemeMode {
  String get label {
    switch (this) {
      case AppThemeMode.terang:
        return 'Terang';
      case AppThemeMode.gelap:
        return 'Gelap';
    }
  }
}

/// Menyimpan preferensi tema di SharedPreferences (local cache) agar pilihan tetap ada
/// setelah aplikasi ditutup. Dibagikan ke seluruh aplikasi lewat Provider.
class ThemeController extends ChangeNotifier {
  static const String _key = 'collabnote_theme_mode';

  AppThemeMode mode = AppThemeMode.terang;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      for (final m in AppThemeMode.values) {
        if (m.name == saved) mode = m;
      }
      notifyListeners();
    } catch (_) {
      // Tanpa cache, aplikasi tetap berjalan dengan tema bawaan.
    }
  }

  Future<void> setMode(AppThemeMode value) async {
    mode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, value.name);
    } catch (_) {}
  }

  bool isDark(BuildContext context) {
    switch (mode) {
      case AppThemeMode.terang:
        return false;
      case AppThemeMode.gelap:
        return true;
    }
  }
}

/// Matriks warna mode gelap: inversi terang-gelap sambil mempertahankan rona (hue).
/// Krem menjadi cokelat tua, cokelat tua menjadi krem terang, mocca tetap mocca.
const List<double> _darkMatrix = [
  0.574, -1.430, -0.144, 0, 255,
  -0.426, -0.430, -0.144, 0, 255,
  -0.426, -1.430, 0.856, 0, 255,
  0, 0, 0, 1, 0,
];

const List<double> _identityMatrix = [
  1, 0, 0, 0, 0,
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
];

List<double> _lerpMatrix(double t) => [for (var i = 0; i < 20; i++) _identityMatrix[i] + (_darkMatrix[i] - _identityMatrix[i]) * t];

/// Menerapkan mode gelap pada seluruh aplikasi dengan transisi halus.
class DarkModeFilter extends StatelessWidget {
  final bool dark;
  final Widget child;

  const DarkModeFilter({super.key, required this.dark, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: dark ? 1 : 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: child,
      builder: (context, t, child) {
        if (t == 0) return child!;
        return ColorFiltered(colorFilter: ColorFilter.matrix(_lerpMatrix(t)), child: child);
      },
    );
  }
}

/// Mengembalikan warna asli (foto/gambar) di dalam mode gelap. Filter gelap bersifat
/// involusi (diterapkan dua kali = warna asli), jadi gambar tidak tampak terbalik.
class RestoreColors extends StatelessWidget {
  final Widget child;

  const RestoreColors({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeController>().isDark(context);
    if (!dark) return child;
    return ColorFiltered(colorFilter: const ColorFilter.matrix(_darkMatrix), child: child);
  }
}
