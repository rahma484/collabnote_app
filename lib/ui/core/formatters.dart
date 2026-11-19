/// Format tanggal dan teks berbahasa Indonesia (tanpa paket tambahan).
library;

const List<String> _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const List<String> _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];
const List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

/// 20 Mei 2026
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// 15 Jan 2026
String formatDateShort(DateTime d) => '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

/// 18 Mei
String formatDayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// Selasa, 17 November 2026
String formatLongDate(DateTime d) => '${_days[d.weekday - 1]}, ${formatDate(d)}';

/// Teks sisa waktu: "2 Hari Lagi", "1 Minggu Lagi", "Terlambat 2 Hari".
String deadlineText(int daysLeft) {
  if (daysLeft < 0) return 'Terlambat ${-daysLeft} Hari';
  if (daysLeft == 0) return 'Hari Ini';
  if (daysLeft == 1) return 'Besok';
  if (daysLeft < 7) return '$daysLeft Hari Lagi';
  if (daysLeft < 30) return '${(daysLeft / 7).round()} Minggu Lagi';
  return '${(daysLeft / 30).round()} Bulan Lagi';
}

String formatSize(int bytes) {
  if (bytes <= 0) return '-';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Teks sisa waktu dari tanggal deadline (memakai hari ini sebagai acuan).
String daysUntilText(DateTime deadline) {
  final today = DateTime.now();
  final a = DateTime.utc(today.year, today.month, today.day);
  final b = DateTime.utc(deadline.year, deadline.month, deadline.day);
  return deadlineText(b.difference(a).inDays);
}
