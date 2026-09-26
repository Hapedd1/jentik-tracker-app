# Jentik Tracker - Mobile App (Flutter)

**Jentik Tracker** adalah aplikasi pelaporan dan pemantauan jentik nyamuk berbasis mobile. Aplikasi ini membantu menjaga lingkungan dari potensi demam berdarah melalui sistem pelaporan yang dilengkapi foto aktual, titik koordinat peta (GPS), dan rekapitulasi data.

**Arsitektur Full-Stack**
Proyek ini dibangun menggunakan arsitektur full-stack:
* **Frontend / Mobile App:** Flutter dan Dart (Repositori ini).
* **Backend & Database:** Node.js dan SQLite (Dijalankan secara lokal).
* **Jaringan:** Menggunakan **Ngrok** sebagai *tunneling* agar perangkat mobile dapat berkomunikasi dengan server lokal tanpa kabel.

**Persyaratan Sistem**
* Flutter SDK (Versi stabil terbaru)
* Perangkat Android fisik (Sangat disarankan untuk menguji fitur Kamera dan GPS) atau Emulator Android
* VS Code dengan ekstensi Flutter dan Dart

**Cara Menjalankan Aplikasi**

**1. Unduh kode**
Unduh kode melalui tombol **Code > Download ZIP**, lalu ekstrak, atau *clone* repositori ini menggunakan Git melalui terminal:
git clone https://github.com/Hapedd1/jentik-tracker-app.git

**2. Unduh dependencies**
Buka folder proyek menggunakan VS Code, buka terminal, lalu jalankan perintah:
flutter pub get

**3. Jalankan aplikasi**
Pastikan HP Android sudah tersambung dengan kabel USB (USB Debugging aktif). Kemudian jalankan:
flutter run
*(Catatan: Aplikasi ini dikonfigurasi khusus untuk dioperasikan pada platform Android).*

**Konfigurasi API Server & Ngrok**
Karena sistem ini berbasis lokal, aplikasi terhubung ke server menggunakan Ngrok. Konfigurasi alamat server (URL) berada di dalam *source code* (seperti `auth_provider.dart` atau `data_screen.dart`). 
URL Ngrok aktif: `https://womb-catnip-unweave.ngrok-free.dev`

**Penting:** Laptop sebagai server utama (Node.js) beserta terminal Ngrok **wajib dalam keadaan menyala** agar aplikasi di HP dapat melakukan *Login*, mengambil data, dan menyimpan laporan.

**Alur Pengujian**
1. Lakukan pendaftaran akun (Register) atau masuk (Login) menggunakan sistem JWT yang telah disediakan.
2. Izinkan akses Lokasi (GPS) dan Kamera saat aplikasi pertama kali membukanya.
3. Buat laporan jentik baru dengan mengambil foto langsung dari lokasi kejadian.
4. Periksa titik pelaporan pada fitur Peta terintegrasi.
5. Gunakan fitur ekspor untuk mencetak atau menyimpan laporan ke dalam format PDF.

**Tech Stack**
* **Frontend:** Flutter, Dart
* **Keamanan:** JWT (JSON Web Token)
* **Pemetaan:** `flutter_map` (OpenStreetMap)
* **Kamera & Lokasi:** `image_picker`, `geolocator`
* **Penyimpanan Lokal:** Shared Preferences
* **Backend:** Node.js, REST API, SQLite
