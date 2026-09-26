import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ⚠️ PASTIKAN IMPORT INI SESUAI JALURNYA
import 'login_screen.dart';

class PilihPeranScreen extends StatelessWidget {
  const PilihPeranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF1D8B41);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Utama Aplikasi di bagian atas
              Image.asset(
                'assets/logo.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.water_drop, size: 100, color: primaryGreen),
              ),
              const SizedBox(height: 20),
              Text(
                'Selamat Datang di\nJentik Tracker',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pilih peranmu untuk melanjutkan',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 50),

              // 🔥 POSISI 1 (ATAS): KARTU GURU DENGAN GAMBAR 'logo_guru.png' 🔥
              _buildRoleCard(
                context: context,
                title: 'Guru / Ketua',
                subtitle: 'Saya ingin membuat grup & menindak laporan',
                imagePath: 'assets/logo_guru.png', // 🔥 Jalur gambar buatanmu
                color: primaryGreen,
                roleValue: 'guru',
              ),
              const SizedBox(height: 20),

              // 🔥 POSISI 2 (BAWAH): KARTU MURID DENGAN GAMBAR 'logo_murid.png' 🔥
              _buildRoleCard(
                context: context,
                title: 'Murid / Relawan',
                subtitle: 'Saya ingin memantau dan melaporkan jentik',
                imagePath: 'assets/logo_murid.png', // 🔥 Jalur gambar buatanmu
                color: Colors.blue.shade600,
                roleValue: 'murid',
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath, // 🔥 Parameter baru untuk menerima jalur gambar
    required Color color,
    required String roleValue,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen(role: roleValue)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(
          18,
        ), // Sedikit sesuaikan padding agar gambar pas
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Container lingkaran untuk menampung gambar aset
            Container(
              padding: const EdgeInsets.all(8), // Padding dalam lingkaran
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                imagePath,
                width: 45, // Sesuaikan lebar gambar
                height: 45, // Sesuaikan tinggi gambar
                fit: BoxFit.contain, // Pastikan gambar tidak terpotong
                // 🔥 ERROR BUILDER: Jika file gambar belum kamu taruh di folder assets,
                // aplikasi akan otomatis memunculkan ikon backup agar tidak crash.
                errorBuilder: (context, error, stackTrace) => Icon(
                  roleValue == 'guru' ? Icons.school : Icons.person_search,
                  color: color,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
