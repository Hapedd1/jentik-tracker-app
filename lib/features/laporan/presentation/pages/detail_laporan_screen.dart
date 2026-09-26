import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ⚠️ PASTIKAN 2 IMPORT INI JALURNYA BENAR
import 'package:jentik_nyamuk/features/laporan/providers/laporan_provider.dart';
import 'lihat_peta_screen.dart';

class DetailLaporanScreen extends ConsumerStatefulWidget {
  final dynamic laporan;
  const DetailLaporanScreen({super.key, required this.laporan});

  @override
  ConsumerState<DetailLaporanScreen> createState() =>
      _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends ConsumerState<DetailLaporanScreen> {
  final primaryGreen = const Color(0xFF1D8B41);
  String _role = 'murid';
  bool _isTindakLoading = false;

  @override
  void initState() {
    super.initState();
    _cekJabatan();
  }

  Future<void> _cekJabatan() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? 'murid';
    });
  }

  Future<void> _tindakLaporan() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konfirmasi Pembersihan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah lokasi ini sudah dipastikan bersih dari jentik nyamuk?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Ya, Bersih!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _isTindakLoading = true);

    try {
      final idLaporan = widget.laporan['id'];
      const String baseUrl = 'https://womb-catnip-unweave.ngrok-free.dev/api';

      final response = await http.put(
        Uri.parse('$baseUrl/laporan/$idLaporan/tindak'),
      );

      if (response.statusCode == 200) {
        ref.invalidate(daftarLaporanProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hebat! Laporan berhasil ditandai bersih 🧹✨'),
              backgroundColor: Color(0xFF1D8B41),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Server merespons gagal');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTindakLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final laporan = widget.laporan;
    final String lokasi = laporan['nama_lokasi'] ?? 'Tanpa Lokasi';

    // 🔥 MENARIK DATA ALAMAT DARI DATABASE 🔥
    final String alamat =
        laporan['alamat'] ?? 'Alamat jalan belum direkam oleh pelapor';

    final int jentik = laporan['jumlah_jentik'] ?? 0;
    final String kondisiAir = laporan['kondisi_air'] ?? '-';
    final String catatan = laporan['catatan'] ?? 'Tidak ada catatan';
    final String status = laporan['status'] ?? 'Belum Ditangani';

    final double? lat = laporan['latitude'] != null
        ? double.tryParse(laporan['latitude'].toString())
        : null;
    final double? lng = laporan['longitude'] != null
        ? double.tryParse(laporan['longitude'].toString())
        : null;

    String tanggal = 'Waktu tidak diketahui';
    if (laporan['created_at'] != null) {
      try {
        final parsedDate = DateTime.parse(laporan['created_at']).toLocal();
        tanggal = DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
      } catch (e) {
        tanggal = '-';
      }
    }

    final fotoBukti = laporan['foto_bukti'];
    final bool hasFoto = fotoBukti != null && fotoBukti.toString().isNotEmpty;
    final String imageUrl = hasFoto
        ? 'https://womb-catnip-unweave.ngrok-free.dev$fotoBukti'
        : '';

    final isBahaya = jentik > 0 && status != 'Sudah Ditangani';
    final bool isGuru = _role == 'guru';
    final bool bisaDitindak = isGuru && status != 'Sudah Ditangani';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Laporan',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BAGIAN FOTO BUKTI ---
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey.shade200,
              child: hasFoto
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tidak ada foto lampiran',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
            ),

            // --- BAGIAN KONTEN DETAIL ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Waktu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isBahaya
                              ? Colors.orange.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isBahaya
                                ? Colors.orange.shade800
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                      Text(
                        tanggal,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // NAMA TEMPAT (Misal: Bak Mandi)
                  Text(
                    lokasi,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  // 🔥 ALAMAT JALAN YANG TAMPIL ELEGAN 🔥
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          alamat,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Info Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Jumlah Jentik',
                          '$jentik ekor',
                          Icons.bug_report,
                          isBahaya ? Colors.red : primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildInfoCard(
                          'Kondisi Air',
                          kondisiAir,
                          Icons.water_drop,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Catatan
                  Text(
                    'Catatan Pelapor',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      catatan,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- TOMBOL LOKASI PETA ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: Text(
                        'Lihat Titik Peta Lokasi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        if (lat != null && lng != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LihatPetaScreen(
                                latitude: lat,
                                longitude: lng,
                                namaLokasi: lokasi,
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Laporan ini tidak merekam koordinat GPS.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  // --- TOMBOL SAKTI GURU ---
                  if (bisaDitindak) ...[
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: _isTindakLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isTindakLoading
                              ? 'Memproses...'
                              : 'Tandai Sudah Dibersihkan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: _isTindakLoading ? null : _tindakLaporan,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
