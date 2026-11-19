# CollabNote – Versi Simulasi Final

Paket ini merupakan source project Flutter lengkap untuk tahap simulasi lokal. Belum menggunakan Supabase/Firebase.

## Fitur yang disiapkan
- Registrasi dan login simulasi menggunakan email dan password.
- Profil pengguna diambil dari akun yang sedang aktif; profil dapat diedit.
- Logout dan login kembali ke akun lain.
- Bergabung ke kelompok dengan kode undangan, baik dari layar login/registrasi maupun dari menu Profil.
- Keanggotaan kelompok disimpan dengan ID akun lokal agar peran pemilik/anggota dapat dibedakan pada simulasi.
- Data penugasan, ruang kerja, kelompok, arsip, dan dokumen tersimpan secara lokal.
- Upload file memakai bytes dan Local Storage, tanpa `path_provider`/`getApplicationDocumentsDirectory`.
- Template, preview, unduh, lampiran pembagian pekerjaan, serta animasi UI dari revisi sebelumnya tetap disertakan.

## Cara menjalankan
1. Ekstrak ZIP.
2. Buka folder `collab_note` di VS Code.
3. Jalankan:

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

## Cara mencoba simulasi undangan dua akun
1. Daftar sebagai Akun A.
2. Buat penugasan kelompok dan kelompoknya melalui alur aplikasi.
3. Salin kode undangan kelompok.
4. Buka Profil lalu pilih **Keluar dari Akun**.
5. Daftar sebagai Akun B atau login dengan akun B.
6. Masukkan kode undangan saat login/registrasi, atau gunakan **Profil > Gabung dengan Kode Undangan**.
7. Buka kembali penugasan/ruang kerja kelompok untuk melihat data yang sama dan anggota yang bergabung.

## Batasan simulasi
- Data disimpan di SharedPreferences browser/perangkat yang sama. Simulasi beberapa akun dilakukan pada browser/perangkat yang sama dengan cara logout dan login bergantian.
- Data tidak tersinkron otomatis ke browser/perangkat lain dan tidak dapat diakses lintas perangkat. Untuk kolaborasi real-time lintas perangkat, tahap berikutnya perlu Supabase/Firebase.
- Password disimpan lokal untuk keperluan demonstrasi, bukan untuk keamanan produksi. Jangan gunakan password penting.
- File upload disimpan sebagai Base64 di penyimpanan lokal browser; gunakan file berukuran kecil.
- Karena environment penyusunan paket ini tidak memiliki Flutter SDK, build dan `flutter analyze` belum dapat dijalankan di sini. Jalankan perintah di atas pada komputer pengembangan untuk verifikasi akhir.
