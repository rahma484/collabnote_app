/// Fungsi bantu kecil untuk membaca JSON dengan aman di semua model.
library;

/// Mengubah nama enum (String) kembali menjadi nilai enum. Bila tidak cocok, pakai [fallback].
T enumFromName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Membaca tanggal ISO-8601 dari JSON. Mengembalikan null bila kosong atau tidak valid.
DateTime? parseDate(Object? value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Membaca daftar String dari JSON.
List<String> parseStringList(Object? value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return const [];
}
