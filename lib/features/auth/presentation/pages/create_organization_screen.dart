import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../main/presentation/pages/main_screen.dart';

// Import file provider dan dashboard
import '../../providers/org_provider.dart';

class CreateOrganizationScreen extends ConsumerStatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState
    extends ConsumerState<CreateOrganizationScreen> {
  final primaryGreen = const Color(0xFF1D8B41);
  bool _isLoading = false;

  // Controller untuk mengambil data dari Input
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  void _buatOrganisasi() async {
    if (_namaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama organisasi wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Memanggil fungsi create di Provider
    final hasil = await ref
        .read(orgProvider.notifier)
        .createOrganization(
          _namaController.text,
          _deskripsiController.text,
          _lokasiController.text,
        );

    setState(() => _isLoading = false);

    if (hasil != null && !hasil.startsWith("Gagal")) {
      // Jika Berhasil: Munculkan kode organisasi
      _tampilkanPopUpSukses(hasil);
    } else {
      // Jika Gagal: Tampilkan pesan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasil ?? 'Terjadi kesalahan sistem'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _tampilkanPopUpSukses(String kode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Text(
                'Berhasil!',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organisasi berhasil dibuat!',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 15),
              Text(
                'Kode Organisasi Anda:',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                child: Center(
                  child: Text(
                    kode,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Simpan dan bagikan kode ini agar anggota lain bisa bergabung.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup Pop-up

                // Navigasi Langsung ke Dashboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
              child: Text(
                'Masuk ke Dashboard',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buat Organisasi Baru',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mulai langkah awal untuk memantau jentik\ndi lingkungan komunitasmu.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 30),

            _buildLabel("Nama Organisasi *"),
            _buildTextField(
              _namaController,
              "Contoh: RT 05 Sehat",
              Icons.business,
            ),

            const SizedBox(height: 20),
            _buildLabel("Lokasi (Kota/Kecamatan)"),
            _buildTextField(
              _lokasiController,
              "Contoh: Semarang Barat",
              Icons.location_on_outlined,
            ),

            const SizedBox(height: 20),
            _buildLabel("Deskripsi (Opsional)"),
            _buildTextField(
              _deskripsiController,
              "Jelaskan singkat tentang grup ini...",
              Icons.notes,
              maxLines: 3,
            ),

            const SizedBox(height: 40),
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
                onPressed: _isLoading ? null : _buatOrganisasi,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Konfirmasi & Buat',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.black26, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAF9),
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
