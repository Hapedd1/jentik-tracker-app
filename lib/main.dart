import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔥 IMPORT SPLASH SCREEN BARU KITA 🔥
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/pilih_peran_screen.dart';

// ⚠️ PASTIKAN IMPORT INI MENGARAH KE MENU NAVIGASI BAWAHMU
import 'features/auth/presentation/pages/main_navigation_screen.dart';

void main() async {
  // 1. Wajib ditambahkan jika kita ingin mengecek data sebelum aplikasi menggambar layar
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Mengecek Brankas HP (Apakah user sudah pernah login?)
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  // 3. Menentukan halaman TUJUAN (Setelah Splash Screen selesai)
  Widget halamanTujuan;
  if (token != null && token.isNotEmpty) {
    // JIKA ADA TOKEN: Langsung masuk ke dalam Navigasi Utama (Rumah lengkap dengan menu bawah)
    halamanTujuan = const MainNavigationScreen();
  } else {
    // 🔥 JIKA KOSONG: Cegat dan suruh masuk ke Gerbang Pemilihan Peran! 🔥
    halamanTujuan = const PilihPeranScreen();
  }

  // 4. Jalankan aplikasi dengan ProviderScope (Wajib untuk Riverpod)
  runApp(ProviderScope(child: MyApp(halamanTujuan: halamanTujuan)));
}

class MyApp extends StatelessWidget {
  final Widget halamanTujuan; // Menerima titipan halaman dari void main

  const MyApp({super.key, required this.halamanTujuan});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jentik Tracker',
      debugShowCheckedModeBanner: false, // Menghilangkan pita "DEBUG"
      theme: ThemeData(
        primaryColor: const Color(0xFF1D8B41),
        scaffoldBackgroundColor: const Color(0xFFF8FAF9),
      ),
      // 🔥 KITA TAMPILKAN SPLASH SCREEN DULU, LALU BERIKAN TIKET HALAMAN TUJUANNYA 🔥
      home: SplashScreen(halamanSelanjutnya: halamanTujuan),
    );
  }
}
