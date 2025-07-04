# FE-Dailist (Frontend) - Dailist To Do List App

FE-Dailist adalah frontend aplikasi Dailist, sebuah aplikasi to do list harian yang membantu pengguna mengelola tugas sehari-hari secara mudah dan efisien. Frontend ini dibangun menggunakan framework Flutter (Dart) sehingga dapat dijalankan di berbagai platform (Android, iOS, dan Web).

---

## Fitur Frontend

- **Manajemen Tugas**  
  Tambah, edit, hapus, dan tandai tugas selesai dengan tampilan yang intuitif.
- **Filter & Pencarian**  
  Temukan tugas dengan fitur pencarian dan filter berdasarkan status.
- **Mode Gelap/Terang**  
  Mendukung tema gelap dan terang untuk kenyamanan pengguna.
- **Notifikasi & Reminder**  
  Mendukung pengingat tugas bagi pengguna (jika diaktifkan).
- **Sinkronisasi Cloud**  
  Data tugas tersimpan di backend (Laravel API) yang aman dan reliable.
- **Multi-platform**  
  Satu codebase untuk Android, iOS, dan Web.

---

## Teknologi

- **Flutter** (Dart)
- **HTTP package** untuk komunikasi REST API dengan backend
- **Provider/Bloc** untuk state management (disesuaikan dengan implementasi)
- **Shared Preferences/Secure Storage** untuk penyimpanan lokal (token, setting, dll)

---

## Instalasi & Menjalankan Proyek

1. **Clone repository**
   ```bash
   git clone https://github.com/RizmaAgustin/FE-Dailist.git
   cd FE-Dailist
   ```

2. **Install dependency**
   ```bash
   flutter pub get
   ```

3. **Atur konfigurasi endpoint API backend**  
   - (Opsional) Edit file konfigurasi (misal: `lib/config.dart`) untuk mengatur URL backend sesuai environment Anda, seperti `http://localhost:8000` atau server hosting.

4. **Jalankan aplikasi**
   - Untuk Android/iOS:
     ```bash
     flutter run
     ```
   - Untuk Web:
     ```bash
     flutter run -d chrome
     ```

---

## Struktur Folder

- `lib/`
  - `models/` : model data (Todo, User, dsb)
  - `screens/` : halaman-halaman utama (Home, Login, Register, dsb)
  - `services/` : kode koneksi API/backend
  - `widgets/` : komponen UI reusable
  - `utils/` : helper, constants, dll

---

## Integrasi dengan Backend

FE-Dailist terhubung dengan [BE-Dailist](https://github.com/RizmaAgustin/BE-Dailist) melalui RESTful API.  
Pastikan backend berjalan dan dapat diakses oleh aplikasi frontend.

---

## Testing

Jalankan pengujian dengan:
```bash
flutter test
```

---

## Kontribusi

1. Fork repo ini
2. Buat branch baru (`git checkout -b fitur-anda`)
3. Commit dan push perubahan Anda
4. Ajukan pull request ke repo utama

---

## Lisensi

MIT License.  
Lihat [LICENSE](LICENSE) untuk detail.

---

## Kontak

Buat [issue](https://github.com/RizmaAgustin/FE-Dailist/issues) untuk bug/masukan.
