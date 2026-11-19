/// Fungsi tanggal yang dipakai bersama oleh data dan tampilan.
library;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Selisih hari kalender dari hari ini ke [deadline]. Negatif berarti sudah lewat.
int daysUntil(DateTime deadline, {DateTime? from}) {
  final a = dateOnly(from ?? DateTime.now());
  final b = dateOnly(deadline);
  return DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// Tahun akademik berjalan, contoh: Nov 2026 -> 2026/2027.
String academicYearFor(DateTime d) => d.month >= 8 ? '${d.year}/${d.year + 1}' : '${d.year - 1}/${d.year}';
