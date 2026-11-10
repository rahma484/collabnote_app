# Cara memasang update

1. Salin isi folder `lib/` dari zip ini ke `lib/` project kamu (timpa file yang sama).
2. Salin folder `test/`, `README.md`, `supabase_schema.sql`, `supabase_seed.sql` ke root project.
3. Pastikan `pubspec.yaml` punya dependency: `provider`, `supabase_flutter`, `url_launcher`.
4. Jalankan `supabase_schema.sql` di Supabase SQL Editor (cocokkan dulu dengan tabel yang sudah ada).
5. `flutter pub get`, lalu `flutter run --dart-define-from-file=supabase_config.json`.
