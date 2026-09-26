import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// ⚠️ PASTIKAN IMPORT INI JALURNYA BENAR SESUAI FOLDERMU
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role; // 🔥 Menerima data peran dari layar Login
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final primaryGreen = const Color(0xFF1D8B41);
  final bgLight = const Color(0xFFF8FAF9);

  bool _isPassObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoading = false;

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _prosesDaftar() async {
    if (_namaController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom wajib diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi Password tidak cocok!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await ref
        .read(authProvider.notifier)
        .register(
          namaLengkap: _namaController.text.trim(),
          email: _emailController.text.trim(),
          noHp: _phoneController.text.trim(),
          password: _passwordController.text,
          role: widget
              .role, // 🔥 INI PENYELAMATNYA: Mengirim pangkat ke Provider!
        );

    if (mounted) setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun berhasil dibuat! Silakan Login.'),
            backgroundColor: Color(0xFF1D8B41),
          ),
        );
        Navigator.pop(context);
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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Buat Akun Baru',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Daftar sebagai ${widget.role.toUpperCase()} untuk mulai menggunakan Jentik Tracker',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 30),
              _buildField(
                'Nama Lengkap',
                Icons.person_outline,
                _namaController,
              ),
              const SizedBox(height: 15),
              _buildField('Email', Icons.mail_outline, _emailController),
              const SizedBox(height: 15),
              _buildField(
                'No. HP',
                Icons.phone_android_outlined,
                _phoneController,
                isNumber: true,
              ),
              const SizedBox(height: 15),
              _buildField(
                'Password',
                Icons.lock_outline,
                _passwordController,
                isPass: true,
                isConfirm: false,
              ),
              const SizedBox(height: 15),
              _buildField(
                'Konfirmasi Password',
                Icons.lock_outline,
                _confirmController,
                isPass: true,
                isConfirm: true,
              ),

              const SizedBox(height: 35),
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
                  onPressed: _isLoading ? null : _prosesDaftar,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Login',
                      style: GoogleFonts.poppins(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPass = false,
    bool isConfirm = false,
    bool isNumber = false,
  }) {
    bool obscure = isConfirm ? _isConfirmObscure : _isPassObscure;
    return TextField(
      controller: controller,
      obscureText: isPass ? obscure : false,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.black38, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: isPass
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black54,
                ),
                onPressed: () => setState(() {
                  if (isConfirm) {
                    _isConfirmObscure = !_isConfirmObscure;
                  } else {
                    _isPassObscure = !_isPassObscure;
                  }
                }),
              )
            : null,
        filled: true,
        fillColor: bgLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
