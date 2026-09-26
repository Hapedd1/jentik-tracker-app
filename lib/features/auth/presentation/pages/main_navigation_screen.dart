import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ⚠️ PASTIKAN IMPORT INI SESUAI DENGAN LOKASI FOLDERMU ⚠️
import 'package:jentik_nyamuk/features/dashboard/presentation/pages/dashboard_screen.dart';
import 'package:jentik_nyamuk/features/laporan/presentation/pages/tambah_laporan_screen.dart';

// Import ini biarkan dinonaktifkan dulu sampai filenya benar-benar ada
import 'package:jentik_nyamuk/features/data/presentation/pages/data_screen.dart';
import 'package:jentik_nyamuk/features/peta/presentation/pages/peta_screen.dart';
import 'package:jentik_nyamuk/features/profil/presentation/pages/profil_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final primaryGreen = const Color(0xFF1D8B41);

  // 🔥 DAFTAR 4 KAMAR (HALAMAN) UTAMA 🔥
  final List<Widget> _screens = [
    const DashboardScreen(), // Index 0
    const DataScreen(), // Index 1
    const PetaScreen(), // Index 2
    const ProfilScreen(), // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: _screens[_currentIndex],

      // 🔥 TOMBOL TAMBAH LAPORAN DI TENGAH (MELAYANG) 🔥
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahLaporanScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🔥 MENU NAVIGASI BAWAH YANG RAPI DAN BERJARAK 🔥
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0, // Memperbesar jarak lengkungan
        color: Colors.white,
        elevation: 15,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ), // Memberi sedikit jarak dari pinggir HP
        child: SizedBox(
          height: 65, // Sedikit lebih tinggi agar tidak terpotong
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol Kiri 1
              Expanded(
                child: _buildNavItem(
                  Icons.home_filled,
                  Icons.home_outlined,
                  'Beranda',
                  0,
                ),
              ),

              // Tombol Kiri 2
              Expanded(
                child: _buildNavItem(
                  Icons.assignment,
                  Icons.assignment_outlined,
                  'Data',
                  1,
                ),
              ),

              // 🔥 CELAH KOSONG DI TENGAH UNTUK TOMBOL MELAYANG 🔥
              const Spacer(
                flex: 1,
              ), // Menggunakan Spacer agar jarak di tengah fleksibel dan lebar
              // Tombol Kanan 1
              Expanded(
                child: _buildNavItem(Icons.map, Icons.map_outlined, 'Peta', 2),
              ),

              // Tombol Kanan 2
              Expanded(
                child: _buildNavItem(
                  Icons.person,
                  Icons.person_outline,
                  'Profil',
                  3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET PEMBANTU UNTUK MEMBUAT TOMBOL ICON
  Widget _buildNavItem(
    IconData activeIcon,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;

    // Menggunakan InkWell untuk efek klik yang halus, tanpa MaterialButton yang punya padding bawaan
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(10), // Membulatkan efek klik
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? primaryGreen : Colors.black45,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? primaryGreen : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
