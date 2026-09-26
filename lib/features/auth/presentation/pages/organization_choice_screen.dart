import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ⚠️ WAJIB GANTI: Import ini harus mengarah ke file Bottom Navigation-mu!
// Contoh: import 'package:jentik_nyamuk/features/main_navigation_screen.dart';
import 'package:jentik_nyamuk/features/auth/presentation/pages/main_navigation_screen.dart';
import 'create_organization_screen.dart';

class OrganizationChoiceScreen extends StatefulWidget {
  const OrganizationChoiceScreen({super.key});

  @override
  State<OrganizationChoiceScreen> createState() =>
      _OrganizationChoiceScreenState();
}

class _OrganizationChoiceScreenState extends State<OrganizationChoiceScreen> {
  final primaryGreen = const Color(0xFF1D8B41);
  final _kodeController = TextEditingController();
  bool _isLoading = false;
  String _role = 'murid';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'murid';
    });
  }

  Future<void> _gabungOrganisasi() async {
    if (_kodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode organisasi wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final emailUser = prefs.getString('email');

      if (emailUser == null || emailUser.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi tidak valid! Silakan Logout dan Login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(
          'https://womb-catnip-unweave.ngrok-free.dev/api/join-organization',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailUser,
          'kode_organisasi': _kodeController.text.trim().toUpperCase(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan kode organisasi yang baru berhasil digabung
        await prefs.setString(
          'kodeOrganisasi',
          _kodeController.text.trim().toUpperCase(),
        );

        // Jika server mengembalikan pangkat baru (misal karena dia pembuat aslinya), simpan!
        if (data['role'] != null) {
          await prefs.setString('role', data['role']);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil bergabung ke Organisasi!'),
              backgroundColor: Color(0xFF1D8B41),
            ),
          );

          // 🔥 PERBAIKAN KRUSIAL NAVIGASI 🔥
          // Mengarahkan ke "Rumah Utama" (Bottom Nav), bukan langsung ke "Kamar" (Dashboard)
          Navigator.pushAndRemoveUntil(
            context,
            // ⚠️ WAJIB GANTI: Pastikan `MainNavigationScreen` ini adalah nama class Menu Bawah-mu!
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Gagal bergabung'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error jaringan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Gerbang Organisasi',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center,
                size: 80,
                color: primaryGreen.withOpacity(0.8),
              ),
              const SizedBox(height: 20),
              Text(
                'Bergabung dengan Tim',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Masukkan kode organisasi yang diberikan oleh Ketuamu untuk mulai memantau jentik.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _kodeController,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'CONTOH: JATENGHEBAT',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.black26,
                    letterSpacing: 0,
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: const Icon(
                    Icons.vpn_key_outlined,
                    color: Colors.black54,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAF9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: primaryGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _gabungOrganisasi,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Gabung Organisasi',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // 🔥 LOGIKA PINTAR: HANYA TAMPIL JIKA DI LAYAR DEPAN MEMILIH SEBAGAI GURU 🔥
              if (_role == 'guru') ...[
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Colors.black12, thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'atau',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: Colors.black12, thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateOrganizationScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.add_circle_outline, color: primaryGreen),
                    label: Text(
                      'Buat Organisasi Baru',
                      style: GoogleFonts.poppins(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sebagai Guru/Ketua, kamu wajib membuat organisasi baru agar pangkatmu aktif.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
