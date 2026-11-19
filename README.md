# CollabNote

Aplikasi Flutter untuk mengelola penugasan kuliah dalam dua mode: **Individu** (checklist tahapan) dan **Kelompok** (anggota, papan Kanban, pengumpulan dan review). Tema **Cream & Mocca**. Tidak ada login; data awal berupa data contoh yang disimpan lokal.

## Cara menjalankan
```bash
flutter create .          # sekali saja, untuk membuat folder android/ios/web
flutter pub get
flutter run
flutter test
```
Android: tambahkan di `android/app/src/main/AndroidManifest.xml` (di dalam `<manifest>`) agar tautan referensi dapat dibuka:
```xml
<queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent></queries>
```

## Arsitektur berlapis
```
lib/
  domain/models/        14 model data (fromJson/toJson/copyWith)
  data/services/        CollabNoteService (server simulasi, Future.delayed + SharedPreferences), LocalFileService
  data/repositories/    sumber data tunggal; semua turunan ChangeNotifier (BaseRepository)
  data/dummy/           data contoh dan katalog template
  ui/<fitur>/           View (screen) + ViewModel (isLoading, error, load())
  config/dependencies.dart  MultiProvider
```
Alur: **View -> ViewModel -> Repository -> Service**. View memakai `ListenableBuilder`; dependensi disediakan dengan `MultiProvider` dan diambil dengan `context.read`.

## Pemetaan tugas Arsitektur Berlapis
| Ketentuan | Implementasi |
|---|---|
| Data utama | `AssignmentModel` (Penugasan) |
| Data aksi | `TaskStepModel` (centang tahapan, `copyWith`) |
| Data informasi | `ArchiveModel` (tab Arsip) |
| NavigationBar | 5 tab: Beranda, Penugasan, Ruang Kerja, Arsip, Profil |
| SegmentedButton (>=3) | Penugasan: Semua / Individu / Kelompok / Mendesak |
| CheckboxListTile | Checklist tahapan di Ruang Kerja |
| Future.delayed | `CollabNoteService.fetchCollection` (250 ms) |
| isLoading / error / load | semua ViewModel |
| Repository ChangeNotifier + badge | `AssignmentRepository.pendingActionCount` -> badge tab Ruang Kerja |
| Test ViewModel | `test/archive_view_model_test.dart`, `test/assignment_progress_test.dart` |

## Fitur utama
- Beranda: ringkasan, banner terlambat/pengingat, Upcoming Deadlines, Perlu Segera Dikerjakan.
- Penugasan: buat/ubah/hapus, template, lampiran, filter dan pencarian.
- Ruang Kerja: tahapan, catatan, dokumen, referensi, finalisasi (individu); anggota, Kanban, submission/review, merge dokumen (kelompok).
- Galeri template: 37 file nyata (docx/xlsx/pptx/pdf/md) pada `assets/templates`, dapat diunduh atau dipakai.
- Arsip: pencarian, filter, detail, ekspor ringkasan, kembalikan ke Penugasan.
- Profil: edit data, foto, pengingat, ukuran teks, reset data contoh.

## Screenshot
Tambahkan tangkapan layar di `docs/screenshots/` setelah aplikasi dijalankan.

## Hasil `flutter test`
Jalankan di komputer Anda dan tempel hasilnya di sini.
