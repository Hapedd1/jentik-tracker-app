import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Menggunakan jalur titik-titik (relatif) agar dijamin tidak error
import '../../../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../../../features/data/presentation/pages/data_screen.dart';
import 'package:jentik_nyamuk/features/laporan/presentation/pages/tambah_laporan_screen.dart';
import 'package:jentik_nyamuk/features/profil/presentation/pages/profil_screen.dart';
import 'package:jentik_nyamuk/features/peta/presentation/pages/peta_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Daftar halaman
  final List<Widget> _pages = [
    const DashboardScreen(),
    const DataScreen(),
    const PetaScreen(), // <--- Peta berhasil dipasang
    const ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: _pages[_currentIndex],

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D8B41),
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        onPressed: () {
          // Navigasi ke halaman Buat Laporan
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TambahLaporanScreen(),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Dashboard', 0),
              _buildNavItem(
                Icons.insert_drive_file_outlined,
                Icons.insert_drive_file,
                'Data',
                1,
              ),
              const SizedBox(width: 48),
              _buildNavItem(
                Icons.location_on_outlined,
                Icons.location_on,
                'Peta',
                2,
              ),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profil', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF1D8B41) : Colors.black45;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? selectedIcon : unselectedIcon,
            color: color,
            size: 26,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
