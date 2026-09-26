import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ PASTIKAN IMPORT INI SESUAI DENGAN LOKASI FOLDERMU
import 'register_screen.dart';
import 'organization_choice_screen.dart';
import 'lupa_password_screen.dart'; // 🔥 IMPORT HALAMAN LUPA PASSWORD BARU
import '../../providers/auth_provider.dart';

// 🔥 WAJIB: GANTI IMPORT INI DENGAN NAMA FILE BOTTOM NAVIGATION BAWAHMU
import 'package:jentik_nyamuk/features/auth/presentation/pages/main_navigation_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role; // Menerima data peran (guru/murid) dari layar Pilih Peran
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isObscure = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  final Color primaryGreen = const Color(0xFF1D8B41);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _prosesLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan Password wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Memanggil fungsi login dari AuthProvider (yang sekarang menarik kodeOrg)
    final error = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        // 🔥 BAGIAN KRITIS: Hanya simpan Email. Role sudah diurus otomatis oleh auth_provider! 🔥
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', _emailController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Berhasil!'),
            backgroundColor: Colors.green,
          ),
        );

        // 🔥 LOGIKA PINTAR LOMPATAN NAVIGASI 🔥
        // Baca apakah dari database Node.js dia sudah punya grup?
        final kodeOrg = prefs.getString('kodeOrganisasi') ?? '';

        if (kodeOrg.isNotEmpty) {
          // JIKA SUDAH PUNYA GRUP (GURU LAMA / MURID LAMA):
          // Lompat langsung ke Pondasi Rumah (Bottom Navigation)
          Navigator.pushReplacement(
            context,
            // ⚠️ PASTIKAN NAMA CLASS INI SESUAI DENGAN BOTTOM NAVIGATION-MU
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        } else {
          // JIKA BELUM PUNYA GRUP (AKUN BARU):
          // Arahkan ke Gerbang Pilihan Organisasi
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OrganizationChoiceScreen()),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            children: [
              // --- LOGO DAN JUDUL ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.water_drop, size: 60, color: primaryGreen),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jentik Tracker',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      Text(
                        'Pantau Jentik, Cegah DBD',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- INDIKATOR PERAN (GURU/MURID DARI LAYAR DEPAN) ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.role == 'guru'
                      ? primaryGreen.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Masuk sebagai: ${widget.role.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.role == 'guru'
                        ? primaryGreen
                        : Colors.blue.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- FORM INPUT ---
              _buildField('Email', Icons.mail_outline, _emailController),
              const SizedBox(height: 15),
              _buildField(
                'Password',
                Icons.lock_outline,
                _passwordController,
                isPass: true,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: primaryGreen,
                        onChanged: (val) => setState(() => _rememberMe = val!),
                      ),
                      Text(
                        'Ingat saya',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    // 🔥 LOMPAT KE HALAMAN LUPA PASSWORD SAAT DIKLIK 🔥
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LupaPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Lupa Password?',
                      style: GoogleFonts.poppins(
                        color: primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- TOMBOL LOGIN ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isLoading ? null : _prosesLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // --- LINK KE HALAMAN REGISTER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun? ',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterScreen(role: widget.role),
                      ), // Membawa peran ke halaman register
                    ),
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.poppins(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET BANTUAN UNTUK MEMBUAT KOLOM TEKS
  Widget _buildField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPass = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass ? _isObscure : false,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  _isObscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black54,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
    );
  }
}
